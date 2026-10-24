module Backend.DEX.Placement

import Backend.DEX.IR
import Backend.DEX.Invoke

%default total

private
next_register : Register -> Register
next_register register = MkRegister (register.number + 1)

private
reference_type : FrameworkValueType -> Bool
reference_type (ReferenceValue _) = True
reference_type (ExistingValue TextValue) = True
reference_type (ExistingValue ObjectValue) = True
reference_type _ = False

private
typed_move : FrameworkValueType -> Register -> Register -> Instruction
typed_move LongValue destination source = MoveWide destination source
typed_move value destination source =
  if reference_type value
    then MoveObject destination source
    else Move destination source

private
value_words : FrameworkValueType -> Int
value_words LongValue = 2
value_words VoidValue = 0
value_words _ = 1

private
text_call : Register -> Register -> Register -> InvocationPlan
text_call destination left right =
  Invoke InvokeVirtual
    (MkMethodReference (MkTypeReference "Ljava/lang/String;") "equals"
      [ReferenceValue (MkTypeReference "Ljava/lang/Object;")]
      (ExistingValue BooleanValue))
    [left, right] (Just destination)

private
result_registers : InvocationPlan -> List Register
result_registers invocation =
  case invocation.result_register of
    Nothing => []
    Just register =>
      case invocation.method.result of
        LongValue => [register, next_register register]
        _ => [register]

private
instruction_registers : Instruction -> Either String (List Register)
instruction_registers (Move destination source) = Right [destination, source]
instruction_registers (MoveWide destination source) =
  Right [destination, next_register destination, source, next_register source]
instruction_registers (MoveObject destination source) = Right [destination, source]
instruction_registers (IntegerConstant destination _) = Right [destination]
instruction_registers (NullReference destination) = Right [destination]
instruction_registers (TextConstant destination _) = Right [destination]
instruction_registers (IntegerBinary _ destination left right) =
  Right [destination, left, right]
instruction_registers (TextEqual destination left right) =
  Right [destination, left, right]
instruction_registers (InvokeMethod invocation) = do
  words <- invocation_register_words invocation
  Right (words ++ result_registers invocation)
instruction_registers (IntegerBranch _ left right _) = Right [left, right]
instruction_registers (Goto _) = Right []
instruction_registers (Goto16 _) = Right []
instruction_registers (Goto32 _) = Right []
instruction_registers (Mark _) = Right []
instruction_registers (ReturnInteger register) = Right [register]
instruction_registers (ReturnObject register) = Right [register]
instruction_registers (ReturnWide register) = Right [register, next_register register]
instruction_registers ReturnVoid = Right []

private
validate_return : FrameworkValueType -> Instruction -> Either String ()
validate_return VoidValue ReturnVoid = Right ()
validate_return _ ReturnVoid = Left "DEX return-void requires a void method result"
validate_return (ExistingValue IntegerValue) (ReturnInteger _) = Right ()
validate_return (ExistingValue BooleanValue) (ReturnInteger _) = Right ()
validate_return _ (ReturnInteger _) =
  Left "DEX return requires an Int32 or Boolean method result"
validate_return result (ReturnObject _) =
  if reference_type result
    then Right ()
    else Left "DEX return-object requires a reference method result"
validate_return LongValue (ReturnWide _) = Right ()
validate_return _ (ReturnWide _) = Left "DEX return-wide requires a long method result"
validate_return _ _ = Right ()

private
validate_instructions : MethodPlan -> List Instruction -> Either String ()
validate_instructions method [] = Right ()
validate_instructions method (instruction :: rest) = do
  registers <- instruction_registers instruction
  if all (\register => register.number >= 0 &&
                      register.number < method.register_count) registers
    then Right ()
    else Left ("DEX instruction references a register outside the frame of " ++
               method.method_name)
  validate_return method.result_type instruction
  validate_instructions method rest

private
call_staging : InvocationPlan -> Either String (Bool, Int)
call_staging invocation = do
  required <- invocation_requires_staging invocation
  words <- invocation_argument_words invocation
  Right (required, words)

private
instruction_staging : Instruction -> Either String (Bool, Int)
instruction_staging (InvokeMethod invocation) = call_staging invocation
instruction_staging (TextEqual destination left right) =
  call_staging (text_call destination left right)
instruction_staging _ = Right (False, 0)

private
staging_requirements : List Instruction -> Either String (Bool, Int)
staging_requirements [] = Right (False, 0)
staging_requirements (instruction :: rest) = do
  (required, words) <- instruction_staging instruction
  (other_required, other_words) <- staging_requirements rest
  Right (required || other_required,
         if words > other_words then words else other_words)

private
shift_register : Register -> Register
shift_register register = MkRegister (register.number + 2)

private
scratch_zero : Register
scratch_zero = MkRegister 0

private
scratch_one : Register
scratch_one = MkRegister 1

private
low_byte_register : Register -> Bool
low_byte_register register = register.number <= 255

private
copy_arguments :
  Int -> List Register -> List FrameworkValueType ->
  Either String (List Instruction, List Register)
copy_arguments start [] [] = Right ([], [])
copy_arguments start (source :: sources) (VoidValue :: values) =
  Left "DEX staging cannot pass a void argument"
copy_arguments start (source :: sources) (value :: values) = do
  let destination = MkRegister start
  (moves, registers) <- copy_arguments (start + value_words value) sources values
  Right (typed_move value destination source :: moves, destination :: registers)
copy_arguments _ _ _ = Left "DEX staging argument count does not match its signature"

private
place_invocation : Int -> InvocationPlan -> Either String (List Instruction)
place_invocation scratch_start invocation = do
  let shifted : InvocationPlan =
        { arguments := map shift_register invocation.arguments
        , result_register := map shift_register invocation.result_register
        } invocation
  (argument_moves, placed) <-
    case invocation_format shifted of
      Right format => Right ([], shifted)
      Left explanation => do
        (moves, registers) <-
          copy_arguments scratch_start shifted.arguments
            (invocation_argument_types shifted)
        Right (moves, Invoke shifted.kind shifted.method registers shifted.result_register)
  case placed.result_register of
    Nothing => Right (argument_moves ++ [InvokeMethod placed])
    Just destination =>
      if low_byte_register destination
        then Right (argument_moves ++ [InvokeMethod placed])
        else
          Right
            (argument_moves ++
             [ InvokeMethod ({ result_register := Just scratch_zero } placed)
             , typed_move placed.method.result destination scratch_zero
             ])

private
place_instruction : Int -> Instruction -> Either String (List Instruction)
place_instruction scratch_start (Move destination source) =
  Right [Move (shift_register destination) (shift_register source)]
place_instruction scratch_start (MoveWide destination source) =
  Right [MoveWide (shift_register destination) (shift_register source)]
place_instruction scratch_start (MoveObject destination source) =
  Right [MoveObject (shift_register destination) (shift_register source)]
place_instruction scratch_start (IntegerConstant destination value) =
  let target = shift_register destination in
  if low_byte_register target
    then Right [IntegerConstant target value]
    else Right [IntegerConstant scratch_zero value, Move target scratch_zero]
place_instruction scratch_start (NullReference destination) =
  let target = shift_register destination in
  if low_byte_register target
    then Right [NullReference target]
    else Right [NullReference scratch_zero, MoveObject target scratch_zero]
place_instruction scratch_start (TextConstant destination value) =
  let target = shift_register destination in
  if low_byte_register target
    then Right [TextConstant target value]
    else Right [TextConstant scratch_zero value, MoveObject target scratch_zero]
place_instruction scratch_start (IntegerBinary operation destination left right) =
  let target = shift_register destination
      first = shift_register left
      second = shift_register right in
  if low_byte_register target && low_byte_register first && low_byte_register second
    then Right [IntegerBinary operation target first second]
    else
      let output = if low_byte_register target then target else scratch_zero
          result_move = if output == target then [] else [Move target output]
      in Right
        ([ Move scratch_zero first
         , Move scratch_one second
         , IntegerBinary operation output scratch_zero scratch_one
         ] ++ result_move)
place_instruction scratch_start (TextEqual destination left right) =
  place_invocation scratch_start (text_call destination left right)
place_instruction scratch_start (InvokeMethod invocation) =
  place_invocation scratch_start invocation
place_instruction scratch_start (IntegerBranch condition left right target) =
  let first = shift_register left
      second = shift_register right in
  if first.number <= 15 && second.number <= 15
    then Right [IntegerBranch condition first second target]
    else Right
      [ Move scratch_zero first
      , Move scratch_one second
      , IntegerBranch condition scratch_zero scratch_one target
      ]
place_instruction scratch_start instruction@(Goto _) = Right [instruction]
place_instruction scratch_start instruction@(Goto16 _) = Right [instruction]
place_instruction scratch_start instruction@(Goto32 _) = Right [instruction]
place_instruction scratch_start instruction@(Mark _) = Right [instruction]
place_instruction scratch_start (ReturnInteger register) =
  let target = shift_register register in
  if low_byte_register target
    then Right [ReturnInteger target]
    else Right [Move scratch_zero target, ReturnInteger scratch_zero]
place_instruction scratch_start (ReturnObject register) =
  let target = shift_register register in
  if low_byte_register target
    then Right [ReturnObject target]
    else Right [MoveObject scratch_zero target, ReturnObject scratch_zero]
place_instruction scratch_start (ReturnWide register) =
  let target = shift_register register in
  if low_byte_register target
    then Right [ReturnWide target]
    else Right [MoveWide scratch_zero target, ReturnWide scratch_zero]
place_instruction scratch_start ReturnVoid = Right [ReturnVoid]

private
place_instructions : Int -> List Instruction -> Either String (List Instruction)
place_instructions scratch_start [] = Right []
place_instructions scratch_start (instruction :: rest) = do
  placed <- place_instruction scratch_start instruction
  more <- place_instructions scratch_start rest
  Right (placed ++ more)

private
copy_incoming :
  Int -> Int -> List FrameworkValueType -> List Instruction
copy_incoming source destination [] = []
copy_incoming source destination (value :: rest) =
  typed_move value (MkRegister destination) (MkRegister source) ::
  copy_incoming (source + value_words value) (destination + value_words value) rest

||| Place invocations without borrowing a live source register. When required,
||| reserve v0/v1 for temporary results and an argument region above the entire
||| original frame. Real incoming parameters remain last and are copied once
||| into uniformly shifted original parameter slots. Uniform shifting preserves
||| every wide pair, including a pair crossing the old local/parameter boundary.
||| Arguments are staged in a disjoint region, so copies cannot form cycles.
|||
||| Instructions affected by the shift retain their integer/reference/wide
||| family and are legalized through the two scratch registers where needed.
||| Methods whose calls already fit an encoding keep their original placement.
public export
prepare_method_invocations : MethodPlan -> Either String MethodPlan
prepare_method_invocations method = do
  incoming_words <- parameter_register_words method.parameter_types
  if method.parameter_count /= cast (length method.parameter_types) ||
     method.parameter_count < 0 || method.register_count < incoming_words ||
     method.register_count < 0 || method.register_count > 65535
    then Left ("Invalid DEX register/parameter counts for " ++ method.method_name)
    else Right ()
  validate_instructions method method.instructions
  (required, argument_words) <- staging_requirements method.instructions
  if not required
    then Right method
    else do
      let scratch_start = method.register_count + 2
      let incoming_start = scratch_start + argument_words
      let register_count = incoming_start + incoming_words
      if register_count > 65535
        then Left ("DEX invocation staging exceeds the register frame limit for " ++
                   method.method_name)
        else Right ()
      placed <- place_instructions scratch_start method.instructions
      let prologue =
            copy_incoming incoming_start
              (method.register_count - incoming_words + 2) method.parameter_types
      Right ({ register_count := register_count
             , instructions := prologue ++ placed
             } method)
