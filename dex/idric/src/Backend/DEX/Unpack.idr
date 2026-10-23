module Backend.DEX.Unpack

import Backend.DEX.IR
import Backend.DEX.Foreign
import Compiler.ANF
import Core.CompileExpr
import Core.FC
import Core.Name
import Core.TT.Primitive
import Core.TT.Term
import Data.List
import Data.Vect

%default covering

-- Checked-ANF extension, not source-text recognition or browser logic.
-- A view denotes a suffix of one immutable runtime code-point array.
private
record View where
  constructor CharacterView
  original_text : Register
  code_points : Register
  position : Register
  length : Register
  known_nonempty : Bool
  preceding_position : Maybe Register

private
data Value
  = Literal Constant
  | TextRegister Register
  | IntegerRegister Register
  | BooleanRegister Register
  | CharacterRegister Register (Maybe View)
  | Characters View
  | Constructor Name ConInfo (Maybe Int) (List Value)
  | Closure Name Nat (List Value)
  | Erased

private
Environment : Type
Environment = List (Int, Value)

private
record State where
  constructor Emission
  next_register : Int
  next_label : Int
  reverse_code : List Instruction

private
Result : Type
Result = Either String State

private
Continuation : Type
Continuation = Value -> State -> Result

private
record Loop where
  constructor TailLoop
  function : Name
  entry : Label
  loop_values : List Value

public export
Definitions : Type
Definitions = List (Name, Administrative_Normal_Form_Definition)

private
named : Name -> String -> Bool
named actual expected =
  show actual == expected || case actual of
    DN spelling _ => spelling == expected
    _ => False

private
is_unpack : Name -> Bool
is_unpack name = named name "Prelude.Types.fastUnpack"

private
is_pack : Name -> Bool
is_pack name = named name "Prelude.Types.fastPack"

mutual
  private
  calls : Administrative_Normal_Form -> List Name
  calls (Administrative_Normal_Form_Named_Function_Application _ _ name _) = [name]
  calls (Administrative_Normal_Form_Partial_Application _ name _ _) = [name]
  calls (Administrative_Normal_Form_Binding _ _ value body) = calls value ++ calls body
  calls (Administrative_Normal_Form_Constructor_Case _ _ alternatives otherwise) =
    concat (map constructor_calls alternatives) ++ maybe [] calls otherwise
  calls (Administrative_Normal_Form_Constant_Case _ _ alternatives otherwise) =
    concat (map constant_calls alternatives) ++ maybe [] calls otherwise
  calls _ = []

  private
  constructor_calls : Administrative_Normal_Form_Constructor_Alternative -> List Name
  constructor_calls (Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ _ body) = calls body

  private
  constant_calls : Administrative_Normal_Form_Constant_Alternative -> List Name
  constant_calls (Make_Administrative_Normal_Form_Constant_Alternative _ body) = calls body

-- A helper with no named calls or partial-application creation may invoke a
-- supplied, statically known closure. Its reappearance in an inlining stack
-- is not by itself recursion: successive Maybe binds use distinct source
-- closures. Closure bodies still cross the ordinary recursion check, and
-- unknown runtime closures remain unsupported. No Prelude/helper name is
-- specially exempted. The application depth bound also applies to this case.
private
is_leaf_helper : Name -> Definitions -> Bool
is_leaf_helper name definitions =
  case lookup name definitions of
    Just (Make_Administrative_Normal_Form_Function _ body) => null (calls body)
    _ => False

private
reachable_unpack : Definitions -> List Name -> List Name -> Bool
reachable_unpack definitions visited [] = False
reachable_unpack definitions visited (name :: pending) =
  if elem name visited then reachable_unpack definitions visited pending
  else if is_unpack name then True
  else case lookup name definitions of
    Just (Make_Administrative_Normal_Form_Function _ body) =>
      reachable_unpack definitions (name :: visited) (calls body ++ pending)
    _ => reachable_unpack definitions (name :: visited) pending

export
requires_unpack_lowering : Name -> Definitions -> Bool
requires_unpack_lowering root definitions = reachable_unpack definitions [] [root]

private
character_list_type : CFType -> Bool
character_list_type (CFUser name [CFChar]) = named name "Prelude.Basics.List"
character_list_type _ = False

private
validate_intrinsic : Bool -> Name -> Definitions -> Either String ()
validate_intrinsic unpacking name definitions =
  case lookup name definitions of
    Just (Make_Administrative_Normal_Form_Foreign_Function conventions arguments result) =>
      if unpacking
        then case arguments of
          [CFString] =>
            if character_list_type result && elem "scheme:string-unpack" conventions &&
               elem "RefC:fastUnpack" conventions
              then Right () else Left "DEX fastUnpack declaration/provenance does not match pinned Prelude"
          _ => Left "DEX fastUnpack requires exactly Text -> List Char"
        else case arguments of
          [source] =>
            case result of
              CFString =>
                if character_list_type source && elem "scheme:string-pack" conventions &&
                   elem "RefC:fastPack" conventions
                  then Right () else Left "DEX fastPack declaration/provenance does not match pinned Prelude"
              _ => Left "DEX fastPack must return Text"
          _ => Left "DEX fastPack requires exactly List Char -> Text"
    _ => Left "DEX text intrinsic is not the checked Prelude foreign declaration"

private
emit : Instruction -> State -> State
-- Reserve r0/r1 for four-bit comparison operands even if calls fit without
-- triggering the existing invocation-staging pass.
emit (IntegerBranch condition left right target) state =
  if left.number <= 15 && right.number <= 15
    then { reverse_code := IntegerBranch condition left right target :: state.reverse_code } state
    else { reverse_code := IntegerBranch condition (MkRegister 0) (MkRegister 1) target ::
                           Move (MkRegister 1) right :: Move (MkRegister 0) left :: state.reverse_code } state
emit instruction state = { reverse_code := instruction :: state.reverse_code } state

private
emit_many : List Instruction -> State -> State
emit_many instructions state = foldl (flip emit) state instructions

private
fresh : State -> (Register, State)
fresh state = (MkRegister state.next_register, { next_register $= (+ 1) } state)

private
label : State -> (Label, State)
label state = (MkLabel state.next_label, { next_label $= (+ 1) } state)

private
read_variable : Environment -> Administrative_Normal_Form_Variable -> Either String Value
read_variable environment Administrative_Normal_Form_Erased_Variable = Right Erased
read_variable environment (Administrative_Normal_Form_Local_Variable variable) =
  maybe (Left ("DEX unpack reads unbound ANF local " ++ show variable)) Right (lookup variable environment)

private
bind_arguments : List Int -> List Value -> Environment -> Either String Environment
bind_arguments [] [] environment = Right environment
bind_arguments (formal :: formals) (value :: values) environment =
  bind_arguments formals values ((formal, value) :: environment)
bind_arguments _ _ _ = Left "DEX unpack checked helper arity mismatch"

private
number : Constant -> Maybe Integer
number (I32 value) = Just (cast value)
number (I value) = Just (cast value)
number (BI value) = Just value
number (B8 value) = Just (cast value)
number _ = Nothing

private
wrap32 : Integer -> Int
wrap32 value =
  let residue = value `mod` 4294967296
      positive = if residue < 0 then residue + 4294967296 else residue
  in cast (if positive >= 2147483648 then positive - 4294967296 else positive)

private
integer_register : Value -> State -> Either String (Register, State)
integer_register (IntegerRegister register) state = Right (register, state)
integer_register (BooleanRegister register) state = Right (register, state)
integer_register (CharacterRegister register _) state = Right (register, state)
integer_register (Literal (Ch character)) state =
  let (register, after) = fresh state in
  Right (register, emit (IntegerConstant register (ord character)) after)
integer_register (Literal constant) state =
  case number constant of
    Just value =>
      if value >= -2147483648 && value <= 2147483647
        then let (register, after) = fresh state in
             Right (register, emit (IntegerConstant register (cast value)) after)
        else Left "DEX unpack requires a qualified wide numeric operation"
    Nothing => Left "DEX unpack expected a character, Boolean or Int32 value"
integer_register _ _ = Left "DEX unpack cannot reinterpret a source object as an integer"

private
text_register : Value -> State -> Either String (Register, State)
text_register (TextRegister register) state = Right (register, state)
text_register (Literal (Str value)) state =
  let (register, after) = fresh state in
  Right (register, emit (TextConstant register value) after)
text_register _ _ = Left "DEX unpack expected Text"

private
reference : String -> FrameworkValueType
reference descriptor = ReferenceValue (MkTypeReference descriptor)

private
invoke : InvokeKind -> String -> String -> List FrameworkValueType -> FrameworkValueType ->
         List Register -> Register -> Instruction
invoke kind owner name types result registers destination =
  InvokeMethod (Invoke kind (MkMethodReference (MkTypeReference owner) name types result) registers (Just destination))

private
unpack_value : Value -> State -> Either String (Value, State)
unpack_value input state = do
  (text, with_text) <- text_register input state
  let (stream, s1) = fresh with_text
  let (array, s2) = fresh s1
  let (size, s3) = fresh s2
  let (start, s4) = fresh s3
  let code =
        [ invoke InvokeVirtual "Ljava/lang/String;" "codePoints" []
            (reference "Ljava/util/stream/IntStream;") [text] stream
        , invoke InvokeInterface "Ljava/util/stream/IntStream;" "toArray" []
            (reference "[I") [stream] array
        , invoke InvokeStatic "Ljava/lang/reflect/Array;" "getLength"
            [ExistingValue ObjectValue] (ExistingValue IntegerValue) [array] size
        , IntegerConstant start 0
        ]
  Right (Characters (CharacterView text array start size False Nothing), emit_many code s4)

private
pack_value : Value -> State -> Either String (Value, State)
pack_value (Characters view) state =
  let (zero, s1) = fresh state
      (offset, s2) = fresh s1
      (output, s3) = fresh s2 in
  Right (TextRegister output, emit_many
    [ IntegerConstant zero 0
    , invoke InvokeVirtual "Ljava/lang/String;" "offsetByCodePoints"
        [ExistingValue IntegerValue, ExistingValue IntegerValue] (ExistingValue IntegerValue)
        [view.original_text, zero, view.position] offset
    , invoke InvokeVirtual "Ljava/lang/String;" "substring"
        [ExistingValue IntegerValue] (ExistingValue TextValue) [view.original_text, offset] output
    ] s3)
pack_value (Constructor _ NIL _ []) state = Right (Literal (Str ""), state)
pack_value _ _ = Left "DEX fastPack supports unpack-derived views; arbitrary constructed List Char is not yet lowered"

-- Reconstruct only the exact head/tail from one observed list match.
private
constructed : Name -> ConInfo -> Maybe Int -> List Value -> Value
constructed name CONS tag [CharacterRegister head (Just origin), Characters tail] =
  if origin.original_text == tail.original_text && origin.code_points == tail.code_points &&
     tail.preceding_position == Just origin.position
    then Characters ({ known_nonempty := True } origin)
    else Constructor name CONS tag [CharacterRegister head (Just origin), Characters tail]
constructed name info tag arguments = Constructor name info tag arguments

private
split_view : View -> State -> (Value, Value, State)
split_view view state =
  let (head, s1) = fresh state
      (one, s2) = fresh s1
      (next, s3) = fresh s2
      tail = CharacterView view.original_text view.code_points next view.length False (Just view.position)
      code =
        [ invoke InvokeStatic "Ljava/lang/reflect/Array;" "getInt"
            [ExistingValue ObjectValue, ExistingValue IntegerValue] (ExistingValue IntegerValue)
            [view.code_points, view.position] head
        , IntegerConstant one 1
        , IntegerBinary AddInteger next view.position one
        ]
  in (CharacterRegister head (Just view), Characters tail, emit_many code s3)

private
comparison : IntegerCondition -> Register -> Register -> State -> Either String (Value, State)
comparison condition left right state =
  let (output, s1) = fresh state
      (yes, s2) = label s1
      (done, s3) = label s2 in
  Right (BooleanRegister output, emit_many
    [IntegerConstant output 0, IntegerBranch condition left right yes,
     Goto done, Mark yes, IntegerConstant output 1, Mark done] s3)

private
constant_integer_primitive : PrimFn arity -> Vect arity Value -> Maybe Value
constant_integer_primitive (Add IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (BI (a + b)))
constant_integer_primitive (Sub IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (BI (a - b)))
constant_integer_primitive (Mul IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (BI (a * b)))
constant_integer_primitive (EQ IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (I (if a == b then 1 else 0)))
constant_integer_primitive (LT IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (I (if a < b then 1 else 0)))
constant_integer_primitive (LTE IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (I (if a <= b then 1 else 0)))
constant_integer_primitive (GTE IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (I (if a >= b then 1 else 0)))
constant_integer_primitive (GT IntegerType) [Literal (BI a), Literal (BI b)] = Just (Literal (I (if a > b then 1 else 0)))
constant_integer_primitive (Cast IntegerType Int32Type) [Literal (BI a)] = Just (Literal (I32 (cast (wrap32 a))))
constant_integer_primitive _ _ = Nothing

private
scalar_condition : PrimFn 2 -> Maybe IntegerCondition
scalar_condition (EQ Int32Type) = Just EqualInteger
scalar_condition (LT Int32Type) = Just LessThanInteger
scalar_condition (LTE Int32Type) = Just LessEqualInteger
scalar_condition (GTE Int32Type) = Just GreaterEqualInteger
scalar_condition (GT Int32Type) = Just GreaterThanInteger
scalar_condition (EQ CharType) = Just EqualInteger
scalar_condition (LT CharType) = Just LessThanInteger
scalar_condition (LTE CharType) = Just LessEqualInteger
scalar_condition (GTE CharType) = Just GreaterEqualInteger
scalar_condition (GT CharType) = Just GreaterThanInteger
scalar_condition _ = Nothing

private
scalar_binary : PrimFn 2 -> Maybe IntegerBinaryOperation
scalar_binary (Add Int32Type) = Just AddInteger
scalar_binary (Sub Int32Type) = Just SubtractInteger
scalar_binary (Mul Int32Type) = Just MultiplyInteger
scalar_binary _ = Nothing

private
primitive : PrimFn arity -> Vect arity Value -> State -> Either String (Value, State)
primitive operation arguments state =
  case constant_integer_primitive operation arguments of
    Just value => Right (value, state)
    Nothing => case (operation, arguments) of
      (EQ StringType, [a, b]) => do
        (left, s1) <- text_register a state
        (right, s2) <- text_register b s1
        let (result, s3) = fresh s2
        Right (BooleanRegister result, emit (TextEqual result left right) s3)
      (Cast CharType Int32Type, [CharacterRegister register _]) => Right (IntegerRegister register, state)
      (binary, [a, b]) => do
        (left, s1) <- integer_register a state
        (right, s2) <- integer_register b s1
        case scalar_binary binary of
          Just operation =>
            let (result, s3) = fresh s2 in
            Right (IntegerRegister result, emit (IntegerBinary operation result left right) s3)
          Nothing => case scalar_condition binary of
            Just condition => comparison condition left right s2
            Nothing => Left ("DEX unpack unsupported dynamic primitive " ++ show operation)
      _ => Left ("DEX unpack unsupported primitive " ++ show operation)

-- Fresh loop registers protect outer aliases. All call arguments are staged
-- before assignment to preserve simultaneous parameter substitution.
private
loop_value_description : Value -> String
loop_value_description (Literal (BI value)) = "unbounded Integer literal " ++ show value
loop_value_description (Literal (I value)) = "platform Int literal " ++ show value
loop_value_description (Literal (B8 value)) = "Bits8 literal " ++ show value
loop_value_description (Literal constant) = "literal " ++ show constant
loop_value_description (Constructor name _ _ _) = "source constructor " ++ show name
loop_value_description (Closure name _ _) = "source closure " ++ show name
loop_value_description Erased = "erased source value"
loop_value_description _ = "unsupported source value"

private
clone_value : Value -> State -> Either String (Value, State)
clone_value (TextRegister source) state =
  let (target, after) = fresh state in Right (TextRegister target, emit (MoveObject target source) after)
clone_value (Literal (Str text)) state =
  let (target, after) = fresh state in
  Right (TextRegister target, emit (TextConstant target text) after)
clone_value (Literal (Ch character)) state =
  let (target, after) = fresh state in
  Right (CharacterRegister target Nothing, emit (IntegerConstant target (ord character)) after)
-- The checked compiler encodes source Boolean constructors as byte flags.
-- Keep only the proven 0/1 range; wider bytes and unbounded numbers are not
-- silently admitted as predicates or Int32 loop state.
clone_value (Literal (B8 value)) state =
  if value == 0 || value == 1
    then let (target, after) = fresh state in
         Right (BooleanRegister target, emit (IntegerConstant target (cast value)) after)
    else Left "DEX tail-loop byte literal has no qualified binary flag representation"
clone_value (Characters view) state =
  let (text, s1) = fresh state
      (array, s2) = fresh s1
      (start, s3) = fresh s2
      (size, s4) = fresh s3 in
  Right (Characters (CharacterView text array start size False Nothing), emit_many
    [MoveObject text view.original_text, MoveObject array view.code_points,
     Move start view.position, Move size view.length] s4)
clone_value value state = do
  (source, before) <- case integer_register value state of
    Left explanation => Left (explanation ++ ": " ++ loop_value_description value)
    Right accepted => Right accepted
  let (target, after) = fresh before
  case value of
    CharacterRegister _ _ => Right (CharacterRegister target Nothing, emit (Move target source) after)
    BooleanRegister _ => Right (BooleanRegister target, emit (Move target source) after)
    Literal (I32 _) => Right (IntegerRegister target, emit (Move target source) after)
    IntegerRegister _ => Right (IntegerRegister target, emit (Move target source) after)
    _ => Left ("DEX tail-loop parameter needs a supported first-order runtime representation: " ++
               loop_value_description value)

private
clone_values : List Value -> State -> Either String (List Value, State)
clone_values [] state = Right ([], state)
clone_values (value :: rest) state = do
  (copied, s1) <- clone_value value state
  (more, s2) <- clone_values rest s1
  Right (copied :: more, s2)

private
clone_loop_arguments : Name -> List Value -> State -> Either String (List Value, State)
clone_loop_arguments name arguments state =
  case clone_values arguments state of
    Left explanation => Left (explanation ++ " in checked helper `" ++ show name ++ "`")
    Right copied => Right copied

private
assign_value : Value -> Value -> State -> Result
assign_value (Characters target) (Characters source) state = Right (emit_many
  [MoveObject target.original_text source.original_text, MoveObject target.code_points source.code_points,
   Move target.position source.position, Move target.length source.length] state)
assign_value (TextRegister target) (TextRegister source) state = Right (emit (MoveObject target source) state)
assign_value (IntegerRegister target) (IntegerRegister source) state = Right (emit (Move target source) state)
assign_value (BooleanRegister target) (BooleanRegister source) state = Right (emit (Move target source) state)
assign_value (CharacterRegister target _) (CharacterRegister source _) state = Right (emit (Move target source) state)
assign_value _ _ _ = Left "DEX tail-loop argument changed representation"

private
assign_values : List Value -> List Value -> State -> Result
assign_values [] [] state = Right state
assign_values (target :: targets) (source :: sources) state = do
  next <- assign_value target source state
  assign_values targets sources next
assign_values _ _ _ = Left "DEX tail-loop arity mismatch"

private
constructor_alternative : Name -> ConInfo ->
  List Administrative_Normal_Form_Constructor_Alternative ->
  Maybe (List Int, Administrative_Normal_Form)
constructor_alternative name info [] = Nothing
constructor_alternative name info (Make_Administrative_Normal_Form_Constructor_Alternative actual shape _ fields body :: rest) =
  if name == actual && info == shape then Just (fields, body)
  else constructor_alternative name info rest

private
list_alternative : ConInfo -> List Administrative_Normal_Form_Constructor_Alternative ->
  Maybe (List Int, Administrative_Normal_Form)
list_alternative info [] = Nothing
list_alternative info (Make_Administrative_Normal_Form_Constructor_Alternative _ shape _ fields body :: rest) =
  if info == shape then Just (fields, body) else list_alternative info rest

private
constant_alternative : Constant -> List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form
constant_alternative value [] = Nothing
constant_alternative value (Make_Administrative_Normal_Form_Constant_Alternative candidate body :: rest) =
  if value == candidate || (case (number value, number candidate) of
      (Just a, Just b) => a == b
      _ => False)
    then Just body else constant_alternative value rest

mutual
  private
  evaluate : Definitions -> List Name -> Maybe Loop -> Bool -> Environment ->
    Administrative_Normal_Form -> Continuation -> State -> Result
  evaluate definitions stack loop tail_position environment expression continuation state =
    case expression of
      Administrative_Normal_Form_Variable_Expression _ variable => do
        value <- read_variable environment variable
        continuation value state
      Administrative_Normal_Form_Primitive_Value _ constant => continuation (Literal constant) state
      Administrative_Normal_Form_Erased_Value _ => continuation Erased state
      Administrative_Normal_Form_Binding _ variable value body =>
        evaluate definitions stack loop False environment value
          (\result, next => evaluate definitions stack loop tail_position ((variable, result) :: environment) body continuation next) state
      Administrative_Normal_Form_Named_Function_Application _ Nothing name arguments => do
        values <- traverse (read_variable environment) arguments
        apply definitions stack loop tail_position name values continuation state
      Administrative_Normal_Form_Partial_Application _ name missing arguments => do
        values <- traverse (read_variable environment) arguments
        continuation (Closure name missing values) state
      Administrative_Normal_Form_Closure_Application _ Nothing closure argument => do
        function <- read_variable environment closure
        value <- read_variable environment argument
        case function of
          Closure name (S Z) captured =>
            apply definitions stack loop tail_position name (captured ++ [value]) continuation state
          Closure name (S missing) captured => continuation (Closure name missing (captured ++ [value])) state
          _ => Left "DEX unpack cannot execute an unknown runtime closure"
      Administrative_Normal_Form_Constructor_Value _ name info tag arguments => do
        values <- traverse (read_variable environment) arguments
        continuation (constructed name info tag values) state
      Administrative_Normal_Form_Primitive_Operation _ Nothing operation arguments => do
        values <- traverse (read_variable environment) arguments
        (result, next) <- primitive operation values state
        continuation result next
      Administrative_Normal_Form_Constructor_Case _ variable alternatives otherwise => do
        value <- read_variable environment variable
        case value of
          Constructor name info _ fields =>
            case constructor_alternative name info alternatives of
              Just (formals, body) => do
                bound <- bind_arguments formals fields environment
                evaluate definitions stack loop tail_position bound body continuation state
              Nothing => fallback definitions stack loop tail_position environment otherwise continuation state
          Characters view =>
            view_case definitions stack loop tail_position environment variable view alternatives otherwise continuation state
          _ => Left "DEX unpack cannot inspect an unknown runtime source constructor"
      Administrative_Normal_Form_Constant_Case _ variable alternatives otherwise => do
        value <- read_variable environment variable
        case value of
          Literal constant =>
            case constant_alternative constant alternatives of
              Just body => evaluate definitions stack loop tail_position environment body continuation state
              Nothing => fallback definitions stack loop tail_position environment otherwise continuation state
          _ => constant_case definitions stack loop tail_position environment value alternatives otherwise continuation state
      _ => Left ("DEX unpack unsupported checked ANF: " ++ show expression)

  private
  apply : Definitions -> List Name -> Maybe Loop -> Bool -> Name -> List Value -> Continuation -> State -> Result
  apply definitions stack loop tail_position name arguments continuation state =
    if length stack > 1024 then Left "DEX unpack checked application depth exceeds 1024"
    else if is_unpack name then do
      validate_intrinsic True name definitions
      case arguments of
        [value] => do
          (result, next) <- unpack_value value state
          continuation result next
        _ => Left "DEX fastUnpack call arity mismatch"
    else if is_pack name then do
      validate_intrinsic False name definitions
      case arguments of
        [value] => do
          (result, next) <- pack_value value state
          continuation result next
        _ => Left "DEX fastPack call arity mismatch"
    else if elem name stack && not (is_leaf_helper name definitions) then
      case loop of
        Just active =>
          if active.function == name && tail_position
            then do
              (staged, next) <- clone_loop_arguments name arguments state
              assigned <- assign_values active.loop_values staged next
              Right (emit (Goto active.entry) assigned)
            else Left ("DEX unpack non-tail/mutual recursion remains unsupported: " ++ show name)
        Nothing => Left ("DEX unpack recursive helper has no tail-loop boundary: " ++ show name)
    else case lookup name definitions of
      Just (Make_Administrative_Normal_Form_Function formals body) =>
        if elem name (calls body)
          then do
            (loop_values, copied) <- clone_loop_arguments name arguments state
            bound <- bind_arguments formals loop_values []
            let (entry, after_label) = label copied
            evaluate definitions (name :: stack) (Just (TailLoop name entry loop_values)) True bound body continuation (emit (Mark entry) after_label)
          else do
            bound <- bind_arguments formals arguments []
            evaluate definitions (name :: stack) Nothing True bound body continuation state
      _ => Left ("DEX unpack unsupported checked helper/foreign call: " ++ show name)

  private
  fallback : Definitions -> List Name -> Maybe Loop -> Bool -> Environment ->
    Maybe Administrative_Normal_Form -> Continuation -> State -> Result
  fallback definitions stack loop tail_position environment (Just body) continuation state =
    evaluate definitions stack loop tail_position environment body continuation state
  fallback _ _ _ _ _ Nothing _ _ = Left "DEX unpack case has no proven exhaustive branch or fallback"

  private
  cons_branch : Definitions -> List Name -> Maybe Loop -> Bool -> Environment ->
    Administrative_Normal_Form_Variable -> View ->
    Maybe (List Int, Administrative_Normal_Form) -> Maybe Administrative_Normal_Form -> Continuation -> State -> Result
  cons_branch definitions stack loop tail_position environment variable view (Just ([first, rest], body)) otherwise continuation state = do
    let nonempty = { known_nonempty := True } view
    let (head, tail, next) = split_view nonempty state
    let refined = case variable of
          Administrative_Normal_Form_Local_Variable index => (index, Characters nonempty) :: environment
          _ => environment
    evaluate definitions stack loop tail_position ((first, head) :: (rest, tail) :: refined) body continuation next
  cons_branch definitions stack loop tail_position environment variable view Nothing otherwise continuation state =
    fallback definitions stack loop tail_position environment otherwise continuation state
  cons_branch _ _ _ _ _ _ _ _ _ _ _ = Left "DEX unpack Cons must bind exactly Char and List Char"

  private
  nil_branch : Definitions -> List Name -> Maybe Loop -> Bool -> Environment ->
    Maybe (List Int, Administrative_Normal_Form) -> Maybe Administrative_Normal_Form -> Continuation -> State -> Result
  nil_branch definitions stack loop tail_position environment (Just ([], body)) otherwise continuation state =
    evaluate definitions stack loop tail_position environment body continuation state
  nil_branch definitions stack loop tail_position environment Nothing otherwise continuation state =
    fallback definitions stack loop tail_position environment otherwise continuation state
  nil_branch _ _ _ _ _ _ _ _ _ = Left "DEX unpack Nil may not bind fields"

  private
  view_case : Definitions -> List Name -> Maybe Loop -> Bool -> Environment ->
    Administrative_Normal_Form_Variable -> View -> List Administrative_Normal_Form_Constructor_Alternative ->
    Maybe Administrative_Normal_Form -> Continuation -> State -> Result
  view_case definitions stack loop tail_position environment variable view alternatives otherwise continuation state = do
    if all list_shape alternatives then Right () else Left "DEX unpack view cannot be matched as a different source data type"
    let cons = list_alternative CONS alternatives
    let nil = list_alternative NIL alternatives
    case view.known_nonempty of
      True => cons_branch definitions stack loop tail_position environment variable view cons otherwise continuation state
      False => do
        let (nonempty, s1) = label state
        empty_done <- nil_branch definitions stack loop tail_position environment nil otherwise continuation
          (emit (IntegerBranch LessThanInteger view.position view.length nonempty) s1)
        cons_branch definitions stack loop tail_position environment variable view cons otherwise continuation
          (emit (Mark nonempty) empty_done)
    where
      list_shape : Administrative_Normal_Form_Constructor_Alternative -> Bool
      list_shape (Make_Administrative_Normal_Form_Constructor_Alternative _ NIL _ [] _) = True
      list_shape (Make_Administrative_Normal_Form_Constructor_Alternative _ CONS _ [_, _] _) = True
      list_shape _ = False

  private
  constant_case : Definitions -> List Name -> Maybe Loop -> Bool -> Environment -> Value ->
    List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form -> Continuation -> State -> Result
  constant_case definitions stack loop tail_position environment value [] otherwise continuation state =
    fallback definitions stack loop tail_position environment otherwise continuation state
  constant_case definitions stack loop tail_position environment value
    (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest) otherwise continuation state = do
      (actual, s1) <- integer_register value state
      (expected, s2) <- integer_register (Literal constant) s1
      let (different, s3) = label s2
      accepted <- evaluate definitions stack loop tail_position environment body continuation
        (emit (IntegerBranch NotEqualInteger actual expected different) s3)
      case (value, rest, otherwise) of
        (BooleanRegister _, [Make_Administrative_Normal_Form_Constant_Alternative other other_body], Nothing) =>
          if (number constant == Just 0 && number other == Just 1) ||
             (number constant == Just 1 && number other == Just 0)
            then evaluate definitions stack loop tail_position environment other_body continuation (emit (Mark different) accepted)
            else Left "DEX unpack Boolean case is not exhaustive"
        _ => constant_case definitions stack loop tail_position environment value rest otherwise continuation (emit (Mark different) accepted)

private
export_result : FrameworkValueType -> Continuation
export_result (ExistingValue TextValue) value state = do
  (register, next) <- text_register value state
  Right (emit (ReturnObject register) next)
export_result (ExistingValue IntegerValue) value state = do
  (register, next) <- integer_register value state
  Right (emit (ReturnInteger register) next)
export_result (ExistingValue BooleanValue) (BooleanRegister register) state = Right (emit (ReturnInteger register) state)
export_result _ _ _ = Left "DEX unpack result requires a supported scalar projection; source lists/objects do not escape"

private
parameter_value : FrameworkValueType -> Register -> Either String Value
parameter_value (ExistingValue TextValue) register = Right (TextRegister register)
parameter_value (ExistingValue IntegerValue) register = Right (IntegerRegister register)
parameter_value (ExistingValue BooleanValue) register = Right (BooleanRegister register)
parameter_value _ _ = Left "DEX unpack export parameters support only Text, Int32 and Bool"

private
initial_values : Int -> List FrameworkValueType -> Either String (List Value)
initial_values start [] = Right []
initial_values start (type :: rest) = do
  value <- parameter_value type (MkRegister start)
  more <- initial_values (start + 1) rest
  Right (value :: more)

private
parameter_moves : Int -> Int -> List FrameworkValueType -> List Instruction
parameter_moves incoming local [] = []
parameter_moves incoming local (type :: rest) =
  (case type of
     ExistingValue TextValue => MoveObject (MkRegister local) (MkRegister incoming)
     _ => Move (MkRegister local) (MkRegister incoming)) ::
  parameter_moves (incoming + 1) (local + 1) rest

export
lower_unpack_method : Definitions -> ForeignEffect -> Name -> String ->
  List FrameworkValueType -> FrameworkValueType -> Administrative_Normal_Form_Definition -> Either String MethodPlan
lower_unpack_method definitions effect name output arguments result definition = do
  if effect == PureForeign then Right () else Left "DEX unpack effectful source is not in the qualified slice"
  case definition of
    Make_Administrative_Normal_Form_Function formals body => do
      values <- initial_values 2 arguments
      bound <- bind_arguments formals values []
      let count = cast (length arguments)
      emitted <- evaluate definitions [name] Nothing True bound body (export_result result) (Emission (count + 2) 0 [])
      let registers = emitted.next_register + count
      if registers > 65535 then Left "DEX unpack register frame exceeds 65535" else Right ()
      Right (MkMethodPlan (show name) output count arguments result registers
        (parameter_moves emitted.next_register 2 arguments ++ reverse emitted.reverse_code))
    _ => Left "DEX unpack export has no checked function definition"
