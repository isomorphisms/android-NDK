module Backend.DEX.Callback

import Backend.DEX.Foreign
import Backend.DEX.IR
import Backend.DEX.Lower
import Data.List
import Data.Maybe
import Data.String

%default total

private
record InterfaceCallback where
  constructor DeclaredCallback
  implemented_type : TypeReference
  method_name : String
  signature : String
  checked_export : String

private
record LifecycleOverride where
  constructor DeclaredOverride
  method_name : String
  signature : String
  checked_export : String

private
data ClassDirective
  = InterfaceBridge InterfaceCallback
  | ActivityParent
  | LifecycleBridge LifecycleOverride

private
parse_directive : String -> Either String (Maybe ClassDirective)
parse_directive directive = case words directive of
  ["callback", implemented, method_name, signature, checked_export] => do
    validate_reference_descriptor implemented
    _ <- validate_method_name method_name
    _ <- validate_method_name checked_export
    (arguments, result) <- parse_method_descriptor signature
    if result /= VoidValue
      then Left "DEX callback bridge currently requires a void result"
      else Right (Just (InterfaceBridge (DeclaredCallback (MkTypeReference implemented)
                          method_name signature checked_export)))
  ["extends", "Landroid/app/Activity;"] => Right (Just ActivityParent)
  ["override", "onCreate", "(Landroid/os/Bundle;)V", checked_export] => do
    _ <- validate_method_name checked_export
    Right (Just (LifecycleBridge (DeclaredOverride "onCreate" "(Landroid/os/Bundle;)V" checked_export)))
  "callback" :: _ =>
    Left "DEX callback requires interface, method, JVM signature and checked export"
  "extends" :: _ => Left "DEX checked subclass currently admits android.app.Activity only"
  "override" :: _ => Left "DEX checked lifecycle currently admits onCreate(Bundle) only"
  [] => Right Nothing
  _ => Left "Unsupported DEX directive; expected unquoted callback, extends or override declaration"

private
interface_bridge : ClassDirective -> Maybe InterfaceCallback
interface_bridge (InterfaceBridge callback) = Just callback
interface_bridge _ = Nothing

private
lifecycle_bridge : ClassDirective -> Maybe LifecycleOverride
lifecycle_bridge (LifecycleBridge lifecycle) = Just lifecycle
lifecycle_bridge _ = Nothing

private
is_activity_parent : ClassDirective -> Bool
is_activity_parent ActivityParent = True
is_activity_parent _ = False

private
argument_registers : Int -> List FrameworkValueType -> List Register
argument_registers start [] = []
argument_registers start (value :: rest) =
  MkRegister start :: argument_registers
    (start + if value == LongValue then 2 else 1) rest

private
bridge_method : String -> List MethodPlan -> InterfaceCallback ->
  Either String MethodPlan
bridge_method class_descriptor methods callback = do
  target <- case filter (\method => method.mode == StaticMethod &&
                           method.method_name == callback.checked_export) methods of
    [target] => Right target
    _ => Left ("DEX callback has no unique checked static export `" ++
                callback.checked_export ++ "`")
  let reference = MkMethodReference (MkTypeReference class_descriptor)
                    target.method_name target.parameter_types target.result_type
  if method_descriptor reference /= callback.signature
    then Left ("DEX callback signature disagrees with checked export `" ++
                callback.checked_export ++ "`")
    else Right ()
  words <- parameter_register_words target.parameter_types
  -- v0 is a local; incoming `this` is v1. Source arguments start at v2.
  -- No instance state or implicit receiver enters the checked static body.
  let bridge = MkMethodPlan ("interface bridge to " ++ target.source_name)
                 callback.method_name target.parameter_count target.parameter_types
                 VoidValue (words + 2)
                 [ InvokeMethod (Invoke InvokeStatic reference
                     (argument_registers 2 target.parameter_types) Nothing)
                 , ReturnVoid ]
  Right ({ mode := InstanceMethod } bridge)

private
object_constructor : TypeReference -> MethodPlan
object_constructor superclass =
  let method = MkMethodPlan "platform superclass initialization" "<init>" 0 [] VoidValue 1
        [ InvokeMethod (Invoke InvokeDirect
            (MkMethodReference superclass
              "<init>" [] VoidValue) [MkRegister 0] Nothing)
        , ReturnVoid ]
  in { mode := ConstructorMethod } method

private
override_method : String -> TypeReference -> List MethodPlan -> LifecycleOverride ->
  Either String MethodPlan
override_method class_descriptor superclass methods lifecycle = do
  (arguments, result) <- parse_method_descriptor lifecycle.signature
  target <- case filter (\method => method.mode == StaticMethod &&
                           method.method_name == lifecycle.checked_export) methods of
    [target] => Right target
    _ => Left "DEX lifecycle has no unique checked static export"
  let expected_arguments = ReferenceValue superclass :: arguments
  let receiver_only = [ReferenceValue superclass]
  if (target.parameter_types /= expected_arguments && target.parameter_types /= receiver_only) || target.result_type /= result
    then Left "DEX lifecycle signature must include its checked Activity receiver"
    else Right ()
  words <- parameter_register_words arguments
  let call_parent = MkMethodReference superclass lifecycle.method_name arguments result
  let call_source = MkMethodReference (MkTypeReference class_descriptor)
                      target.method_name target.parameter_types target.result_type
  let incoming = argument_registers 1 expected_arguments
  let source_incoming = if target.parameter_types == receiver_only then take 1 incoming else incoming
  let bridge = MkMethodPlan ("platform lifecycle to " ++ target.source_name)
                 lifecycle.method_name (cast (length arguments)) arguments result (words + 2)
                 [ InvokeMethod (Invoke InvokeSuper call_parent incoming Nothing)
                 , InvokeMethod (Invoke InvokeStatic call_source source_incoming Nothing)
                 , ReturnVoid ]
  Right ({ mode := InstanceMethod } bridge)

||| Platform metadata agrees with actual checked exports. Construction and
||| dispatch remain subject to independent SDK/ART qualification.
public export
with_interface_callbacks : String -> List MethodPlan -> List String ->
  Either String FilePlan
with_interface_callbacks class_descriptor methods directives = do
  parsed <- traverse parse_directive directives
  let declarations = mapMaybe id parsed
  let parents = filter is_activity_parent declarations
  if length parents > 1 then Left "DEX class has repeated superclass declarations" else Right ()
  let lifecycle = mapMaybe lifecycle_bridge declarations
  if not (null lifecycle) && null parents
    then Left "DEX lifecycle override requires its Activity superclass"
    else Right ()
  let superclass = MkTypeReference (if null parents then "Ljava/lang/Object;" else "Landroid/app/Activity;")
  let callbacks = mapMaybe interface_bridge declarations
  bridges <- traverse (bridge_method class_descriptor methods) callbacks
  overrides <- traverse (override_method class_descriptor superclass methods) lifecycle
  let needs_constructor = not (null callbacks) || not (null parents)
  let plan = MkFilePlan class_descriptor
               (methods ++ (if needs_constructor then [object_constructor superclass] else []) ++
                bridges ++ overrides)
  Right ({ interfaces := nub (map implemented_type callbacks), superclass := superclass } plan)
