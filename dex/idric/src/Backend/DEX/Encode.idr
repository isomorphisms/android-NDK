module Backend.DEX.Encode

import Backend.DEX.Hash
import Backend.DEX.IR
import Backend.DEX.Invoke
import Backend.DEX.Placement
import Data.Buffer
import Data.List
import Data.Maybe
import System.File

%default covering

private
signed32_min : Int
signed32_min = -2147483648

private
signed32_max : Int
signed32_max = 2147483647

private
valid_register : Int -> Register -> Bool
valid_register maximum register =
  register.number >= 0 && register.number <= maximum

private
unsigned_mod : Integer -> Integer -> Integer
unsigned_mod value modulus =
  let reduced = value `mod` modulus
  in if reduced < 0 then reduced + modulus else reduced

private
u16le : Integer -> List Int
u16le value =
  let encoded = unsigned_mod value 65536
  in [cast (encoded `mod` 256), cast ((encoded `div` 256) `mod` 256)]

private
u32le : Integer -> List Int
u32le value =
  let encoded = unsigned_mod value 4294967296
  in [ cast (encoded `mod` 256)
     , cast ((encoded `div` 256) `mod` 256)
     , cast ((encoded `div` 65536) `mod` 256)
     , cast ((encoded `div` 16777216) `mod` 256)
     ]

private
uleb128 : Integer -> List Int
uleb128 value =
  if value < 0
    then []
    else
      let byte = value `mod` 128
          rest = value `div` 128
      in if rest == 0
           then [cast byte]
           else cast (byte + 128) :: uleb128 rest

private
align_up : Int -> Int -> Int
align_up offset alignment =
  let remainder = offset `mod` alignment
  in if remainder == 0 then offset else offset + alignment - remainder

private
padding : Int -> Int -> List Int
padding offset alignment =
  replicate (cast (align_up offset alignment - offset)) 0

private
text_equals_reference : MethodReference
text_equals_reference =
  MkMethodReference
    (MkTypeReference "Ljava/lang/String;")
    "equals"
    [ReferenceValue (MkTypeReference "Ljava/lang/Object;")]
    (ExistingValue BooleanValue)

private
text_equal_invocation : Register -> Register -> Register -> InvocationPlan
text_equal_invocation destination left right =
  Invoke InvokeVirtual text_equals_reference [left, right] (Just destination)

private
move_width : Register -> Register -> Either String Int
move_width destination source =
  if not (valid_register 65535 destination && valid_register 65535 source)
    then Left "DEX move register exceeds v65535"
    else if valid_register 15 destination && valid_register 15 source
      then Right 1
      else if valid_register 255 destination
        then Right 2
        else Right 3

private
wide_move_width : Register -> Register -> Either String Int
wide_move_width destination source =
  if not (valid_register 65534 destination && valid_register 65534 source)
    then Left "DEX move-wide register pair exceeds v65535"
    else move_width destination source

private
instruction_width : Instruction -> Either String Int
instruction_width (Mark label) = Right 0
instruction_width (IntegerConstant destination value) =
  if not (valid_register 255 destination)
    then Left ("DEX const destination exceeds v255: " ++ show destination)
    else if value < signed32_min || value > signed32_max
      then Left ("DEX Int32 constant is out of range: " ++ show value)
      else if valid_register 15 destination && value >= -8 && value <= 7
        then Right 1
        else if value >= -32768 && value <= 32767
          then Right 2
          else Right 3
instruction_width (NullReference destination) =
  instruction_width (IntegerConstant destination 0)
instruction_width (CheckCast register _) =
  if register.number >= 0 && register.number <= 255
    then Right 2
    else Left "DEX check-cast requires register v0..v255"
instruction_width (TextConstant destination value) =
  if valid_register 255 destination
    then Right 2
    else Left "DEX const-string requires a destination in v0..v255"
instruction_width (Move destination source) = move_width destination source
instruction_width (MoveWide destination source) = wide_move_width destination source
instruction_width (MoveObject destination source) = move_width destination source
instruction_width (IntegerBinary _ destination left right) =
  if valid_register 255 destination &&
     valid_register 255 left && valid_register 255 right
    then Right 2
    else Left "DEX format 23x Int32 arithmetic requires registers v0..v255"
instruction_width (TextEqual destination left right) =
  invocation_width (text_equal_invocation destination left right)
instruction_width (InvokeMethod invocation) =
  invocation_width invocation
instruction_width (IntegerBranch _ left right target) =
  if valid_register 15 left && valid_register 15 right
    then Right 2
    else Left "DEX format 22t integer branches require registers v0..v15"
instruction_width (Goto target) = Right 1
instruction_width (Goto16 target) = Right 2
instruction_width (Goto32 target) = Right 3
instruction_width (ReturnInteger register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX return requires a register in v0..v255"
instruction_width (ReturnObject register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX return-object requires a register in v0..v255"
instruction_width (ReturnWide register) =
  if valid_register 255 register
    then Right 1
    else Left "DEX return-wide requires a pair beginning in v0..v255"
instruction_width ReturnVoid = Right 1

private
find_label : Label -> List (Label, Int) -> Either String Int
find_label requested [] = Left ("Undefined DEX label " ++ show requested)
find_label requested ((label, address) :: rest) =
  if requested == label then Right address else find_label requested rest

private
label_addresses_from :
  Int -> List (Label, Int) -> List Instruction ->
  Either String (List (Label, Int))
label_addresses_from address labels [] = Right labels
label_addresses_from address labels (Mark label :: rest) =
  if elem label (map fst labels)
    then Left ("Duplicate DEX label " ++ show label)
    else label_addresses_from address ((label, address) :: labels) rest
label_addresses_from address labels (instruction :: rest) = do
  width <- instruction_width instruction
  label_addresses_from (address + width) labels rest

private
label_addresses : List Instruction -> Either String (List (Label, Int))
label_addresses = label_addresses_from 0 []

-- Widen jumps after instruction placement. Offsets are in 16-bit code
-- units relative to the jump itself. A widening can move another target, so
-- layout must be recomputed until no jump changes. Widening is monotone:
-- short -> 16 -> 32, never the reverse. There are at most two promotions
-- per goto; the explicit fuel guards against an implementation regression.
private
checked_goto_offset : Int -> Either String ()
checked_goto_offset offset =
  if offset == 0 || offset < signed32_min || offset > signed32_max
    then Left ("DEX goto offset is zero or outside signed 32-bit code-unit range: " ++ show offset)
    else Right ()

private
widen_goto : List (Label, Int) -> Int -> Instruction -> Either String (Instruction, Bool)
widen_goto labels address (Goto target) = do
  target_address <- find_label target labels
  let offset = target_address - address
  checked_goto_offset offset
  if offset >= -128 && offset <= 127
    then Right (Goto target, False)
    else if offset >= -32768 && offset <= 32767
      then Right (Goto16 target, True)
      else Right (Goto32 target, True)
widen_goto labels address (Goto16 target) = do
  target_address <- find_label target labels
  let offset = target_address - address
  checked_goto_offset offset
  if offset >= -32768 && offset <= 32767
    then Right (Goto16 target, False)
    else Right (Goto32 target, True)
widen_goto labels address (Goto32 target) = do
  target_address <- find_label target labels
  checked_goto_offset (target_address - address)
  Right (Goto32 target, False)
widen_goto labels address instruction = Right (instruction, False)

private
widen_goto_stream :
  List (Label, Int) -> Int -> List Instruction ->
  Either String (List Instruction, Bool)
widen_goto_stream labels address [] = Right ([], False)
widen_goto_stream labels address (instruction :: rest) = do
  (widened, changed) <- widen_goto labels address instruction
  width <- instruction_width instruction
  (remaining, rest_changed) <- widen_goto_stream labels (address + width) rest
  Right (widened :: remaining, changed || rest_changed)

private
relax_gotos : Nat -> List Instruction -> Either String (List Instruction)
relax_gotos Z instructions =
  Left "DEX goto layout failed to stabilize within monotone widening bound"
relax_gotos (S remaining) instructions = do
  labels <- label_addresses instructions
  (widened, changed) <- widen_goto_stream labels 0 instructions
  if changed then relax_gotos remaining widened else Right widened

private
binary_opcode : IntegerBinaryOperation -> Integer
binary_opcode AddInteger = 0x90
binary_opcode SubtractInteger = 0x91
binary_opcode MultiplyInteger = 0x92

private
branch_opcode : IntegerCondition -> Integer
branch_opcode EqualInteger = 0x32
branch_opcode NotEqualInteger = 0x33
branch_opcode LessThanInteger = 0x34
branch_opcode GreaterEqualInteger = 0x35
branch_opcode GreaterThanInteger = 0x36
branch_opcode LessEqualInteger = 0x37

private
lookup_index : Eq value => String -> value -> List value -> Either String Int
lookup_index role requested values = find_from 0 values
  where
    find_from : Int -> List value -> Either String Int
    find_from index [] = Left ("Missing " ++ role ++ " index")
    find_from index (candidate :: rest) =
      if requested == candidate then Right index else find_from (index + 1) rest

private
encode_move : Integer -> Integer -> Integer -> Register -> Register -> Either String (List Int)
encode_move narrow_opcode from16_opcode wide_opcode destination source = do
  width <- move_width destination source
  let destination_number : Integer = cast destination.number
  let source_number : Integer = cast source.number
  case width of
    1 =>
      Right
        (u16le
          (narrow_opcode + destination_number * 256 + source_number * 4096))
    2 =>
      Right
        (u16le (from16_opcode + destination_number * 256) ++
         u16le source_number)
    _ =>
      Right
        (u16le wide_opcode ++ u16le destination_number ++ u16le source_number)

private
encode_instruction :
  List String -> List String -> List MethodReference -> List (Label, Int) -> Int -> Instruction ->
  Either String (List Int)
encode_instruction strings descriptors method_ids labels address (Mark label) = Right []
encode_instruction strings descriptors method_ids labels address instruction@(CheckCast register target) = do
  _ <- instruction_width instruction
  index <- lookup_index "check-cast type" target.descriptor descriptors
  if index > 65535 then Left "DEX check-cast type index exceeds 65535"
    else Right (u16le (0x1f + cast register.number * 256) ++ u16le (cast index))
encode_instruction strings descriptors method_ids labels address
  instruction@(IntegerConstant destination value) = do
  width <- instruction_width instruction
  let register = cast destination.number
  let literal : Integer = cast value
  case width of
    1 =>
      Right
        (u16le
          (0x12 + register * 256 + unsigned_mod literal 16 * 4096))
    2 => Right (u16le (0x13 + register * 256) ++ u16le literal)
    _ => Right (u16le (0x14 + register * 256) ++ u32le literal)
encode_instruction strings descriptors method_ids labels address (NullReference destination) =
  encode_instruction strings descriptors method_ids labels address (IntegerConstant destination 0)
encode_instruction strings descriptors method_ids labels address
  instruction@(TextConstant destination value) = do
  _ <- instruction_width instruction
  string_index <- lookup_index "const-string" value strings
  if string_index > 65535
    then Left "DEX const-string/jumbo is not implemented in the checked Text slice"
    else
      Right
        (u16le (0x1a + cast destination.number * 256) ++
         u16le (cast string_index))
encode_instruction strings descriptors method_ids labels address (Move destination source) =
  encode_move 0x01 0x02 0x03 destination source
encode_instruction strings descriptors method_ids labels address (MoveWide destination source) = do
  _ <- wide_move_width destination source
  encode_move 0x04 0x05 0x06 destination source
encode_instruction strings descriptors method_ids labels address (MoveObject destination source) =
  encode_move 0x07 0x08 0x09 destination source
encode_instruction strings descriptors method_ids labels address
  instruction@(IntegerBinary operation destination left right) = do
  _ <- instruction_width instruction
  Right
    (u16le (binary_opcode operation + cast destination.number * 256) ++
     u16le (cast left.number + cast right.number * 256))
encode_instruction strings descriptors method_ids labels address
  instruction@(TextEqual destination left right) = do
  _ <- instruction_width instruction
  let invocation = text_equal_invocation destination left right
  method_index <- lookup_index "external method" invocation.method method_ids
  encode_invoke method_index invocation
encode_instruction strings descriptors method_ids labels address
  instruction@(InvokeMethod invocation) = do
  _ <- instruction_width instruction
  method_index <- lookup_index "external method" invocation.method method_ids
  encode_invoke method_index invocation
encode_instruction strings descriptors method_ids labels address
  instruction@(IntegerBranch condition left right target) = do
  _ <- instruction_width instruction
  target_address <- find_label target labels
  let offset = target_address - address
  if offset == 0 || offset < -32768 || offset > 32767
    then
      Left
        ("DEX format 22t branch offset is zero or out of range at code unit " ++
         show address ++ ": " ++ show offset)
    else
      Right
        (u16le
          (branch_opcode condition + cast left.number * 256 +
           cast right.number * 4096) ++
         u16le (cast offset))
encode_instruction strings descriptors method_ids labels address instruction@(Goto target) = do
  _ <- instruction_width instruction
  target_address <- find_label target labels
  let offset = target_address - address
  if offset == 0 || offset < -128 || offset > 127
    then Left ("DEX goto/8 offset is zero or out of range at code unit " ++
               show address ++ ": " ++ show offset)
    else Right (u16le (0x28 + unsigned_mod (cast offset) 256 * 256))
encode_instruction strings descriptors method_ids labels address instruction@(Goto16 target) = do
  _ <- instruction_width instruction
  target_address <- find_label target labels
  let offset = target_address - address
  if offset == 0 || offset < -32768 || offset > 32767
    then Left ("DEX goto/16 offset is zero or out of range at code unit " ++
               show address ++ ": " ++ show offset)
    else Right (u16le 0x29 ++ u16le (cast offset))
encode_instruction strings descriptors method_ids labels address instruction@(Goto32 target) = do
  _ <- instruction_width instruction
  target_address <- find_label target labels
  let offset = target_address - address
  checked_goto_offset offset
  Right (u16le 0x2a ++ u32le (cast offset))
encode_instruction strings descriptors method_ids labels address
  instruction@(ReturnInteger register) = do
  _ <- instruction_width instruction
  Right (u16le (0x0f + cast register.number * 256))
encode_instruction strings descriptors method_ids labels address
  instruction@(ReturnObject register) = do
  _ <- instruction_width instruction
  Right (u16le (0x11 + cast register.number * 256))
encode_instruction strings descriptors method_ids labels address
  instruction@(ReturnWide register) = do
  _ <- instruction_width instruction
  Right (u16le (0x10 + cast register.number * 256))
encode_instruction strings descriptors method_ids labels address ReturnVoid =
  Right (u16le 0x0e)

private
encode_instruction_stream :
  List String -> List String -> List MethodReference -> List (Label, Int) -> Int -> List Instruction ->
  Either String (List Int)
encode_instruction_stream strings descriptors method_ids labels address [] = Right []
encode_instruction_stream strings descriptors method_ids labels address (instruction :: rest) = do
  encoded <- encode_instruction strings descriptors method_ids labels address instruction
  width <- instruction_width instruction
  more <-
    encode_instruction_stream strings descriptors method_ids labels (address + width) rest
  Right (encoded ++ more)

-- Strict emission of already finalized instruction widths. Unlike the
-- compatibility entry below, this does not silently promote a stale goto.
private
encode_final_instructions :
  List String -> List String -> List MethodReference -> List Instruction -> Either String (List Int)
encode_final_instructions strings descriptors method_ids instructions = do
  labels <- label_addresses instructions
  encode_instruction_stream strings descriptors method_ids labels 0 instructions

public export
encode_instructions_with_types :
  List String -> List String -> List MethodReference -> List Instruction -> Either String (List Int)
encode_instructions_with_types strings descriptors method_ids instructions = do
  widened <- relax_gotos (S (2 * length instructions)) instructions
  encode_final_instructions strings descriptors method_ids widened

public export
encode_instructions :
  List String -> List MethodReference -> List Instruction -> Either String (List Int)
encode_instructions strings method_ids instructions =
  encode_instructions_with_types strings [] method_ids instructions

private
record Prototype where
  constructor MkPrototype
  parameter_descriptors : List String
  result_descriptor : String

private
Eq Prototype where
  left == right =
    left.parameter_descriptors == right.parameter_descriptors &&
    left.result_descriptor == right.result_descriptor

private
prototype_of_method : MethodPlan -> Prototype
prototype_of_method method =
  MkPrototype
    (map framework_descriptor method.parameter_types)
    (framework_descriptor method.result_type)

private
prototype_of_reference : MethodReference -> Prototype
prototype_of_reference method =
  MkPrototype
    (map framework_descriptor method.argument_types)
    (framework_descriptor method.result)

private
generated_method_reference : String -> MethodPlan -> MethodReference
generated_method_reference class_descriptor method =
  MkMethodReference
    (MkTypeReference class_descriptor)
    method.method_name
    method.parameter_types
    method.result_type

private
utf16_character_units : Char -> List Int
utf16_character_units character =
  let code = ord character in
  if code <= 65535 then [code]
  else let supplementary = code - 65536 in
       [55296 + supplementary `div` 1024, 56320 + supplementary `mod` 1024]

private
utf16_units : String -> List Int
utf16_units value = concat (map utf16_character_units (unpack value))

export
compare_dex_strings : String -> String -> Ordering
compare_dex_strings left right = compare (utf16_units left) (utf16_units right)

private
compare_descriptors : List String -> List String -> Ordering
compare_descriptors [] [] = EQ
compare_descriptors [] (_ :: _) = LT
compare_descriptors (_ :: _) [] = GT
compare_descriptors (left :: left_rest) (right :: right_rest) =
  case compare_dex_strings left right of
    EQ => compare_descriptors left_rest right_rest
    ordering => ordering

private
compare_prototype : Prototype -> Prototype -> Ordering
compare_prototype left right =
  case compare_dex_strings left.result_descriptor right.result_descriptor of
    EQ =>
      compare_descriptors
        left.parameter_descriptors
        right.parameter_descriptors
    ordering => ordering

private
insert_prototype : Prototype -> List Prototype -> List Prototype
insert_prototype prototype [] = [prototype]
insert_prototype prototype (candidate :: rest) =
  case compare_prototype prototype candidate of
    LT => prototype :: candidate :: rest
    EQ => candidate :: rest
    GT => candidate :: insert_prototype prototype rest

private
unique_prototypes : List Prototype -> List Prototype
unique_prototypes =
  foldr insert_prototype []

private
method_reference_before : MethodReference -> MethodReference -> Bool
method_reference_before left right =
  case compare_dex_strings left.owner.descriptor right.owner.descriptor of
    LT => True
    GT => False
    EQ =>
      case compare_dex_strings left.name right.name of
        LT => True
        GT => False
        EQ =>
          compare_prototype
            (prototype_of_reference left)
            (prototype_of_reference right) /= GT

private
insert_method_reference :
  MethodReference -> List MethodReference -> List MethodReference
insert_method_reference method [] = [method]
insert_method_reference method (candidate :: rest) =
  if method == candidate
    then candidate :: rest
    else if method_reference_before method candidate
      then method :: candidate :: rest
      else candidate :: insert_method_reference method rest

private
sort_method_references : List MethodReference -> List MethodReference
sort_method_references = foldr insert_method_reference []

private
method_before : MethodPlan -> MethodPlan -> Bool
method_before left right =
  case compare_dex_strings left.method_name right.method_name of
    LT => True
    GT => False
    EQ =>
      compare_prototype
        (prototype_of_method left)
        (prototype_of_method right) /= GT

private
insert_method : MethodPlan -> List MethodPlan -> List MethodPlan
insert_method method [] = [method]
insert_method method (candidate :: rest) =
  if method_before method candidate
    then method :: candidate :: rest
    else candidate :: insert_method method rest

private
sort_methods : List MethodPlan -> List MethodPlan
sort_methods = foldr insert_method []

private
find_duplicate_method : List MethodPlan -> Maybe String
find_duplicate_method [] = Nothing
find_duplicate_method (method :: rest) =
  if any
       (\candidate =>
         candidate.method_name == method.method_name &&
         prototype_of_method candidate == prototype_of_method method) rest
    then Just method.method_name
    else find_duplicate_method rest

private
modified_utf8_unit : Int -> List Int
modified_utf8_unit 0 = [192, 128]
modified_utf8_unit code =
  if code <= 127 then [code]
  else if code <= 2047 then [192 + code `div` 64, 128 + code `mod` 64]
  else [224 + code `div` 4096, 128 + (code `div` 64) `mod` 64, 128 + code `mod` 64]

||| DEX string_data_item uses UTF-16 length and modified UTF-8, including
||| encoded NUL and three-byte encodings for each surrogate-pair member.
export
encode_string_data : String -> Either String (List Int)
encode_string_data value =
  if all (\character => ord character >= 0 && ord character <= 1114111) (unpack value)
    then let units = utf16_units value in
         Right (uleb128 (cast (length units)) ++ concat (map modified_utf8_unit units) ++ [0])
    else Left "DEX string contains an invalid Unicode code point"

private
descriptor_shorty : String -> Char
descriptor_shorty descriptor =
  case unpack descriptor of
    'L' :: _ => 'L'
    '[' :: _ => 'L'
    character :: _ => character
    [] => '?'

private
shorty : Prototype -> String
shorty prototype =
  pack
    (descriptor_shorty prototype.result_descriptor ::
     map descriptor_shorty prototype.parameter_descriptors)

private
instruction_texts : Instruction -> List String
instruction_texts (TextConstant destination value) = [value]
instruction_texts instruction = []

private
instruction_method_references : Instruction -> List MethodReference
instruction_method_references (TextEqual _ _ _) = [text_equals_reference]
instruction_method_references (InvokeMethod invocation) = [invocation.method]
instruction_method_references _ = []

private
method_external_references : MethodPlan -> List MethodReference
method_external_references method =
  concat (map instruction_method_references method.instructions)

private
all_method_references : String -> List MethodPlan -> List MethodReference
all_method_references class_descriptor methods =
  sort_method_references
    (map (generated_method_reference class_descriptor) methods ++
     concat (map method_external_references methods))

private
method_texts : MethodPlan -> List String
method_texts method = concat (map instruction_texts method.instructions)

private
prototype_descriptors : Prototype -> List String
prototype_descriptors prototype =
  prototype.result_descriptor :: prototype.parameter_descriptors

private
instruction_type_descriptors : Instruction -> List String
instruction_type_descriptors (CheckCast register target) = [target.descriptor]
instruction_type_descriptors _ = []

private
method_type_descriptors : MethodPlan -> List String
method_type_descriptors method = concat (map instruction_type_descriptors method.instructions)

private
type_descriptors :
  String -> TypeReference -> List Prototype -> List MethodReference -> List TypeReference -> List MethodPlan -> List String
type_descriptors class_descriptor superclass prototypes method_ids interfaces methods =
  sortBy compare_dex_strings
    (nub
      ([class_descriptor, superclass.descriptor] ++ map descriptor interfaces ++
       map (\method => method.owner.descriptor) method_ids ++
       concat (map prototype_descriptors prototypes) ++ concat (map method_type_descriptors methods)))

private
all_strings :
  List MethodPlan -> List MethodReference -> List Prototype -> List String -> List String
all_strings methods method_ids prototypes descriptors =
  sortBy compare_dex_strings
    (nub
      (descriptors ++
       map (\method => method.name) method_ids ++
       map shorty prototypes ++
       concat (map method_texts methods)))

private
record TypeListLayout where
  constructor MkTypeListLayout
  bytes : List Int
  offsets : List (Prototype, Int)
  first_offset : Maybe Int
  next_offset : Int
  item_count : Int
  interfaces_offset : Int

private
encode_parameter_types :
  List String -> List String -> Either String (List Int)
encode_parameter_types descriptors [] = Right []
encode_parameter_types descriptors (descriptor :: rest) = do
  type_index <- lookup_index "parameter type" descriptor descriptors
  more <- encode_parameter_types descriptors rest
  Right (u16le (cast type_index) ++ more)

private
layout_type_lists_from :
  List String -> Int -> List Prototype -> List Int ->
  List (Prototype, Int) -> Maybe Int -> Int -> Either String TypeListLayout
layout_type_lists_from descriptors current [] accumulated offsets first count =
  Right (MkTypeListLayout accumulated offsets first current count 0)
layout_type_lists_from descriptors current (prototype :: rest)
                       accumulated offsets first count =
  if null prototype.parameter_descriptors
    then
      layout_type_lists_from descriptors current rest accumulated
        ((prototype, 0) :: offsets) first count
    else do
      encoded_types <-
        encode_parameter_types descriptors prototype.parameter_descriptors
      let start = align_up current 4
      let pad = padding current 4
      let item =
            u32le (cast (length prototype.parameter_descriptors)) ++ encoded_types
      let next = start + cast (length item)
      let next_first =
            case first of
              Nothing => Just start
              Just existing => Just existing
      layout_type_lists_from descriptors next rest
        (accumulated ++ pad ++ item) ((prototype, start) :: offsets)
        next_first (count + 1)

private
layout_type_lists :
  List String -> Int -> List Prototype -> Either String TypeListLayout
layout_type_lists descriptors start prototypes =
  layout_type_lists_from descriptors start prototypes [] [] Nothing 0

private
layout_interfaces : List String -> TypeListLayout -> List TypeReference ->
  Either String TypeListLayout
layout_interfaces descriptors layout [] = Right layout
layout_interfaces descriptors layout interfaces = do
  encoded <- encode_parameter_types descriptors (map descriptor interfaces)
  let start = align_up layout.next_offset 4
  let item = u32le (cast (length interfaces)) ++ encoded
  Right ({ bytes := layout.bytes ++ padding layout.next_offset 4 ++ item
         , first_offset := Just (fromMaybe start layout.first_offset)
         , next_offset := start + cast (length item)
         , item_count := layout.item_count + 1
         , interfaces_offset := start
         } layout)

private
find_prototype_offset :
  Prototype -> List (Prototype, Int) -> Either String Int
find_prototype_offset requested [] = Left "Missing DEX prototype parameter list"
find_prototype_offset requested ((prototype, offset) :: rest) =
  if requested == prototype
    then Right offset
    else find_prototype_offset requested rest

private
instruction_outgoing_register_count : Instruction -> Either String Int
instruction_outgoing_register_count (TextEqual _ _ _) = Right 2
instruction_outgoing_register_count (InvokeMethod invocation) =
  invocation_argument_words invocation
instruction_outgoing_register_count _ = Right 0

private
outgoing_register_count : List Instruction -> Either String Int
outgoing_register_count [] = Right 0
outgoing_register_count (instruction :: rest) = do
  words <- instruction_outgoing_register_count instruction
  other_words <- outgoing_register_count rest
  Right (if words > other_words then words else other_words)

private
record PreparedMethod where
  constructor MkPreparedMethod
  owner : String
  plan : MethodPlan
  incoming_words : Int
  outgoing_words : Int
  method_index : Int
  prototype_index : Int
  instruction_bytes : List Int
  instruction_units : Int
  code_offset : Int

private
prepare_methods :
  List String -> List String -> List Prototype -> List MethodReference -> String ->
  List MethodPlan -> Either String (List PreparedMethod)
prepare_methods strings descriptors prototypes method_ids class_descriptor [] = Right []
prepare_methods strings descriptors prototypes method_ids class_descriptor (method :: rest) = do
  incoming_words <- parameter_register_words (incoming_parameter_types method)
  outgoing_words <- outgoing_register_count method.instructions
  prototype_index <-
    lookup_index "prototype" (prototype_of_method method) prototypes
  method_index <-
    lookup_index "generated method"
      (generated_method_reference class_descriptor method) method_ids
  bytes <- encode_final_instructions strings descriptors method_ids method.instructions
  more <-
    prepare_methods strings descriptors prototypes method_ids class_descriptor rest
  Right
    (MkPreparedMethod class_descriptor method incoming_words outgoing_words method_index prototype_index bytes
      (cast (length bytes) `div` 2) 0 :: more)

private
record CodeLayout where
  constructor MkCodeLayout
  bytes : List Int
  methods : List PreparedMethod
  first_offset : Int
  next_offset : Int

private
layout_code_from :
  Int -> List PreparedMethod -> List Int -> List PreparedMethod -> Maybe Int ->
  CodeLayout
layout_code_from current [] accumulated laid_out first =
  MkCodeLayout accumulated laid_out (fromMaybe current first) current
layout_code_from current (method :: rest) accumulated laid_out first =
  if native_method method.plan.mode
    then layout_code_from current rest accumulated (laid_out ++ [method]) first
    else
  let start = align_up current 4
      pad = padding current 4
      header =
        u16le (cast method.plan.register_count) ++
        u16le (cast method.incoming_words) ++
        u16le (cast method.outgoing_words) ++
        u16le 0 ++ u32le 0 ++
        u32le (cast method.instruction_units)
      item = header ++ method.instruction_bytes
      placed = { code_offset := start } method
      next_first =
        case first of
          Nothing => Just start
          Just existing => Just existing
  in layout_code_from (start + cast (length item)) rest
       (accumulated ++ pad ++ item) (laid_out ++ [placed]) next_first

private
layout_code : Int -> List PreparedMethod -> CodeLayout
layout_code start methods = layout_code_from start methods [] [] Nothing

private
record StringLayout where
  constructor MkStringLayout
  bytes : List Int
  offsets : List (String, Int)
  first_offset : Int
  next_offset : Int

private
layout_strings_from :
  Int -> List String -> List Int -> List (String, Int) -> Maybe Int ->
  Either String StringLayout
layout_strings_from current [] accumulated offsets first =
  Right (MkStringLayout accumulated offsets (fromMaybe current first) current)
layout_strings_from current (value :: rest) accumulated offsets first = do
  item <- encode_string_data value
  let next_first =
        case first of
          Nothing => Just current
          Just existing => Just existing
  layout_strings_from (current + cast (length item)) rest
    (accumulated ++ item) (offsets ++ [(value, current)]) next_first

private
layout_strings : Int -> List String -> Either String StringLayout
layout_strings start strings = layout_strings_from start strings [] [] Nothing

private
find_string_offset : String -> List (String, Int) -> Either String Int
find_string_offset requested [] = Left ("Missing DEX string data for " ++ requested)
find_string_offset requested ((value, offset) :: rest) =
  if requested == value then Right offset else find_string_offset requested rest

private
encode_class_methods : Int -> List PreparedMethod -> List Int
encode_class_methods previous [] = []
encode_class_methods previous (method :: rest) =
  uleb128 (cast (method.method_index - previous)) ++
  uleb128 (method_access_flags method.plan.mode) ++ uleb128 (cast method.code_offset) ++
  encode_class_methods method.method_index rest

private
class_data : List PreparedMethod -> List Int
class_data methods =
  let direct = filter (\method => not (virtual_method method.plan.mode)) methods
      virtual = filter (\method => virtual_method method.plan.mode) methods in
  uleb128 0 ++ uleb128 0 ++ uleb128 (cast (length direct)) ++
  uleb128 (cast (length virtual)) ++
  encode_class_methods 0 direct ++ encode_class_methods 0 virtual

private
map_item : Integer -> Int -> Int -> List Int
map_item item_type count offset =
  u16le item_type ++ u16le 0 ++ u32le (cast count) ++ u32le (cast offset)

private
replace_range : Int -> List Int -> List Int -> List Int
replace_range offset replacement bytes =
  take (cast offset) bytes ++ replacement ++
  drop (cast (offset + cast (length replacement))) bytes

private
validate_class_descriptor : String -> Either String ()
validate_class_descriptor descriptor =
  case unpack descriptor of
    'L' :: rest =>
      case reverse rest of
        ';' :: middle =>
          if not (null middle) &&
             not (isPrefixOf (unpack "L/") (unpack descriptor)) &&
             not (isSuffixOf (unpack "/;") (unpack descriptor)) &&
             not (isInfixOf (unpack "//") (unpack descriptor)) &&
             all
               (\character =>
                 (character >= 'A' && character <= 'Z') ||
                 (character >= 'a' && character <= 'z') ||
                 (character >= '0' && character <= '9') ||
                 character == '/' || character == '_' || character == '$') middle
            then Right ()
            else Left ("Unsupported DEX class descriptor `" ++ descriptor ++ "`")
        _ => Left ("Invalid DEX class descriptor `" ++ descriptor ++ "`")
    _ => Left ("Invalid DEX class descriptor `" ++ descriptor ++ "`")

private
validate_reference_type : String -> Either String ()
validate_reference_type value = array 0 (unpack value)
  where
    array : Int -> List Char -> Either String ()
    array depth ('[' :: rest) =
      if depth >= 255 then Left "DEX array descriptor exceeds 255 dimensions"
      else array (depth + 1) rest
    array depth chars@('L' :: rest) = validate_class_descriptor (pack chars)
    array depth [primitive] =
      if depth > 0 && elem primitive (unpack "BCDFIJSZ") then Right ()
      else Left ("Invalid DEX reference descriptor `" ++ value ++ "`")
    array depth _ = Left ("Invalid DEX reference descriptor `" ++ value ++ "`")

private
validate_value_type : FrameworkValueType -> Either String ()
validate_value_type (ReferenceValue reference) = validate_reference_type reference.descriptor
validate_value_type _ = Right ()

private
validate_method_types : MethodReference -> Either String ()
validate_method_types method = do
  validate_class_descriptor method.owner.descriptor
  _ <- traverse validate_value_type (method.result :: method.argument_types)
  if elem VoidValue method.argument_types then Left "DEX method parameter cannot be void"
    else Right ()

private
prototype_bytes :
  List String -> List String -> TypeListLayout -> Prototype ->
  Either String (List Int)
prototype_bytes strings descriptors type_lists prototype = do
  shorty_index <- lookup_index "shorty" (shorty prototype) strings
  return_type_index <-
    lookup_index "return type" prototype.result_descriptor descriptors
  parameters_off <- find_prototype_offset prototype type_lists.offsets
  Right
    (u32le (cast shorty_index) ++ u32le (cast return_type_index) ++
     u32le (cast parameters_off))

-- Constructor is not exported: consumers cannot label an unplaced,
-- pre-relaxation plan as finalized. Binary and readable outputs share this
-- exact value, including invocation staging and method ordering.
export
data FinalizedFilePlan = FrozenFilePlan FilePlan

export
finalized_plan : FinalizedFilePlan -> FilePlan
finalized_plan (FrozenFilePlan plan) = plan

private
finalize_method : MethodPlan -> Either String MethodPlan
finalize_method original = do
  case original.mode of
    ConstructorMethod =>
      if original.method_name == "<init>" && null original.parameter_types &&
         original.result_type == VoidValue
        then Right ()
        else Left "DEX callback constructor must be <init>()V"
    ClassInitializerMethod =>
      if original.method_name == "<clinit>" && null original.parameter_types &&
         original.result_type == VoidValue
        then Right ()
        else Left "DEX class initializer must be <clinit>()V"
    _ =>
      if original.method_name == "<init>" || original.method_name == "<clinit>"
        then Left "DEX initializer cannot use static or virtual method mode"
        else Right ()
  if native_method original.mode
    then if null original.instructions && original.register_count == 0 &&
            original.parameter_count == cast (length original.parameter_types) &&
            not (elem VoidValue original.parameter_types)
           then Right original
           else Left "DEX native declaration must have a valid signature and no code or registers"
    else do
     placed <- prepare_method_invocations original
     widened <- relax_gotos (S (2 * length placed.instructions)) placed.instructions
     Right ({ instructions := widened } placed)

export
finalize_file_plan : FilePlan -> Either String FinalizedFilePlan
finalize_file_plan file_plan = do
  if elem file_plan.access_flags [1, 0x11] then Right ()
    else Left "Unsupported DEX class access flags"
  validate_class_descriptor file_plan.class_descriptor
  validate_class_descriptor file_plan.superclass.descriptor
  if file_plan.class_descriptor == file_plan.superclass.descriptor
    then Left "DEX class cannot extend itself"
    else Right ()
  _ <- traverse (validate_class_descriptor . descriptor) file_plan.interfaces
  _ <- traverse validate_reference_type (concat (map method_type_descriptors file_plan.methods))
  _ <- traverse validate_value_type
    (concatMap (\method => method.result_type :: method.parameter_types) file_plan.methods)
  if elem (MkTypeReference file_plan.class_descriptor) file_plan.interfaces
    then Left "A DEX class cannot implement itself"
    else Right ()
  if null file_plan.methods
    then Left "A DEX file must contain at least one checked Idriç method"
    else Right ()
  let ordered = sort_methods file_plan.methods
  case find_duplicate_method ordered of
    Just duplicate => Left ("Duplicate DEX method signature " ++ duplicate)
    Nothing => Right ()
  finalized <- traverse finalize_method ordered
  let interfaces = sortBy (\left, right => compare_dex_strings left.descriptor right.descriptor)
                         (nub file_plan.interfaces)
  Right (FrozenFilePlan ({ methods := finalized, interfaces := interfaces } file_plan))

-- Multiple classes share one identifier table, type-list layout, code layout,
-- string encoder, signature and checksum implementation.
private
layout_class_interfaces : List String -> TypeListLayout -> List FilePlan ->
  Either String (TypeListLayout, List (String, Int))
layout_class_interfaces descriptors layout [] = Right (layout, [])
layout_class_interfaces descriptors layout (plan :: rest) = do
  placed <- layout_interfaces descriptors layout plan.interfaces
  (finished, others) <- layout_class_interfaces descriptors placed rest
  Right (finished, (plan.class_descriptor, placed.interfaces_offset) :: others)

private
layout_class_data : Int -> List FilePlan -> List PreparedMethod ->
  (List Int, List (String, Int), Int)
layout_class_data current [] methods = ([], [], current)
layout_class_data current (plan :: rest) methods =
  let bytes = class_data (filter (\method => method.owner == plan.class_descriptor) methods)
      (other, offsets, finish) =
        layout_class_data (current + cast (length bytes)) rest methods
  in (bytes ++ other, (plan.class_descriptor, current) :: offsets, finish)

private
encode_finalized_classes : List FinalizedFilePlan -> Either String (List Int)
encode_finalized_classes frozen = do
  if null frozen then Left "A DEX file needs at least one class" else Right ()
  let plans = sortBy (\left, right => compare_dex_strings left.class_descriptor right.class_descriptor)
                    (map finalized_plan frozen)
  let classes = map class_descriptor plans
  if length (nub classes) /= length classes
    then Left "Duplicate DEX class descriptor"
    else Right ()
  -- As with the retained adapter, application-defined inheritance needs an
  -- explicit dependency-ordering pass before it can be admitted.
  if any (\plan => elem plan.superclass.descriptor classes ||
                   any (\implemented => elem implemented.descriptor classes) plan.interfaces) plans
    then Left "App-defined superclass/interface dependencies are unsupported"
    else Right ()
  let methods = concatMap methods plans
  let method_ids = sort_method_references
        (concatMap (\plan => all_method_references plan.class_descriptor plan.methods) plans)
  _ <- traverse validate_method_types method_ids
  let prototypes = unique_prototypes (map prototype_of_reference method_ids)
  let descriptors = sortBy compare_dex_strings (nub
        (concatMap (\plan => type_descriptors plan.class_descriptor plan.superclass
          prototypes method_ids plan.interfaces plan.methods) plans))
  let strings = all_strings methods method_ids prototypes descriptors
  let method_id_count : Int = cast (length method_ids)
  let string_ids_off = 112
  let type_ids_off = string_ids_off + 4 * cast (length strings)
  let proto_ids_off = type_ids_off + 4 * cast (length descriptors)
  let method_ids_off = proto_ids_off + 12 * cast (length prototypes)
  let class_defs_off = method_ids_off + 8 * method_id_count
  let data_off = class_defs_off + 32 * cast (length plans)
  parameter_lists <- layout_type_lists descriptors data_off prototypes
  (type_lists, interface_offsets) <- layout_class_interfaces descriptors parameter_lists plans
  prepared_groups <- traverse
    (\plan => prepare_methods strings descriptors prototypes method_ids plan.class_descriptor plan.methods) plans
  let code = layout_code type_lists.next_offset (concat prepared_groups)
  let code_count = length (filter (\method => not (native_method method.mode)) methods)
  strings_layout <- layout_strings code.next_offset strings
  let (class_data_bytes, class_offsets, before_map) =
        layout_class_data strings_layout.next_offset plans code.methods
  let class_data_off = strings_layout.next_offset
  let map_off = align_up before_map 4
  string_id_bytes <- traverse
    (\value => do offset <- find_string_offset value strings_layout.offsets
                  Right (u32le (cast offset))) strings
  type_id_bytes <- traverse
    (\descriptor => do index <- lookup_index "type descriptor" descriptor strings
                       Right (u32le (cast index))) descriptors
  proto_id_bytes <- traverse (prototype_bytes strings descriptors type_lists) prototypes
  method_id_bytes <- traverse
    (\method => do
      owner_index <- lookup_index "method owner type" method.owner.descriptor descriptors
      prototype_index <- lookup_index "method prototype" (prototype_of_reference method) prototypes
      name_index <- lookup_index "method name" method.name strings
      Right (u16le (cast owner_index) ++ u16le (cast prototype_index) ++ u32le (cast name_index)))
    method_ids
  class_definitions <- traverse
    (\plan => do
      class_index <- lookup_index "generated class type" plan.class_descriptor descriptors
      super_index <- lookup_index "superclass type" plan.superclass.descriptor descriptors
      interfaces <- maybe (Left "Missing class interface offset") Right
                      (lookup plan.class_descriptor interface_offsets)
      data_offset <- maybe (Left "Missing class data offset") Right
                       (lookup plan.class_descriptor class_offsets)
      Right (u32le (cast class_index) ++ u32le plan.access_flags ++ u32le (cast super_index) ++
        u32le (cast interfaces) ++ u32le 0xffffffff ++ u32le 0 ++
        u32le (cast data_offset) ++ u32le 0)) plans
  let type_list_map = case type_lists.first_offset of
        Nothing => []
        Just offset => [map_item 0x1001 type_lists.item_count offset]
  let code_map = if code_count == 0 then [] else
        [map_item 0x2001 (cast code_count) code.first_offset]
  let map_entries =
        [ map_item 0x0000 1 0
        , map_item 0x0001 (cast (length strings)) string_ids_off
        , map_item 0x0002 (cast (length descriptors)) type_ids_off
        , map_item 0x0003 (cast (length prototypes)) proto_ids_off
        , map_item 0x0005 method_id_count method_ids_off
        , map_item 0x0006 (cast (length plans)) class_defs_off
        ] ++ type_list_map ++ code_map ++
        [ map_item 0x2002 (cast (length strings)) strings_layout.first_offset
        , map_item 0x2000 (cast (length plans)) class_data_off
        , map_item 0x1000 1 map_off ]
  let map_count = length map_entries
  let file_size = map_off + 4 + 12 * cast map_count
  let data_size = file_size - data_off
  let map_bytes = u32le (cast map_count) ++ concat map_entries
  let header =
        [100, 101, 120, 10, 48, 51, 53, 0] ++ replicate 24 0 ++
        u32le (cast file_size) ++ u32le 112 ++ u32le 0x12345678 ++
        u32le 0 ++ u32le 0 ++ u32le (cast map_off) ++
        u32le (cast (length strings)) ++ u32le (cast string_ids_off) ++
        u32le (cast (length descriptors)) ++ u32le (cast type_ids_off) ++
        u32le (cast (length prototypes)) ++ u32le (cast proto_ids_off) ++
        u32le 0 ++ u32le 0 ++ u32le (cast method_id_count) ++ u32le (cast method_ids_off) ++
        u32le (cast (length plans)) ++ u32le (cast class_defs_off) ++
        u32le (cast data_size) ++ u32le (cast data_off)
  let unsigned_file = header ++ concat string_id_bytes ++ concat type_id_bytes ++
        concat proto_id_bytes ++ concat method_id_bytes ++ concat class_definitions ++
        type_lists.bytes ++ code.bytes ++ strings_layout.bytes ++ class_data_bytes ++
        padding before_map 4 ++ map_bytes
  if cast (length unsigned_file) /= file_size
    then Left ("Internal DEX layout mismatch: planned " ++ show file_size ++
               " bytes, encoded " ++ show (length unsigned_file))
    else Right ()
  let signature = sha1 (drop 32 unsigned_file)
  if length signature /= 20 then Left "Internal SHA-1 size mismatch" else Right ()
  let signed_file = replace_range 12 signature unsigned_file
  Right (replace_range 8 (u32le (adler32 (drop 12 signed_file))) signed_file)

||| Encode the same finalized plan consumed by the readable evidence writers.
export
encode_finalized_dex : FinalizedFilePlan -> Either String (List Int)
encode_finalized_dex plan = encode_finalized_classes [plan]

||| Shared binary writer for checked code and consumer-owned JNI class plans.
public export
encode_dex_classes : List FilePlan -> Either String (List Int)
encode_dex_classes plans = do
  finalized <- traverse finalize_file_plan plans
  encode_finalized_classes finalized

||| Compatibility entry for callers needing only bytes. The compiler consumer
||| uses finalize_file_plan once, then shares it with all output producers.
public export
encode_dex : FilePlan -> Either String (List Int)
encode_dex plan = do
  finalized <- finalize_file_plan plan
  encode_finalized_dex finalized

private
fill_buffer : Buffer -> Int -> List Int -> IO ()
fill_buffer buffer offset [] = pure ()
fill_buffer buffer offset (byte :: rest) = do
  setBits8 buffer offset (cast byte)
  fill_buffer buffer (offset + 1) rest

||| Persist an already encoded candidate artifact without invoking smali, d8,
||| javac, RefC, or a native backend.
public export
write_dex : String -> List Int -> IO (Either String ())
write_dex path bytes = do
  Just buffer <- newBuffer (cast (length bytes))
    | Nothing => pure (Left "Could not allocate DEX output buffer")
  fill_buffer buffer 0 bytes
  result <- writeBufferToFile path buffer (cast (length bytes))
  case result of
    Left error => pure (Left (show error))
    Right () => pure (Right ())
