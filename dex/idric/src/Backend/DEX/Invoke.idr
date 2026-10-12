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

public export
invocation_argument_types : InvocationPlan -> List FrameworkValueType
invocation_argument_types invocation =
  case invocation.kind of
    InvokeStatic => invocation.method.argument_types
    InvokeVirtual =>
      ReferenceValue invocation.method.owner :: invocation.method.argument_types
    InvokeInterface =>
      ReferenceValue invocation.method.owner :: invocation.method.argument_types

private
expand_argument :
  Register -> FrameworkValueType -> Either String (List Register)
expand_argument register VoidValue =
  Left "DEX invocation cannot pass void as an argument"
expand_argument register LongValue =
  let high = next_register register in
  if valid_register 65534 register && valid_register 65535 high
    then Right [register, high]
    else Left
      "DEX wide invocation argument exceeds a register pair in v0..v65535"
expand_argument register value =
  if valid_register 65535 register
    then Right [register]
    else Left "DEX invocation argument requires register v0..v65535"

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

||| Concrete DEX register words used by an invocation. Wide arguments
||| expand to their consecutive register pair.
public export
invocation_register_words : InvocationPlan -> Either String (List Register)
invocation_register_words invocation =
  expand_arguments invocation.arguments (invocation_argument_types invocation)

||| Number of DEX argument register words consumed by either call format.
||| Receiver registers for virtual/interface calls are included.
public export
invocation_argument_words : InvocationPlan -> Either String Int
invocation_argument_words invocation = do
  registers <- invocation_register_words invocation
  let word_count : Int = cast (length registers)
  if word_count > 255
    then Left "DEX invocation exceeds the 3rc limit of 255 register words"
    else Right word_count

public export
data InvocationFormat = Format35c | Format3rc

public export
Eq InvocationFormat where
  Format35c == Format35c = True
  Format3rc == Format3rc = True
  _ == _ = False

public export
Show InvocationFormat where
  show Format35c = "35c"
  show Format3rc = "3rc"

private
consecutive_registers : List Register -> Bool
consecutive_registers [] = True
consecutive_registers [register] = True
consecutive_registers (left :: right :: rest) =
  right.number == left.number + 1 && consecutive_registers (right :: rest)

private
fits_35c : List Register -> Bool
fits_35c registers =
  length registers <= 5 && all (valid_register 15) registers

||| Choose a call format for already placed arguments. Discontiguous arguments
||| which cannot use 35c must first be copied to a disjoint consecutive region.
public export
invocation_format : InvocationPlan -> Either String InvocationFormat
invocation_format invocation = do
  _ <- invocation_argument_words invocation
  registers <- invocation_register_words invocation
  if fits_35c registers
    then Right Format35c
    else if consecutive_registers registers
      then Right Format3rc
      else Left "DEX range arguments require safe contiguous staging"

private
validate_result_register :
  FrameworkValueType -> Maybe Register -> Either String ()
validate_result_register VoidValue Nothing = Right ()
validate_result_register VoidValue (Just register) =
  Left "DEX void invocation cannot have a result register"
validate_result_register result Nothing = Right ()
validate_result_register LongValue (Just register) =
  if valid_register 65534 register
    then Right ()
    else Left "DEX long result exceeds a register pair in v0..v65535"
validate_result_register result (Just register) =
  if valid_register 65535 register
    then Right ()
    else Left "DEX invocation result requires register v0..v65535"

||| Whether an otherwise well-formed invocation needs fresh placement. A high
||| result uses a low move-result register followed by a typed move.
public export
invocation_requires_staging : InvocationPlan -> Either String Bool
invocation_requires_staging invocation = do
  _ <- invocation_argument_words invocation
  registers <- invocation_register_words invocation
  validate_result_register invocation.method.result invocation.result_register
  let high_result =
        case invocation.result_register of
          Nothing => False
          Just register => register.number > 255
  Right
    (high_result ||
     (not (fits_35c registers) && not (consecutive_registers registers)))

private
move_result_width : FrameworkValueType -> Maybe Register -> Either String Int
move_result_width VoidValue Nothing = Right 0
move_result_width VoidValue (Just register) =
  Left "DEX void invocation cannot have a result register"
move_result_width result Nothing = Right 0
move_result_width LongValue (Just register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX move-result-wide requires a pair beginning in v0..v255"
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
  registers <- invocation_register_words invocation
  if fits_35c registers
    then Right ()
    else Left "DEX format 35c requires at most five register words in v0..v15"
  result_width <- move_result_width invocation.method.result invocation.result_register
  Right (3 + result_width)

public export
invocation_width : InvocationPlan -> Either String Int
invocation_width invocation = do
  _ <- invocation_format invocation
  result_width <- move_result_width invocation.method.result invocation.result_register
  Right (3 + result_width)

private
invoke_opcode : InvokeKind -> Integer
invoke_opcode InvokeVirtual = 0x6e
invoke_opcode InvokeStatic = 0x71
invoke_opcode InvokeInterface = 0x72

private
invoke_range_opcode : InvokeKind -> Integer
invoke_range_opcode InvokeVirtual = 0x74
invoke_range_opcode InvokeStatic = 0x77
invoke_range_opcode InvokeInterface = 0x78

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
encode_move_result result Nothing = Right []
encode_move_result LongValue (Just register) =
  if valid_register 255 register
    then Right (u16le (0x0b + cast register.number * 256))
    else Left "DEX move-result-wide requires a pair beginning in v0..v255"
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
||| two consecutive words. Non-void results may be explicitly discarded.
public export
encode_invoke_35c :
  (method_index : Int) -> InvocationPlan -> Either String (List Int)
encode_invoke_35c method_index invocation = do
  if method_index < 0 || method_index > 65535
    then Left "DEX format 35c method index exceeds 16 bits"
    else Right ()
  registers <- invocation_register_words invocation
  word_count <- invocation_argument_words invocation
  if fits_35c registers
    then Right ()
    else Left "DEX format 35c requires at most five register words in v0..v15"
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

||| Encode already contiguous arguments using format 3rc. The word count is
||| eight bits and the first register is sixteen bits; expanded wide pairs and
||| the end of the interval are validated before encoding.
public export
encode_invoke_3rc :
  (method_index : Int) -> InvocationPlan -> Either String (List Int)
encode_invoke_3rc method_index invocation = do
  if method_index < 0 || method_index > 65535
    then Left "DEX format 3rc method index exceeds 16 bits"
    else Right ()
  registers <- invocation_register_words invocation
  word_count <- invocation_argument_words invocation
  if consecutive_registers registers
    then Right ()
    else Left "DEX format 3rc requires consecutive argument register words"
  let first_register : Int =
        case registers of
          [] => 0
          register :: _ => register.number
  result <- encode_move_result invocation.method.result invocation.result_register
  Right
    (u16le (invoke_range_opcode invocation.kind + cast word_count * 256) ++
     u16le (cast method_index) ++
     u16le (cast first_register) ++ result)

public export
encode_invoke :
  (method_index : Int) -> InvocationPlan -> Either String (List Int)
encode_invoke method_index invocation = do
  format <- invocation_format invocation
  case format of
    Format35c => encode_invoke_35c method_index invocation
    Format3rc => encode_invoke_3rc method_index invocation
