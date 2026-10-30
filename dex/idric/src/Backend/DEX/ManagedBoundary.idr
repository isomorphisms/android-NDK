module Backend.DEX.ManagedBoundary

import Backend.DEX.Foreign
import Backend.DEX.IR
import Data.List

%default covering

private
object_value : FrameworkValueType
object_value = ExistingValue ObjectValue

private
number_type : TypeReference
number_type = MkTypeReference "Ljava/math/BigInteger;"

private
generated_type : TypeReference
generated_type = MkTypeReference "LIdric/Generated;"

private
call : InvokeKind -> TypeReference -> String -> List FrameworkValueType ->
       FrameworkValueType -> List Register -> Maybe Register -> Instruction
call kind owner name arguments result registers destination =
  InvokeMethod (Invoke kind (MkMethodReference owner name arguments result)
    registers destination)

private
box_integer : Register -> Register -> List Instruction
box_integer destination source =
  [ IntToLong (MkRegister 2) source
  , call InvokeStatic number_type "valueOf" [LongValue]
      (ReferenceValue number_type) [MkRegister 2] (Just destination)
  ]

private
to_managed : FrameworkValueType -> Register -> Register ->
             Either String (List Instruction)
to_managed (ExistingValue IntegerValue) source destination =
  Right (box_integer destination source)
to_managed (ExistingValue BooleanValue) source destination =
  Right (box_integer destination source)
to_managed LongValue source destination = Right
  [call InvokeStatic number_type "valueOf" [LongValue]
    (ReferenceValue number_type) [source] (Just destination)]
to_managed (ExistingValue TextValue) source destination = Right
  [MoveObject destination source, CheckCast destination (MkTypeReference "Ljava/lang/String;")]
to_managed (ExistingValue ObjectValue) source destination = Right [MoveObject destination source]
to_managed (ReferenceValue descriptor) source destination = Right
  [MoveObject destination source, CheckCast destination descriptor]
to_managed VoidValue source destination = Right [NullReference destination]
to_managed type _ _ = Left ("Managed export cannot import platform value " ++ show type)

private
from_managed : FrameworkValueType -> Register -> Register ->
               Either String (List Instruction)
from_managed (ExistingValue IntegerValue) source destination = Right
  [call InvokeStatic generated_type "__idricIntExact" [object_value]
    (ExistingValue IntegerValue) [source] (Just destination)]
from_managed (ExistingValue BooleanValue) source destination =
  from_managed (ExistingValue IntegerValue) source destination
from_managed LongValue source destination = Right
  [call InvokeStatic generated_type "__idricLongExact" [object_value]
    LongValue [source] (Just destination)]
from_managed (ExistingValue TextValue) source destination = Right
  [MoveObject destination source, CheckCast destination (MkTypeReference "Ljava/lang/String;")]
from_managed (ExistingValue ObjectValue) source destination = Right [MoveObject destination source]
from_managed (ReferenceValue descriptor) source destination = Right
  [MoveObject destination source, CheckCast destination descriptor]
from_managed VoidValue _ _ = Right []
from_managed type _ _ = Left ("Managed export cannot return platform value " ++ show type)

private
value_width : FrameworkValueType -> Int
value_width LongValue = 2
value_width _ = 1

private
import_parameters : List FrameworkValueType -> Int -> Int ->
                    Either String (List Instruction, List Register)
import_parameters [] source destination = Right ([], [])
import_parameters (VoidValue :: _) _ _ = Left "Managed export cannot accept a void parameter"
import_parameters (type :: rest) source destination = do
  current <- to_managed type (MkRegister source) (MkRegister destination)
  (more, registers) <- import_parameters rest (source + value_width type) (destination + 1)
  Right (current ++ more, MkRegister destination :: registers)

private
export_parameters : List FrameworkValueType -> Int -> Int ->
                    Either String (List Instruction, List Register)
export_parameters [] source destination = Right ([], [])
export_parameters (VoidValue :: _) _ _ = Left "Managed foreign cannot accept a void parameter"
export_parameters (type :: rest) source destination = do
  current <- from_managed type (MkRegister source) (MkRegister destination)
  (more, registers) <- export_parameters rest (source + 1) (destination + value_width type)
  Right (current ++ more, MkRegister destination :: registers)

private
return_value : FrameworkValueType -> Register -> Instruction
return_value VoidValue _ = ReturnVoid
return_value LongValue source = ReturnWide source
return_value (ExistingValue IntegerValue) source = ReturnInteger source
return_value (ExistingValue BooleanValue) source = ReturnInteger source
return_value _ source = ReturnObject source

-- The public signature stays scalar/opaque. ArrayList nodes and BigInteger
-- values are private to the checked method graph and never become source ABI.
public export
managed_export_bridge : ForeignEffect -> String -> String ->
  List FrameworkValueType -> FrameworkValueType -> Either String MethodPlan
managed_export_bridge effect exported checked arguments result = do
  let world_count : Int = if effect == PrimitiveIOForeign then 1 else 0
  if cast (length arguments) + world_count > 12
    then Left "Managed export exceeds the checked twelve-argument frame"
    else Right ()
  (prepared, registers) <- import_parameters arguments 64 16
  let world_register = MkRegister (16 + cast (length arguments))
  let managed_registers = registers ++ if world_count == 1 then [world_register] else []
  let prepare_world = if world_count == 1 then [NullReference world_register] else []
  completed <- from_managed result (MkRegister 12) (MkRegister 0)
  Right (MkMethodPlan "checked managed export boundary" exported
    (cast (length arguments)) arguments result
    (64 + sum (map value_width arguments))
    (prepared ++ prepare_world ++
     [call InvokeStatic generated_type checked
       (replicate (length managed_registers) object_value) object_value
       managed_registers (Just (MkRegister 12))] ++ completed ++
     [return_value result (MkRegister 0)]))

-- Foreign.parse_dex_foreign has already checked the source signature; Codegen
-- has independently checked that every opaque source domain is external.
public export
managed_foreign_bridge : String -> DEXForeign -> Either String MethodPlan
managed_foreign_bridge method foreign = do
  let arguments = foreign_target_arguments foreign
  let count : Int = cast (length arguments) + if foreign.effect == PrimitiveIOForeign then 1 else 0
  if count > 12 then Left "Managed foreign exceeds the checked twelve-argument frame" else Right ()
  (prepared, registers) <- export_parameters arguments 64 24
  operation <- the (Either String (List Instruction)) $ case foreign.operation of
    MethodInvocation kind target => Right
      [InvokeMethod (Invoke kind target registers
        (if target.result == VoidValue then Nothing else Just (MkRegister 0)))]
    CheckedReferenceCast source target => case registers of
      [input] => Right [MoveObject (MkRegister 0) input, CheckCast (MkRegister 0) target]
      _ => Left "Managed checked cast requires exactly one argument"
    ObjectConstruction target => Right
      [ NewObject (MkRegister 0) target.owner
      , InvokeMethod (Invoke InvokeDirect target (MkRegister 0 :: registers) Nothing)
      ]
  completed <- to_managed (foreign_target_result foreign) (MkRegister 0) (MkRegister 16)
  Right (MkMethodPlan "checked managed framework declaration" method count
    (replicate (cast count) object_value) object_value (64 + count)
    (prepared ++ operation ++ completed ++ [ReturnObject (MkRegister 16)]))
