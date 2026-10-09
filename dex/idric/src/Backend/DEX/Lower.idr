module Backend.DEX.Lower

import Backend.DEX.Foreign
import Backend.DEX.IR
import Compiler.ANF
import Core.FC
import Core.Name
import Core.TT.Primitive
import Core.TT.Term
import Data.List
import Data.Vect

%default covering

private
record LowerState where
  constructor MkLowerState
  integer_less_name : Name
  foreigns : List (Name, DEXForeign)
  world_variable : Maybe Int
  registers : List (Int, Register)
  value_types : List (Int, FrameworkValueType)
  result_register : Register
  next_label : Int
  instructions_reversed : List Instruction

private
emit : Instruction -> LowerState -> LowerState
emit instruction state =
  { instructions_reversed := instruction :: state.instructions_reversed } state

private
fresh_label : LowerState -> (Label, LowerState)
fresh_label state =
  (MkLabel state.next_label, { next_label $= (+ 1) } state)

private
lookup_register : String -> Int -> LowerState -> Either String Register
lookup_register role variable state =
  case find_register variable state.registers of
    Nothing => Left (role ++ " reads unknown ANF local v" ++ show variable)
    Just register => Right register
  where
    find_register : Int -> List (Int, Register) -> Maybe Register
    find_register requested [] = Nothing
    find_register requested ((candidate, register) :: rest) =
      if requested == candidate
        then Just register
        else find_register requested rest

private
lookup_value_type : String -> Int -> LowerState -> Either String FrameworkValueType
lookup_value_type role variable state =
  case find_type variable state.value_types of
    Nothing => Left (role ++ " has no checked DEX value type for ANF local v" ++ show variable)
    Just value_type => Right value_type
  where
    find_type : Int -> List (Int, FrameworkValueType) -> Maybe FrameworkValueType
    find_type requested [] = Nothing
    find_type requested ((candidate, value_type) :: rest) =
      if requested == candidate
        then Just value_type
        else find_type requested rest

private
set_value_type : Int -> FrameworkValueType -> LowerState -> LowerState
set_value_type variable value_type state =
  { value_types := (variable, value_type) :: state.value_types } state

private
append_unique : List Int -> Int -> List Int
append_unique values value =
  if elem value values then values else values ++ [value]

private
append_uniques : List Int -> List Int -> List Int
append_uniques values [] = values
append_uniques values (value :: rest) =
  append_uniques (append_unique values value) rest

mutual
  private
  collect_variables : Administrative_Normal_Form -> List Int
  collect_variables
    (Administrative_Normal_Form_Binding _ destination value body) =
      append_uniques
        (append_unique (collect_variables value) destination)
        (collect_variables body)
  collect_variables
    (Administrative_Normal_Form_Constructor_Case _ _ alternatives fallback) =
      append_uniques
        (collect_constructor_alternatives alternatives)
        (maybe [] collect_variables fallback)
  collect_variables
    (Administrative_Normal_Form_Constant_Case _ _ alternatives fallback) =
      append_uniques
        (collect_constant_alternatives alternatives)
        (maybe [] collect_variables fallback)
  collect_variables expression = []

  private
  collect_constructor_alternatives :
    List Administrative_Normal_Form_Constructor_Alternative -> List Int
  collect_constructor_alternatives [] = []
  collect_constructor_alternatives
    (Make_Administrative_Normal_Form_Constructor_Alternative
      _ _ _ arguments body :: rest) =
      append_uniques arguments
        (append_uniques (collect_variables body)
          (collect_constructor_alternatives rest))

  private
  collect_constant_alternatives :
    List Administrative_Normal_Form_Constant_Alternative -> List Int
  collect_constant_alternatives [] = []
  collect_constant_alternatives
    (Make_Administrative_Normal_Form_Constant_Alternative _ body :: rest) =
      append_uniques (collect_variables body)
        (collect_constant_alternatives rest)

private
number_registers_from : Int -> List Int -> List (Int, Register)
number_registers_from next [] = []
number_registers_from next (variable :: rest) =
  (variable, MkRegister next) :: number_registers_from (next + 1) rest

private
pair_types : List Int -> List FrameworkValueType -> Either String (List (Int, FrameworkValueType))
pair_types [] [] = Right []
pair_types (variable :: variables) (value_type :: value_types) = do
  rest <- pair_types variables value_types
  Right ((variable, value_type) :: rest)
pair_types _ _ = Left "Internal DEX ABI mismatch while assigning parameter types"

private
integer_condition : PrimFn 2 -> Maybe IntegerCondition
integer_condition (LT Int32Type) = Just LessThanInteger
integer_condition (LTE Int32Type) = Just LessEqualInteger
integer_condition (EQ Int32Type) = Just EqualInteger
integer_condition (GTE Int32Type) = Just GreaterEqualInteger
integer_condition (GT Int32Type) = Just GreaterThanInteger
integer_condition _ = Nothing

private
integer_binary : PrimFn 2 -> Maybe IntegerBinaryOperation
integer_binary (Add Int32Type) = Just AddInteger
integer_binary (Sub Int32Type) = Just SubtractInteger
integer_binary (Mul Int32Type) = Just MultiplyInteger
integer_binary _ = Nothing

private
underlying_name : Name -> Name
underlying_name (DN _ name) = underlying_name name
underlying_name name = name

private
is_checked_int32_less : Name -> Name -> Bool
is_checked_int32_less actual resolved_expected =
  underlying_name actual == underlying_name resolved_expected ||
  show actual == "Prelude.EqOrd.<" ||
  case actual of
    DN "Prelude.EqOrd.<" _ => True
    _ => False

private
is_checked_equal : Name -> Bool
is_checked_equal actual =
  show actual == "Prelude.EqOrd.==" ||
  case actual of
    DN "Prelude.EqOrd.==" _ => True
    _ => False

private
find_foreign : Name -> List (Name, DEXForeign) -> Maybe DEXForeign
find_foreign requested [] = Nothing
find_foreign requested ((name, foreign) :: rest) =
  if requested == name
    then Just foreign
    else find_foreign requested rest

-- Specialize only the checked ANF graph. Statically known source closures and
-- constructor values are consumed by their callers; they are not reinterpreted
-- as framework objects. A continuation distributes across cases so temporary
-- source sums can be projected without inventing an external sum ABI.
private
CheckedExpression : Type
CheckedExpression = Administrative_Normal_Form

private
CheckedVariable : Type
CheckedVariable = Administrative_Normal_Form_Variable

private
KnownValues : Type
KnownValues = List (Int, CheckedExpression)

private
SpecializedResult : Type
SpecializedResult = Either String (CheckedExpression, Int)

private
Continuation : Type
Continuation = CheckedExpression -> KnownValues -> Int -> SpecializedResult

private
known_value : FC -> KnownValues -> CheckedVariable -> CheckedExpression
known_value fc known Administrative_Normal_Form_Erased_Variable =
  Administrative_Normal_Form_Erased_Value fc
known_value fc known original@(Administrative_Normal_Form_Local_Variable variable) =
  case Data.List.lookup variable known of
    Nothing => Administrative_Normal_Form_Variable_Expression fc original
    Just (Administrative_Normal_Form_Variable_Expression _ next) =>
      if next == original
        then Administrative_Normal_Form_Variable_Expression fc original
        else known_value fc known next
    Just value => value

private
alias_variable : KnownValues -> CheckedVariable -> CheckedVariable
alias_variable known original@(Administrative_Normal_Form_Local_Variable variable) =
  case Data.List.lookup variable known of
    Just (Administrative_Normal_Form_Variable_Expression _ next) =>
      if next == original then original else alias_variable known next
    _ => original
alias_variable known variable = variable

private
renamed_variable : List (Int, Int) -> CheckedVariable -> CheckedVariable
renamed_variable renaming (Administrative_Normal_Form_Local_Variable variable) =
  Administrative_Normal_Form_Local_Variable (fromMaybe variable (Data.List.lookup variable renaming))
renamed_variable renaming variable = variable

mutual
  private
  rename_checked : List (Int, Int) -> CheckedExpression -> CheckedExpression
  rename_checked names (Administrative_Normal_Form_Variable_Expression fc variable) =
    Administrative_Normal_Form_Variable_Expression fc (renamed_variable names variable)
  rename_checked names (Administrative_Normal_Form_Named_Function_Application fc lazy name arguments) =
    Administrative_Normal_Form_Named_Function_Application fc lazy name (map (renamed_variable names) arguments)
  rename_checked names (Administrative_Normal_Form_Partial_Application fc name missing arguments) =
    Administrative_Normal_Form_Partial_Application fc name missing (map (renamed_variable names) arguments)
  rename_checked names (Administrative_Normal_Form_Closure_Application fc lazy closure argument) =
    Administrative_Normal_Form_Closure_Application fc lazy (renamed_variable names closure) (renamed_variable names argument)
  rename_checked names (Administrative_Normal_Form_Binding fc variable value body) =
    Administrative_Normal_Form_Binding fc (fromMaybe variable (Data.List.lookup variable names))
      (rename_checked names value) (rename_checked names body)
  rename_checked names (Administrative_Normal_Form_Constructor_Value fc name info tag arguments) =
    Administrative_Normal_Form_Constructor_Value fc name info tag (map (renamed_variable names) arguments)
  rename_checked names (Administrative_Normal_Form_Primitive_Operation fc lazy operation arguments) =
    Administrative_Normal_Form_Primitive_Operation fc lazy operation (map (renamed_variable names) arguments)
  rename_checked names (Administrative_Normal_Form_External_Primitive fc lazy name arguments) =
    Administrative_Normal_Form_External_Primitive fc lazy name (map (renamed_variable names) arguments)
  rename_checked names (Administrative_Normal_Form_Constructor_Case fc variable alternatives fallback) =
    Administrative_Normal_Form_Constructor_Case fc (renamed_variable names variable)
      (map (rename_constructor names) alternatives) (map (rename_checked names) fallback)
  rename_checked names (Administrative_Normal_Form_Constant_Case fc variable alternatives fallback) =
    Administrative_Normal_Form_Constant_Case fc (renamed_variable names variable)
      (map (rename_constant names) alternatives) (map (rename_checked names) fallback)
  rename_checked names expression = expression

  private
  rename_constructor : List (Int, Int) -> Administrative_Normal_Form_Constructor_Alternative -> Administrative_Normal_Form_Constructor_Alternative
  rename_constructor names (Make_Administrative_Normal_Form_Constructor_Alternative name info tag arguments body) =
    Make_Administrative_Normal_Form_Constructor_Alternative name info tag
      (map (\variable => fromMaybe variable (Data.List.lookup variable names)) arguments)
      (rename_checked names body)

  private
  rename_constant : List (Int, Int) -> Administrative_Normal_Form_Constant_Alternative -> Administrative_Normal_Form_Constant_Alternative
  rename_constant names (Make_Administrative_Normal_Form_Constant_Alternative constant body) =
    Make_Administrative_Normal_Form_Constant_Alternative constant (rename_checked names body)

private
variable_mentions : Int -> CheckedVariable -> Bool
variable_mentions requested (Administrative_Normal_Form_Local_Variable actual) = requested == actual
variable_mentions requested _ = False

mutual
  private
  expression_mentions : Int -> CheckedExpression -> Bool
  expression_mentions requested (Administrative_Normal_Form_Variable_Expression _ variable) = variable_mentions requested variable
  expression_mentions requested (Administrative_Normal_Form_Named_Function_Application _ _ _ arguments) = any (variable_mentions requested) arguments
  expression_mentions requested (Administrative_Normal_Form_Partial_Application _ _ _ arguments) = any (variable_mentions requested) arguments
  expression_mentions requested (Administrative_Normal_Form_Closure_Application _ _ closure argument) = variable_mentions requested closure || variable_mentions requested argument
  expression_mentions requested (Administrative_Normal_Form_Binding _ _ value body) = expression_mentions requested value || expression_mentions requested body
  expression_mentions requested (Administrative_Normal_Form_Constructor_Value _ _ _ _ arguments) = any (variable_mentions requested) arguments
  expression_mentions requested (Administrative_Normal_Form_Primitive_Operation _ _ _ arguments) = any (variable_mentions requested) (toList arguments)
  expression_mentions requested (Administrative_Normal_Form_External_Primitive _ _ _ arguments) = any (variable_mentions requested) arguments
  expression_mentions requested (Administrative_Normal_Form_Constructor_Case _ variable alternatives fallback) =
    variable_mentions requested variable || any (constructor_mentions requested) alternatives || maybe False (expression_mentions requested) fallback
  expression_mentions requested (Administrative_Normal_Form_Constant_Case _ variable alternatives fallback) =
    variable_mentions requested variable || any (constant_mentions requested) alternatives || maybe False (expression_mentions requested) fallback
  expression_mentions requested _ = False

  private
  constructor_mentions : Int -> Administrative_Normal_Form_Constructor_Alternative -> Bool
  constructor_mentions requested (Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ _ body) = expression_mentions requested body

  private
  constant_mentions : Int -> Administrative_Normal_Form_Constant_Alternative -> Bool
  constant_mentions requested (Make_Administrative_Normal_Form_Constant_Alternative _ body) = expression_mentions requested body

private
bind_known_arguments : FC -> List Int -> List CheckedVariable -> KnownValues -> Either String KnownValues
bind_known_arguments fc [] [] known = Right known
bind_known_arguments fc (formal :: formals) (actual :: actuals) known =
  bind_known_arguments fc formals actuals
    ((formal, Administrative_Normal_Form_Variable_Expression fc (alias_variable known actual)) :: known)
bind_known_arguments fc _ _ known = Left "Checked helper argument count mismatch during DEX specialization"

private
fresh_names : Int -> List Int -> (List (Int, Int), Int)
fresh_names next [] = ([], next)
fresh_names next (variable :: rest) =
  let (more, finish) = fresh_names (next + 1) rest in ((variable, next) :: more, finish)

private
find_checked_definition : Name -> List (Name, Administrative_Normal_Form_Definition) -> Maybe Administrative_Normal_Form_Definition
find_checked_definition name definitions = Data.List.lookup name definitions

private
residual_argument : FC -> KnownValues -> CheckedVariable -> Either String CheckedVariable
residual_argument fc known variable =
  case known_value fc known variable of
    Administrative_Normal_Form_Constructor_Value {} => Left "A source constructor cannot cross a raw DEX foreign boundary"
    Administrative_Normal_Form_Partial_Application {} => Left "A source closure cannot cross a raw DEX foreign boundary"
    _ => Right (alias_variable known variable)

mutual
  private
  specialize_with :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> KnownValues -> Int -> CheckedExpression -> Continuation -> SpecializedResult
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Binding fc variable value body) continuation =
      specialize_with integer_less foreigns definitions stack known next value
        (bind_specialized integer_less foreigns definitions stack fc variable body continuation)
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Named_Function_Application _ (Just _) _ _) continuation =
      Left "DEX specialization cannot evaluate a delayed named application"
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Named_Function_Application fc lazy name arguments) continuation =
      case find_foreign name foreigns of
        Just _ => do
          actuals <- traverse (residual_argument fc known) arguments
          continuation (Administrative_Normal_Form_Named_Function_Application fc lazy name actuals) known next
        Nothing =>
          if is_checked_int32_less name integer_less || is_checked_equal name
            then continuation
              (Administrative_Normal_Form_Named_Function_Application fc lazy name (map (alias_variable known) arguments)) known next
            else if elem name stack
              then Left ("Recursive checked helper is not in the DEX specialization slice: " ++ show name)
              else case find_checked_definition name definitions of
                Just (Make_Administrative_Normal_Form_Function formals body) => do
                  let variables = append_uniques formals (collect_variables body)
                  let (renaming, after_names) = fresh_names next variables
                  let fresh_formals = map (\variable => fromMaybe variable (Data.List.lookup variable renaming)) formals
                  extended <- bind_known_arguments fc fresh_formals arguments known
                  specialize_with integer_less foreigns definitions (name :: stack) extended after_names
                    (rename_checked renaming body) continuation
                _ => Left ("No checked helper body for DEX call " ++ show name)
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Closure_Application _ (Just _) _ _) continuation =
      Left "DEX specialization cannot evaluate a delayed closure application"
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Closure_Application fc lazy closure argument) continuation =
      case known_value fc known closure of
        Administrative_Normal_Form_Partial_Application _ name (S Z) captures =>
          specialize_with integer_less foreigns definitions stack known next
            (Administrative_Normal_Form_Named_Function_Application fc lazy name
              (captures ++ [alias_variable known argument])) continuation
        Administrative_Normal_Form_Partial_Application _ name (S missing) captures =>
          continuation (Administrative_Normal_Form_Partial_Application fc name missing
            (captures ++ [alias_variable known argument])) known next
        _ => Left "DEX cannot execute an unknown runtime source closure"
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Variable_Expression fc variable) continuation =
      case known_value fc known variable of
        value@(Administrative_Normal_Form_Constructor_Value {}) => continuation value known next
        value@(Administrative_Normal_Form_Partial_Application {}) => continuation value known next
        value@(Administrative_Normal_Form_Erased_Value {}) => continuation value known next
        _ => continuation (Administrative_Normal_Form_Variable_Expression fc (alias_variable known variable)) known next
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Partial_Application fc name missing arguments) continuation =
      continuation (Administrative_Normal_Form_Partial_Application fc name missing (map (alias_variable known) arguments)) known next
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Constructor_Value fc name info tag arguments) continuation =
      continuation (Administrative_Normal_Form_Constructor_Value fc name info tag (map (alias_variable known) arguments)) known next
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Primitive_Operation _ (Just _) _ _) continuation =
      Left "DEX specialization cannot evaluate a delayed primitive application"
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Primitive_Operation fc lazy operation arguments) continuation =
      continuation (Administrative_Normal_Form_Primitive_Operation fc lazy operation (map (alias_variable known) arguments)) known next
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_External_Primitive _ (Just _) _ _) continuation =
      Left "DEX specialization cannot evaluate a delayed external primitive application"
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Constructor_Case fc scrutinee alternatives fallback) continuation =
      case known_value fc known scrutinee of
        Administrative_Normal_Form_Constructor_Value _ name _ _ fields =>
          specialize_known_constructor integer_less foreigns definitions stack known next fc name fields alternatives fallback continuation
        _ => do
          (branches, after_branches) <- specialize_constructor_branches integer_less foreigns definitions stack known next alternatives continuation
          (otherwise, after_default) <- specialize_fallback integer_less foreigns definitions stack known after_branches fallback continuation
          Right (Administrative_Normal_Form_Constructor_Case fc (alias_variable known scrutinee) branches otherwise, after_default)
  specialize_with integer_less foreigns definitions stack known next
    (Administrative_Normal_Form_Constant_Case fc scrutinee alternatives fallback) continuation =
      case known_value fc known scrutinee of
        Administrative_Normal_Form_Primitive_Value _ constant =>
          specialize_known_constant integer_less foreigns definitions stack known next constant alternatives fallback continuation
        _ => do
          (branches, after_branches) <- specialize_constant_branches integer_less foreigns definitions stack known next alternatives continuation
          (otherwise, after_default) <- specialize_fallback integer_less foreigns definitions stack known after_branches fallback continuation
          Right (Administrative_Normal_Form_Constant_Case fc (alias_variable known scrutinee) branches otherwise, after_default)
  specialize_with integer_less foreigns definitions stack known next expression continuation =
    continuation expression known next

  private
  bind_specialized :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> FC -> Int -> CheckedExpression -> Continuation -> Continuation
  bind_specialized integer_less foreigns definitions stack fc variable body continuation value known next =
    case value of
      Administrative_Normal_Form_Constructor_Value {} =>
        specialize_with integer_less foreigns definitions stack ((variable, value) :: known) next body continuation
      Administrative_Normal_Form_Partial_Application {} =>
        specialize_with integer_less foreigns definitions stack ((variable, value) :: known) next body continuation
      Administrative_Normal_Form_Variable_Expression {} =>
        specialize_with integer_less foreigns definitions stack ((variable, value) :: known) next body continuation
      Administrative_Normal_Form_Erased_Value {} =>
        specialize_with integer_less foreigns definitions stack ((variable, value) :: known) next body continuation
      Administrative_Normal_Form_Primitive_Value {} => do
        (rest, after) <- specialize_with integer_less foreigns definitions stack ((variable, value) :: known) next body continuation
        if expression_mentions variable rest
          then Right (Administrative_Normal_Form_Binding fc variable value rest, after)
          else Right (rest, after)
      _ => do
        (rest, after) <- specialize_with integer_less foreigns definitions stack known next body continuation
        -- A residual call/primitive is evaluated even when its result is unused.
        Right (Administrative_Normal_Form_Binding fc variable value rest, after)

  private
  specialize_known_constructor :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> KnownValues -> Int -> FC -> Name -> List CheckedVariable ->
    List Administrative_Normal_Form_Constructor_Alternative -> Maybe CheckedExpression -> Continuation -> SpecializedResult
  specialize_known_constructor integer_less foreigns definitions stack known next fc name fields [] (Just fallback) continuation =
    specialize_with integer_less foreigns definitions stack known next fallback continuation
  specialize_known_constructor integer_less foreigns definitions stack known next fc name fields [] Nothing continuation =
    Left ("No checked constructor branch for " ++ show name)
  specialize_known_constructor integer_less foreigns definitions stack known next fc name fields
    (Make_Administrative_Normal_Form_Constructor_Alternative candidate _ _ arguments body :: rest) fallback continuation =
      if name == candidate
        then do
          extended <- bind_known_arguments fc arguments fields known
          specialize_with integer_less foreigns definitions stack extended next body continuation
        else specialize_known_constructor integer_less foreigns definitions stack known next fc name fields rest fallback continuation

  private
  specialize_known_constant :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> KnownValues -> Int -> Constant ->
    List Administrative_Normal_Form_Constant_Alternative -> Maybe CheckedExpression -> Continuation -> SpecializedResult
  specialize_known_constant integer_less foreigns definitions stack known next constant [] (Just fallback) continuation =
    specialize_with integer_less foreigns definitions stack known next fallback continuation
  specialize_known_constant integer_less foreigns definitions stack known next constant [] Nothing continuation =
    Left ("No checked constant branch for " ++ show constant)
  specialize_known_constant integer_less foreigns definitions stack known next constant
    (Make_Administrative_Normal_Form_Constant_Alternative candidate body :: rest) fallback continuation =
      if constant == candidate
        then specialize_with integer_less foreigns definitions stack known next body continuation
        else specialize_known_constant integer_less foreigns definitions stack known next constant rest fallback continuation

  private
  specialize_constructor_branches :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> KnownValues -> Int -> List Administrative_Normal_Form_Constructor_Alternative -> Continuation ->
    Either String (List Administrative_Normal_Form_Constructor_Alternative, Int)
  specialize_constructor_branches integer_less foreigns definitions stack known next [] continuation = Right ([], next)
  specialize_constructor_branches integer_less foreigns definitions stack known next
    (Make_Administrative_Normal_Form_Constructor_Alternative name info tag arguments body :: rest) continuation = do
      (branch, after_branch) <- specialize_with integer_less foreigns definitions stack known next body continuation
      (more, after_more) <- specialize_constructor_branches integer_less foreigns definitions stack known after_branch rest continuation
      Right (Make_Administrative_Normal_Form_Constructor_Alternative name info tag arguments branch :: more, after_more)

  private
  specialize_constant_branches :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> KnownValues -> Int -> List Administrative_Normal_Form_Constant_Alternative -> Continuation ->
    Either String (List Administrative_Normal_Form_Constant_Alternative, Int)
  specialize_constant_branches integer_less foreigns definitions stack known next [] continuation = Right ([], next)
  specialize_constant_branches integer_less foreigns definitions stack known next
    (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest) continuation = do
      (branch, after_branch) <- specialize_with integer_less foreigns definitions stack known next body continuation
      (more, after_more) <- specialize_constant_branches integer_less foreigns definitions stack known after_branch rest continuation
      Right (Make_Administrative_Normal_Form_Constant_Alternative constant branch :: more, after_more)

  private
  specialize_fallback :
    Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
    List Name -> KnownValues -> Int -> Maybe CheckedExpression -> Continuation ->
    Either String (Maybe CheckedExpression, Int)
  specialize_fallback integer_less foreigns definitions stack known next Nothing continuation = Right (Nothing, next)
  specialize_fallback integer_less foreigns definitions stack known next (Just body) continuation = do
    (branch, after) <- specialize_with integer_less foreigns definitions stack known next body continuation
    Right (Just branch, after)

private
specialize_body :
  Name -> List (Name, DEXForeign) -> List (Name, Administrative_Normal_Form_Definition) ->
  List Int -> CheckedExpression -> Either String CheckedExpression
specialize_body integer_less foreigns definitions arguments body = do
  let next = 1 + foldl max 0 (arguments ++ collect_variables body)
  (specialized, _) <- specialize_with integer_less foreigns definitions [] [] next body
    (\value, known, final => Right (value, final))
  Right specialized

private
foreign_result_value_type : DEXForeign -> Either String FrameworkValueType
foreign_result_value_type foreign =
  case foreign.method.result of
    ExistingValue BooleanValue => Right (ExistingValue IntegerValue)
    ExistingValue value => Right (ExistingValue value)
    ReferenceValue reference => Right (ReferenceValue reference)
    LongValue =>
      Left
        ("DEX source lowering does not yet allocate a register pair for foreign result " ++
         show foreign.method)
    VoidValue => Right VoidValue

private
same_register_type : FrameworkValueType -> FrameworkValueType -> Bool
same_register_type (ExistingValue IntegerValue) (ExistingValue BooleanValue) = True
same_register_type (ExistingValue BooleanValue) (ExistingValue IntegerValue) = True
same_register_type left right = framework_descriptor left == framework_descriptor right

private
foreign_argument_registers :
  String -> List FrameworkValueType -> List Administrative_Normal_Form_Variable -> LowerState ->
  Either String (List Register)
foreign_argument_registers role [] [] state = Right []
foreign_argument_registers role (expected :: expected_rest)
  (Administrative_Normal_Form_Local_Variable variable :: rest) state = do
  actual <- lookup_value_type role variable state
  if same_register_type actual expected
    then Right ()
    else Left (role ++ " expected " ++ show expected ++ ", got " ++ show actual)
  register <- lookup_register role variable state
  more <- foreign_argument_registers role expected_rest rest state
  Right (register :: more)
foreign_argument_registers role expected
  (Administrative_Normal_Form_Erased_Variable :: rest) state =
  Left (role ++ " contains an erased ordinary argument")
foreign_argument_registers role _ _ state =
  Left (role ++ " argument count does not match the checked foreign signature")

private
ordinary_foreign_arguments :
  DEXForeign -> List Administrative_Normal_Form_Variable -> LowerState ->
  Either String (List Administrative_Normal_Form_Variable)
ordinary_foreign_arguments foreign arguments state =
  if foreign.effect == PureForeign
    then Right arguments
    else case (state.world_variable, reverse arguments) of
      (Just expected, Administrative_Normal_Form_Local_Variable actual :: rest) =>
        if expected == actual
          then Right (reverse rest)
          else Left "DEX foreign call received a different World token"
      (Just _, Administrative_Normal_Form_Erased_Variable :: rest) =>
        Right (reverse rest)
      _ => Left "DEX primitive IO call has no checked trailing World token"

private
lower_foreign_call :
  Register -> FrameworkValueType -> Name -> List Administrative_Normal_Form_Variable ->
  LowerState -> Either String LowerState
lower_foreign_call destination destination_type name arguments state =
  case find_foreign name state.foreigns of
    Nothing =>
      Left ("Unsupported checked named call in DEX checked slice: " ++ show name)
    Just foreign => do
          result_type <- foreign_result_value_type foreign
          if not (same_register_type result_type destination_type)
            then
              Left
                ("DEX foreign result type mismatch for " ++ show foreign.method ++
                 ": inferred " ++ show result_type ++
                 ", destination is " ++ show destination_type)
            else Right ()
          ordinary <- ordinary_foreign_arguments foreign arguments state
          registers <-
            foreign_argument_registers
              ("Foreign call " ++ show name)
              (target_argument_types foreign.invocation_kind foreign.method)
              ordinary state
          Right
            (emit
              (InvokeMethod
                (Invoke foreign.invocation_kind foreign.method registers
                  (if result_type == VoidValue then Nothing else Just destination)))
              state)

private
lower_comparison :
  IntegerCondition -> Register -> Register -> Register -> LowerState -> LowerState
lower_comparison condition destination left right state =
  let (true_label, after_true_label) = fresh_label state
      (done_label, after_done_label) = fresh_label after_true_label
  in emit (Mark done_label)
       (emit (IntegerConstant destination 1)
         (emit (Mark true_label)
           (emit (Goto done_label)
             (emit (IntegerBranch condition left right true_label)
               (emit (IntegerConstant destination 0) after_done_label)))))

private
lower_primitive :
  Register -> PrimFn arity ->
  Vect arity Administrative_Normal_Form_Variable -> LowerState ->
  Either String LowerState
lower_primitive destination operation arguments state =
  case (operation, arguments) of
    (EQ StringType,
      [Administrative_Normal_Form_Local_Variable left_variable,
       Administrative_Normal_Form_Local_Variable right_variable]) => do
      left <- lookup_register "Text equality left operand" left_variable state
      right <- lookup_register "Text equality right operand" right_variable state
      left_type <- lookup_value_type "Text equality left operand" left_variable state
      right_type <- lookup_value_type "Text equality right operand" right_variable state
      if left_type /= ExistingValue TextValue || right_type /= ExistingValue TextValue
        then Left "Checked String equality received a non-Text DEX operand"
        else Right (emit (TextEqual destination left right) state)
    (binary,
      [Administrative_Normal_Form_Local_Variable left_variable,
       Administrative_Normal_Form_Local_Variable right_variable]) => do
      left <- lookup_register "Int32 primitive left operand" left_variable state
      right <- lookup_register "Int32 primitive right operand" right_variable state
      left_type <- lookup_value_type "Int32 primitive left operand" left_variable state
      right_type <- lookup_value_type "Int32 primitive right operand" right_variable state
      if left_type /= ExistingValue IntegerValue || right_type /= ExistingValue IntegerValue
        then Left "DEX Int32 primitive received a non-Int32 checked operand"
        else Right ()
      case integer_binary binary of
        Just accepted =>
          Right (emit (IntegerBinary accepted destination left right) state)
        Nothing =>
          case integer_condition binary of
            Just accepted =>
              Right (lower_comparison accepted destination left right state)
            Nothing =>
              Left
                ("Unsupported checked primitive in DEX Int32/Text subset: " ++
                 show operation)
    _ =>
      Left
        ("DEX checked primitive operands must be two ANF locals, got " ++
         show operation)

private
infer_value_type : Administrative_Normal_Form -> LowerState -> Either String FrameworkValueType
infer_value_type
  (Administrative_Normal_Form_Variable_Expression _
    (Administrative_Normal_Form_Local_Variable source_variable)) state =
  lookup_value_type "Value" source_variable state
infer_value_type (Administrative_Normal_Form_Primitive_Value _ (I32 _)) state =
  Right (ExistingValue IntegerValue)
infer_value_type (Administrative_Normal_Form_Primitive_Value _ (Str _)) state =
  Right (ExistingValue TextValue)
infer_value_type
  (Administrative_Normal_Form_Primitive_Operation _ _ (EQ StringType) arguments) state =
  Right (ExistingValue IntegerValue)
infer_value_type
  (Administrative_Normal_Form_Primitive_Operation _ _ operation [_, _]) state =
  case integer_binary operation of
    Just _ => Right (ExistingValue IntegerValue)
    Nothing =>
      case integer_condition operation of
        Just _ => Right (ExistingValue IntegerValue)
        Nothing => Left ("Cannot infer DEX value type for primitive " ++ show operation)
infer_value_type
  (Administrative_Normal_Form_Primitive_Operation _ _ operation arguments) state =
  Left ("Cannot infer DEX value type for primitive " ++ show operation)
infer_value_type
  (Administrative_Normal_Form_Named_Function_Application _ _ name [_, _]) state =
  if is_checked_int32_less name state.integer_less_name || is_checked_equal name
    then Right (ExistingValue IntegerValue)
    else
      case find_foreign name state.foreigns of
        Nothing => Left ("Cannot infer DEX value type for checked call " ++ show name)
        Just foreign => foreign_result_value_type foreign
infer_value_type
  (Administrative_Normal_Form_Named_Function_Application _ _ name _) state =
  case find_foreign name state.foreigns of
    Nothing => Left ("Cannot infer DEX value type for checked call " ++ show name)
    Just foreign => foreign_result_value_type foreign
infer_value_type (Administrative_Normal_Form_Erased_Value _) state = Right VoidValue
infer_value_type expression state =
  Left ("Cannot infer DEX value type for checked ANF: " ++ show expression)

private
lower_copy :
  Register -> FrameworkValueType -> Administrative_Normal_Form_Variable -> LowerState ->
  Either String LowerState
lower_copy destination destination_type variable state =
  case variable of
    Administrative_Normal_Form_Erased_Variable =>
      if destination_type == VoidValue
        then Right state
        else Left "An erased DEX value cannot produce a non-void result"
    Administrative_Normal_Form_Local_Variable source_variable => do
      source <- lookup_register "Copy" source_variable state
      source_type <- lookup_value_type "Copy source" source_variable state
      if not (same_register_type source_type destination_type)
        then
          Left
            ("DEX copy type mismatch: source is " ++ show source_type ++
             ", destination is " ++ show destination_type)
        else if destination == source || destination_type == VoidValue
          then Right state
          else
            Right
              (emit
                (case destination_type of
                   ExistingValue IntegerValue => Move destination source
                   ExistingValue BooleanValue => Move destination source
                   ExistingValue TextValue => MoveObject destination source
                   ExistingValue ObjectValue => MoveObject destination source
                   ReferenceValue _ => MoveObject destination source
                   LongValue => MoveWide destination source
                   VoidValue => Move destination source)
                state)

private
lower_literal :
  Register -> FrameworkValueType -> Constant -> LowerState -> Either String LowerState
lower_literal destination destination_type constant state =
  case constant of
    I32 value =>
      if destination_type == ExistingValue IntegerValue
        then Right (emit (IntegerConstant destination (cast value)) state)
        else if destination_type == ExistingValue BooleanValue
          then if value == 0 || value == 1
            then Right (emit (IntegerConstant destination (cast value)) state)
            else Left "Checked Boolean result has a non-Boolean Int32 literal"
          else unsupported
    I value =>
      if destination_type == ExistingValue BooleanValue
        then if value == 0 || value == 1
          then Right (emit (IntegerConstant destination value) state)
          else Left "Checked Boolean result has a non-Boolean compiler enum tag"
        else Left
          ("Idriç Int is 64-bit in the current compiler; the DEX checked slice " ++
           "accepts Int32 or Text (got literal " ++ show value ++ ")")
    Str value =>
      if destination_type == ExistingValue TextValue
        then Right (emit (TextConstant destination value) state)
        else unsupported
    _ => unsupported
  where
    unsupported : Either String LowerState
    unsupported = Left ("Unsupported checked DEX literal " ++ show constant ++
                       " for result type " ++ show destination_type)

private
lower_primitive_result :
  Register -> FrameworkValueType -> PrimFn arity ->
  Vect arity Administrative_Normal_Form_Variable -> LowerState -> Either String LowerState
lower_primitive_result destination destination_type operation arguments state =
  if destination_type == ExistingValue IntegerValue ||
     destination_type == ExistingValue BooleanValue
    then lower_primitive destination operation arguments state
    else Left ("Unsupported checked DEX primitive result type " ++ show destination_type)

private
lower_scalar_call :
  Register -> Name -> List Administrative_Normal_Form_Variable -> LowerState ->
  Either String LowerState
lower_scalar_call destination name arguments state =
  case arguments of
    [Administrative_Normal_Form_Local_Variable left_variable,
     Administrative_Normal_Form_Local_Variable right_variable] =>
      if is_checked_int32_less name state.integer_less_name
        then do
          left <- lookup_register "Int32 < left operand" left_variable state
          right <- lookup_register "Int32 < right operand" right_variable state
          left_type <- lookup_value_type "Int32 < left operand" left_variable state
          right_type <- lookup_value_type "Int32 < right operand" right_variable state
          if left_type == ExistingValue IntegerValue && right_type == ExistingValue IntegerValue
            then Right (lower_comparison LessThanInteger destination left right state)
            else Left "Checked < is outside the DEX Int32 comparison slice"
        else if is_checked_equal name
          then do
            left <- lookup_register "Equality left operand" left_variable state
            right <- lookup_register "Equality right operand" right_variable state
            left_type <- lookup_value_type "Equality left operand" left_variable state
            right_type <- lookup_value_type "Equality right operand" right_variable state
            if left_type == ExistingValue TextValue && right_type == ExistingValue TextValue
              then Right (emit (TextEqual destination left right) state)
              else if left_type == ExistingValue IntegerValue && right_type == ExistingValue IntegerValue
                then Right (lower_comparison EqualInteger destination left right state)
                else Left "Checked == is outside the DEX Int32/Text equality slice"
          else
            lower_foreign_call destination (ExistingValue IntegerValue) name arguments state
    _ => lower_foreign_call destination (ExistingValue IntegerValue) name arguments state

private
lower_named_call :
  Register -> FrameworkValueType -> Name -> List Administrative_Normal_Form_Variable ->
  LowerState -> Either String LowerState
lower_named_call destination destination_type name arguments state =
  if destination_type == ExistingValue IntegerValue ||
     destination_type == ExistingValue BooleanValue
    then lower_scalar_call destination name arguments state
    else lower_foreign_call destination destination_type name arguments state

mutual
  private
  lower_to :
    Register -> FrameworkValueType -> Administrative_Normal_Form -> LowerState ->
    Either String LowerState
  lower_to destination destination_type expression state =
    -- Dispatch on the expression once. Overlapping expression/result-type
    -- clauses expand into a large repeated case tree in the bootstrap compiler.
    case expression of
      Administrative_Normal_Form_Variable_Expression _ variable =>
        lower_copy destination destination_type variable state
      Administrative_Normal_Form_Primitive_Value _ constant =>
        lower_literal destination destination_type constant state
      Administrative_Normal_Form_Primitive_Operation _ _ operation arguments =>
        lower_primitive_result destination destination_type operation arguments state
      Administrative_Normal_Form_Named_Function_Application _ _ name arguments =>
        lower_named_call destination destination_type name arguments state
      Administrative_Normal_Form_Binding _ nested_destination value body => do
        target <- lookup_register "Let destination" nested_destination state
        nested_type <- infer_value_type value state
        let typed_state = set_value_type nested_destination nested_type state
        after_value <- lower_to target nested_type value typed_state
        lower_to destination destination_type body after_value
      Administrative_Normal_Form_Constructor_Case _ variable alternatives fallback =>
        case variable of
          Administrative_Normal_Form_Local_Variable scrutinee =>
            lower_boolean_case destination destination_type scrutinee alternatives fallback state
          _ => unsupported
      Administrative_Normal_Form_Constant_Case _ variable alternatives fallback =>
        case variable of
          Administrative_Normal_Form_Local_Variable scrutinee =>
            lower_constant_case destination destination_type scrutinee alternatives fallback state
          _ => unsupported
      Administrative_Normal_Form_Erased_Value _ =>
        if destination_type == VoidValue then Right state else unsupported
      _ => unsupported
    where
      unsupported : Either String LowerState
      unsupported = Left
        ("Unsupported checked ANF for DEX result type " ++ show destination_type ++
         ": " ++ show expression)

  private
  lower_boolean_case :
    Register -> FrameworkValueType -> Int ->
    List Administrative_Normal_Form_Constructor_Alternative ->
    Maybe Administrative_Normal_Form -> LowerState -> Either String LowerState
  lower_boolean_case destination destination_type scrutinee_variable alternatives fallback state = do
    scrutinee <- lookup_register "Boolean case scrutinee" scrutinee_variable state
    scrutinee_type <- lookup_value_type "Boolean case scrutinee" scrutinee_variable state
    if not (same_register_type scrutinee_type (ExistingValue IntegerValue))
      then Left "DEX Boolean case scrutinee is not an Int32/Boolean value"
      else Right ()
    false_body <- find_constructor_tag 0 alternatives fallback
    true_body <- find_constructor_tag 1 alternatives fallback
    let (false_label, after_false_label) = fresh_label state
    let (done_label, after_done_label) = fresh_label after_false_label
    let with_zero = emit (IntegerConstant destination 0) after_done_label
    let with_branch =
          emit (IntegerBranch EqualInteger scrutinee destination false_label) with_zero
    after_true <- lower_to destination destination_type true_body with_branch
    let with_goto = emit (Goto done_label) after_true
    let at_false = emit (Mark false_label) with_goto
    after_false <- lower_to destination destination_type false_body at_false
    Right (emit (Mark done_label) after_false)

  private
  lower_constant_case :
    Register -> FrameworkValueType -> Int ->
    List Administrative_Normal_Form_Constant_Alternative ->
    Maybe Administrative_Normal_Form -> LowerState -> Either String LowerState
  lower_constant_case destination destination_type scrutinee_variable alternatives fallback state = do
    scrutinee <- lookup_register "Boolean case scrutinee" scrutinee_variable state
    scrutinee_type <- lookup_value_type "Boolean case scrutinee" scrutinee_variable state
    if not (same_register_type scrutinee_type (ExistingValue IntegerValue))
      then Left "DEX Boolean constant case scrutinee is not Int32"
      else Right ()
    let (done_label, after_done_label) = fresh_label state
    lowered <- lower_constant_alternatives destination destination_type scrutinee
      done_label alternatives fallback after_done_label
    Right (emit (Mark done_label) lowered)

  private
  lower_constant_alternatives :
    Register -> FrameworkValueType -> Register -> Label ->
    List Administrative_Normal_Form_Constant_Alternative ->
    Maybe Administrative_Normal_Form -> LowerState -> Either String LowerState
  lower_constant_alternatives destination destination_type scrutinee done []
    (Just fallback) state = lower_to destination destination_type fallback state
  lower_constant_alternatives destination destination_type scrutinee done [] Nothing state =
    Left "Residual DEX integer case needs an explicit default"
  lower_constant_alternatives destination destination_type scrutinee done
    [Make_Administrative_Normal_Form_Constant_Alternative constant body] Nothing state =
    -- The source checker proved this final alternative exhaustive. Earlier
    -- tests route only its remaining case here; no fabricated default value.
    lower_to destination destination_type body state
  lower_constant_alternatives destination destination_type scrutinee done
    (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest) fallback state = do
    code <- constant_case_integer constant
    let (next_case, with_label) = fresh_label state
    let with_constant = emit (IntegerConstant destination code) with_label
    let with_test = emit (IntegerBranch NotEqualInteger scrutinee destination next_case) with_constant
    selected <- lower_to destination destination_type body with_test
    let after_selected = emit (Mark next_case) (emit (Goto done) selected)
    lower_constant_alternatives destination destination_type scrutinee done rest fallback after_selected

  private
  constant_case_integer : Constant -> Either String Int
  constant_case_integer (I32 value) = Right (cast value)
  constant_case_integer (I value) =
    if value >= -2147483648 && value <= 2147483647
      then Right value
      else Left "DEX compiler enum case tag exceeds an Int32 register"
  constant_case_integer constant =
    Left ("Unsupported DEX case constant " ++ show constant)

  private
  constant_tag : Constant -> Maybe Int
  constant_tag (I8 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (I16 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (I32 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (I64 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (I value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (BI value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (B8 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (B16 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (B32 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag (B64 value) = if value == 0 || value == 1 then Just (cast value) else Nothing
  constant_tag constant = Nothing

  private
  find_constant_tag :
    Int ->
    List Administrative_Normal_Form_Constant_Alternative ->
    Maybe Administrative_Normal_Form -> Either String Administrative_Normal_Form
  find_constant_tag requested [] Nothing =
    Left
      ("DEX Boolean constant case has no tag " ++ show requested ++
       " and no fallback")
  find_constant_tag requested [] (Just fallback) = Right fallback
  find_constant_tag requested
    (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest)
    fallback =
      case constant_tag constant of
        Just tag =>
          if tag == requested
            then Right body
            else find_constant_tag requested rest fallback
        Nothing =>
          Left
            ("DEX Boolean case has a non-Boolean constant alternative: " ++
             show constant)

  private
  find_constructor_tag :
    Int ->
    List Administrative_Normal_Form_Constructor_Alternative ->
    Maybe Administrative_Normal_Form -> Either String Administrative_Normal_Form
  find_constructor_tag requested [] Nothing =
    Left
      ("DEX Boolean case has no constructor tag " ++ show requested ++
       " and no fallback")
  find_constructor_tag requested [] (Just fallback) = Right fallback
  find_constructor_tag requested
    (Make_Administrative_Normal_Form_Constructor_Alternative
      _ _ (Just tag) arguments body :: rest) fallback =
      if tag == requested
        then if null arguments
          then Right body
          else Left "DEX Boolean alternatives must be nullary"
        else find_constructor_tag requested rest fallback
  find_constructor_tag requested
    (Make_Administrative_Normal_Form_Constructor_Alternative
      name _ Nothing _ _ :: rest) fallback =
      Left "DEX Boolean alternative has no constructor tag"

private
finish_method :
  FrameworkValueType -> Administrative_Normal_Form -> LowerState ->
  Either String (List Instruction)
finish_method result_type body state = do
  lowered <- lower_to state.result_register result_type body state
  let final_instruction =
        case result_type of
          ExistingValue IntegerValue => ReturnInteger lowered.result_register
          ExistingValue BooleanValue => ReturnInteger lowered.result_register
          ExistingValue TextValue => ReturnObject lowered.result_register
          ExistingValue ObjectValue => ReturnObject lowered.result_register
          ReferenceValue _ => ReturnObject lowered.result_register
          LongValue => ReturnWide lowered.result_register
          VoidValue => ReturnVoid
  Right (reverse (final_instruction :: lowered.instructions_reversed))

private
is_ascii_letter : Char -> Bool
is_ascii_letter character =
  (character >= 'A' && character <= 'Z') ||
  (character >= 'a' && character <= 'z')

private
is_ascii_digit : Char -> Bool
is_ascii_digit character = character >= '0' && character <= '9'

public export
validate_method_name : String -> Either String String
validate_method_name name =
  case unpack name of
    [] => Left "A DEX method name cannot be empty"
    first :: rest =>
      if (is_ascii_letter first || first == '_') &&
         all (\character =>
           is_ascii_letter character || is_ascii_digit character || character == '_') rest
        then Right name
        else Left ("Unsupported DEX method name `" ++ name ++ "`")

||| Lower an already checked ANF function. Idriç checking and source ABI
||| classification happen before this function; this pass owns only dense DEX
||| virtual-register placement and target instruction planning.
public export
lower_method :
  Name -> List (Name, DEXForeign) ->
  List (Name, Administrative_Normal_Form_Definition) -> ForeignEffect -> String -> String ->
  List FrameworkValueType -> FrameworkValueType ->
  Administrative_Normal_Form_Definition -> Either String MethodPlan
lower_method integer_less_name foreigns definitions effect source_name requested_method parameter_types result_type
  (Make_Administrative_Normal_Form_Function arguments body) = do
  method_name <- validate_method_name requested_method
  (ordinary_arguments, world) <-
    if effect == PureForeign
      then Right (arguments, Nothing)
      else case reverse arguments of
        token :: ordinary => Right (reverse ordinary, Just token)
        [] => Left "Effectful DEX export has no trailing checked World argument"
  if length ordinary_arguments /= length parameter_types
    then Left "Internal DEX ABI mismatch between checked arguments and parameter types"
    else Right ()
  specialized <- specialize_body integer_less_name foreigns definitions arguments body
  let discovered = collect_variables specialized
  let local_variables = filter (\variable => not (elem variable ordinary_arguments) && Just variable /= world) discovered
  let local_registers = number_registers_from 0 local_variables
  let local_count : Int = cast (length local_variables)
  let result_register = MkRegister local_count
  let parameter_start = local_count + 1
  let argument_registers = number_registers_from parameter_start ordinary_arguments
  let mapping = local_registers ++ argument_registers
  argument_types <- pair_types ordinary_arguments parameter_types
  let parameter_count : Int = cast (length ordinary_arguments)
  let register_count = parameter_start + parameter_count
  instructions <-
    finish_method result_type specialized
      (MkLowerState integer_less_name foreigns world mapping argument_types result_register 0 [])
  Right
    (MkMethodPlan source_name method_name parameter_count parameter_types result_type
      register_count instructions)
lower_method integer_less_name foreigns definitions effect source_name requested_method parameter_types result_type definition =
  Left
    ("DEX export `" ++ source_name ++ "` is not a checked function: " ++
     show definition)
