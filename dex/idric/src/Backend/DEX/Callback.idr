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
parse_callback : String -> Either String (Maybe InterfaceCallback)
parse_callback directive = case words directive of
  ["callback", implemented, method_name, signature, checked_export] => do
    validate_reference_descriptor implemented
    _ <- validate_method_name method_name
    _ <- validate_method_name checked_export
    (arguments, result) <- parse_method_descriptor signature
    if result /= VoidValue
      then Left "DEX callback bridge currently requires a void result"
      else Right (Just (DeclaredCallback (MkTypeReference implemented)
                          method_name signature checked_export))
  "callback" :: _ =>
    Left "DEX callback requires interface, method, JVM signature and checked export"
  ["activity", create_export, action_export] => do
    _ <- validate_method_name create_export
    _ <- validate_method_name action_export
    Right Nothing
  "activity" :: _ =>
    Left "DEX activity requires checked create and action exports"
  ["extends", "Landroid/app/Activity;"] => Right Nothing
  ["override", "onCreate", "(Landroid/os/Bundle;)V", checked_export] => do
    _ <- validate_method_name checked_export
    Right Nothing
  "extends" :: _ => Left "DEX checked subclass currently admits android.app.Activity only"
  "override" :: _ => Left "DEX checked lifecycle currently admits onCreate(Bundle) only"
  [] => Right Nothing
  _ => Left "Unsupported DEX directive; expected unquoted callback, activity, extends or override declaration"

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
platform_constructor : TypeReference -> MethodPlan
platform_constructor superclass =
  let method = MkMethodPlan "platform superclass initialization" "<init>" 0 [] VoidValue 1
        [ InvokeMethod (Invoke InvokeDirect
            (MkMethodReference superclass
              "<init>" [] VoidValue) [MkRegister 0] Nothing)
        , ReturnVoid ]
  in { mode := ConstructorMethod } method

private
checked_activity_export : String -> List MethodPlan -> String ->
  List FrameworkValueType -> Either String MethodReference
checked_activity_export class_descriptor methods name arguments =
  case filter (\method => method.mode == StaticMethod && method.method_name == name) methods of
    [target] =>
      if target.parameter_types == arguments && target.result_type == VoidValue
        then Right (MkMethodReference (MkTypeReference class_descriptor)
                     name arguments VoidValue)
        else Left ("DEX activity signature disagrees with checked export `" ++ name ++ "`")
    _ => Left ("DEX activity has no unique checked static export `" ++ name ++ "`")

private
activity_bridges : String -> List MethodPlan -> String -> String ->
  Either String (List MethodPlan)
activity_bridges class_descriptor methods create_name action_name = do
  let activity = ReferenceValue (MkTypeReference "Landroid/app/Activity;")
  let bundle = ReferenceValue (MkTypeReference "Landroid/os/Bundle;")
  let view = ReferenceValue (MkTypeReference "Landroid/view/View;")
  create <- checked_activity_export class_descriptor methods create_name [activity]
  action <- checked_activity_export class_descriptor methods action_name [activity, view]
  let create_bridge = MkMethodPlan "Activity super.onCreate then checked create action"
        "onCreate" 1 [bundle] VoidValue 3
        [ InvokeMethod (Invoke InvokeSuper
            (MkMethodReference (MkTypeReference "Landroid/app/Activity;")
              "onCreate" [bundle] VoidValue) [MkRegister 1, MkRegister 2] Nothing)
        , InvokeMethod (Invoke InvokeStatic create [MkRegister 1] Nothing)
        , ReturnVoid ]
  let action_bridge = MkMethodPlan "Activity receiver and clicked view to checked action"
        "onClick" 1 [view] VoidValue 3
        [ InvokeMethod (Invoke InvokeStatic action [MkRegister 1, MkRegister 2] Nothing)
        , ReturnVoid ]
  Right [{ mode := InstanceMethod } create_bridge,
         { mode := InstanceMethod } action_bridge]

private
activity_declarations : List String -> List (String, String)
activity_declarations [] = []
activity_declarations (directive :: rest) = case words directive of
  ["activity", create_name, action_name] =>
    (create_name, action_name) :: activity_declarations rest
  _ => activity_declarations rest

private
select_activity_adapter : String -> List MethodPlan -> List (String, String) ->
  Either String (TypeReference, List MethodPlan)
select_activity_adapter class_descriptor methods [] =
  Right (MkTypeReference "Ljava/lang/Object;", [])
select_activity_adapter class_descriptor methods [(create_name, action_name)] = do
  lifecycle <- activity_bridges class_descriptor methods create_name action_name
  Right (MkTypeReference "Landroid/app/Activity;", lifecycle)
select_activity_adapter class_descriptor methods _ =
  Left "DEX class requires at most one Activity declaration"

private
lifecycle_declarations : List String -> List LifecycleOverride
lifecycle_declarations [] = []
lifecycle_declarations (directive :: rest) = case words directive of
  ["override", "onCreate", "(Landroid/os/Bundle;)V", checked_export] =>
    DeclaredOverride "onCreate" "(Landroid/os/Bundle;)V" checked_export :: lifecycle_declarations rest
  _ => lifecycle_declarations rest

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

||| Metadata supplies the platform method contract; the compiler checks its
||| exact agreement with a real checked export. SDK interface conformance and
||| framework dispatch still require independent target execution.
public export
with_interface_callbacks : String -> List MethodPlan -> List String ->
  Either String FilePlan
with_interface_callbacks class_descriptor methods directives = do
  parsed <- traverse parse_callback directives
  let callbacks = mapMaybe id parsed
  bridges <- traverse (bridge_method class_descriptor methods) callbacks
  let declarations = activity_declarations directives
  let parents = filter (\directive => words directive == ["extends", "Landroid/app/Activity;"]) directives
  if length parents > 1 then Left "DEX class has repeated superclass declarations" else Right ()
  let lifecycle = lifecycle_declarations directives
  if not (null lifecycle) && null parents
    then Left "DEX lifecycle override requires its Activity superclass"
    else Right ()
  if not (null declarations) && (not (null parents) || not (null lifecycle))
    then Left "DEX class cannot mix activity shorthand with extends/override declarations"
    else Right ()
  (adapter_superclass, adapter_methods) <- select_activity_adapter class_descriptor methods declarations
  let superclass = if null parents then adapter_superclass else MkTypeReference "Landroid/app/Activity;"
  overrides <- traverse (override_method class_descriptor superclass methods) lifecycle
  let needs_constructor = not (null callbacks) || not (null declarations) || not (null parents)
  let plan = MkFilePlan class_descriptor
        (methods ++ (if needs_constructor then [platform_constructor superclass] else []) ++
         bridges ++ adapter_methods ++ overrides)
  Right ({ interfaces := nub (map implemented_type callbacks), superclass := superclass } plan)
