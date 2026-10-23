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
  [] => Right Nothing
  _ => Left "Unsupported DEX directive; expected unquoted callback or activity declaration"

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
  (superclass, lifecycle) <- select_activity_adapter class_descriptor methods declarations
  let plan = MkFilePlan class_descriptor
        (methods ++ if null callbacks && null declarations then []
                    else platform_constructor superclass :: bridges ++ lifecycle)
  Right ({ interfaces := nub (map implemented_type callbacks), superclass := superclass } plan)
