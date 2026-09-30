module Backend.DEX.Invoke

import Backend.DEX.IR

%default total

private
u16le : Integer -> List Int
u16le value =
  [ cast (value `mod` 256)
  , cast ((value `div` 256) `mod` 256)
  ]

private
valid_register : Int -> Register -> Bool
valid_register maximum register =
  register.number >= 0 && register.number <= maximum

private
next_register : Register -> Register
next_register register = MkRegister (register.number + 1)

private
argument_types : InvocationPlan -> List FrameworkValueType
argument_types invocation =
  case invocation.kind of
    InvokeStatic => invocation.method.parameters
    InvokeVirtual =>
      ReferenceValue invocation.method.owner :: invocation.method.parameters
    InvokeInterface =>
      ReferenceValue invocation.method.owner :: invocation.method.parameters

private
expand_argument :
  Register -> FrameworkValueType -> Either String (List Register)
expand_argument register VoidValue =
  Left "DEX invocation cannot pass void as an argument"
expand_argument register LongValue =
  let high = next_register register in
  if valid_register 15 register && valid_register 15 high
    then Right [register, high]
    else Left
      "DEX format 35c wide argument requires two consecutive registers in v0..v15"
expand_argument register value =
  if valid_register 15 register
    then Right [register]
    else Left "DEX format 35c invocation argument requires register v0..v15"

private
expand_arguments :
  List Register -> List FrameworkValueType -> Either String (List Register)
expand_arguments [] [] = Right []
expand_arguments (register :: registers) (value :: values) = do
  words <- expand_argument register value
  rest <- expand_arguments registers values
  Right (words ++ rest)
expand_arguments _ _ =
  Left "DEX invocation register count does not match the method signature"

||| Number of DEX argument register words consumed by format 35c.
||| Receiver registers for virtual/interface calls are included.
public export
invocation_argument_words : InvocationPlan -> Either String Int
invocation_argument_words invocation = do
  registers <- expand_arguments invocation.arguments (argument_types invocation)
  let word_count : Int = cast (length registers)
  if word_count > 5
    then Left "DEX format 35c invocation exceeds five register words"
    else Right word_count

private
move_result_width : FrameworkValueType -> Maybe Register -> Either String Int
move_result_width VoidValue Nothing = Right 0
move_result_width VoidValue (Just register) =
  Left "DEX void invocation cannot have a result register"
move_result_width result Nothing =
  Left "DEX non-void invocation requires a result register"
move_result_width LongValue (Just register) =
  if valid_register 254 register
    then Right 1
    else Left "DEX move-result-wide requires a register pair beginning in v0..v254"
move_result_width (ReferenceValue reference) (Just register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX move-result-object requires a register in v0..v255"
move_result_width (ExistingValue TextValue) (Just register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX move-result-object requires a register in v0..v255"
move_result_width (ExistingValue ObjectValue) (Just register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX move-result-object requires a register in v0..v255"
move_result_width (ExistingValue value) (Just register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX move-result requires a register in v0..v255"

||| Width in 16-bit DEX code units for an invoke-35c plus its move-result,
||| when required.
public export
invocation_width_35c : InvocationPlan -> Either String Int
invocation_width_35c invocation = do
  _ <- invocation_argument_words invocation
  result_width <- move_result_width invocation.method.result invocation.result_register
  Right (3 + result_width)

private
invoke_opcode : InvokeKind -> Integer
invoke_opcode InvokeVirtual = 0x6e
invoke_opcode InvokeStatic = 0x71
invoke_opcode InvokeInterface = 0x72

private
fifth_register : List Register -> Integer
fifth_register (_ :: _ :: _ :: _ :: register :: _) = cast register.number
fifth_register _ = 0

private
register_at : Int -> List Register -> Integer
register_at requested registers =
  case index_from 0 registers of
    Just register => cast register.number
    Nothing => 0
  where
    index_from : Int -> List Register -> Maybe Register
    index_from index [] = Nothing
    index_from index (register :: rest) =
      if index == requested
        then Just register
        else index_from (index + 1) rest

private
encode_argument_word : List Register -> Integer
encode_argument_word registers =
  register_at 0 registers +
  register_at 1 registers * 16 +
  register_at 2 registers * 256 +
  register_at 3 registers * 4096

private
encode_move_result :
  FrameworkValueType -> Maybe Register -> Either String (List Int)
encode_move_result VoidValue Nothing = Right []
encode_move_result VoidValue (Just register) =
  Left "DEX void invocation cannot have a result register"
encode_move_result result Nothing =
  Left "DEX non-void invocation requires a result register"
encode_move_result LongValue (Just register) =
  if valid_register 254 register
    then Right (u16le (0x0b + cast register.number * 256))
    else Left "DEX move-result-wide requires a register pair beginning in v0..v254"
encode_move_result (ReferenceValue reference) (Just register) =
  if valid_register 255 register
    then Right (u16le (0x0c + cast register.number * 256))
    else Left "DEX move-result-object requires a register in v0..v255"
encode_move_result (ExistingValue TextValue) (Just register) =
  if valid_register 255 register
    then Right (u16le (0x0c + cast register.number * 256))
    else Left "DEX move-result-object requires a register in v0..v255"
encode_move_result (ExistingValue ObjectValue) (Just register) =
  if valid_register 255 register
    then Right (u16le (0x0c + cast register.number * 256))
    else Left "DEX move-result-object requires a register in v0..v255"
encode_move_result (ExistingValue value) (Just register) =
  if valid_register 255 register
    then Right (u16le (0x0a + cast register.number * 256))
    else Left "DEX move-result requires a register in v0..v255"

||| Encode one non-range invoke and its required move-result instruction.
|||
||| Format 35c carries at most five register words. A long argument consumes
||| two consecutive words. This is sufficient for the first Binder slice:
||| IBinder.transact uses exactly five words including its receiver.
public export
encode_invoke_35c :
  (method_index : Int) -> InvocationPlan -> Either String (List Int)
encode_invoke_35c method_index invocation = do
  if method_index < 0 || method_index > 65535
    then Left "DEX format 35c method index exceeds 16 bits"
    else Right ()
  registers <- expand_arguments invocation.arguments (argument_types invocation)
  word_count <- invocation_argument_words invocation
  let first =
        invoke_opcode invocation.kind +
        fifth_register registers * 256 +
        cast word_count * 4096
  let packed = encode_argument_word registers
  result <- encode_move_result invocation.method.result invocation.result_register
  Right
    (u16le first ++
     u16le (cast method_index) ++
     u16le packed ++
     result)
