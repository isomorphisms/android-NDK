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
  [] => Right Nothing
  _ => Left "Unsupported DEX directive; expected unquoted callback declaration"

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
object_constructor : MethodPlan
object_constructor =
  let method = MkMethodPlan "platform Object initialization" "<init>" 0 [] VoidValue 1
        [ InvokeMethod (Invoke InvokeDirect
            (MkMethodReference (MkTypeReference "Ljava/lang/Object;")
              "<init>" [] VoidValue) [MkRegister 0] Nothing)
        , ReturnVoid ]
  in { mode := ConstructorMethod } method

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
  let plan = MkFilePlan class_descriptor
               (methods ++ if null callbacks then [] else object_constructor :: bridges)
  Right ({ interfaces := nub (map implemented_type callbacks) } plan)
