module Backend.DEX.Heap

import Backend.DEX.IR
import Backend.DEX.NativeContract
import Backend.DEX.ValueLayout
import Compiler.ANF
import Core.CompileExpr
import Core.Name
import Core.TT.Primitive
import Core.TT.Term
import Data.List
import Data.Vect

%default covering

-- Internal managed ABI. These are platform storage choices, never external
-- source descriptors: an ordinary source constructor is not a foreign object.
private
object_value : FrameworkValueType
object_value = ExistingValue ObjectValue

private
text_value : FrameworkValueType
text_value = ExistingValue TextValue

private
integer_value : FrameworkValueType
integer_value = ExistingValue IntegerValue

private
node_type : TypeReference
node_type = managed_node_type

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
register : Int -> Register
register = MkRegister

private
record TailContext where
  constructor MkTailContext
  targets : List (Name, (Int, Int))
  common_parameters : List Register
  temporary_references : List Register
  dispatch_label : Label

-- Register 14 is reserved for a tail group's integer selector. Ordinary heap
-- primitives use 0..9, erased World uses 15, and expression results use 16.

private
record HeapState where
  constructor MkHeapState
  methods : List (Name, (String, Int))
  locals : List (Int, Register)
  next_label : Int
  code : List Instruction
  tail_context : Maybe TailContext

private
emit : List Instruction -> HeapState -> HeapState
emit instructions state = { code := state.code ++ instructions } state

private
fresh_label : HeapState -> (Label, HeapState)
fresh_label state = (MkLabel state.next_label, { next_label $= (+ 1) } state)

private
local : Int -> HeapState -> Either String Register
local variable state = maybe (Left ("Managed DEX reads unknown ANF local " ++ show variable))
  Right (lookup variable state.locals)

private
argument : Administrative_Normal_Form_Variable -> HeapState -> Either String Register
argument (Administrative_Normal_Form_Local_Variable variable) state = local variable state
argument Administrative_Normal_Form_Erased_Variable state = Right (register 15)

private
number_literal : Register -> String -> List Instruction
number_literal destination digits =
  [ NewObject destination number_type
  , TextConstant (register 0) digits
  , call InvokeDirect number_type "<init>" [text_value] VoidValue
      [destination, register 0] Nothing
  ]

private
box_int : Register -> Register -> List Instruction
box_int destination source =
  [ IntToLong (register 2) source
  , call InvokeStatic number_type "valueOf" [LongValue]
      (ReferenceValue number_type) [register 2] (Just destination)
  ]

private
unbox_int : Register -> Register -> List Instruction
unbox_int destination source =
  [call InvokeStatic generated_type "__idricIntExact" [object_value] integer_value [source] (Just destination)]

private
node_get : Register -> Register -> Int -> List Instruction
node_get destination source index =
  [ MoveObject (register 5) source
  , CheckCast (register 5) node_type
  , IntegerConstant (register 6) index
  , call InvokeVirtual node_type "get" [integer_value] object_value
      [register 5, register 6] (Just destination)
  ]

private
node_add : Register -> Register -> Instruction
node_add node value = call InvokeVirtual node_type "add" [object_value]
  (ExistingValue BooleanValue) [node, value] Nothing

private
emit_node : Register -> ManagedValueLayout -> List Register -> List Instruction
emit_node destination layout fields =
  [ NewObject destination node_type
  , call InvokeDirect node_type "<init>" [] VoidValue [destination] Nothing
  , TextConstant (register 0) layout.identity
  , node_add destination (register 0)
  ] ++ map (node_add destination) fields

private
make_node : Register -> ManagedValueLayout -> List Register -> Either String (List Instruction)
make_node destination layout fields = do
  checked <- checked_node_fields layout fields
  Right (emit_node destination layout checked)

private
literal : Register -> Constant -> Either String (List Instruction)
literal destination (Str text) = Right [TextConstant destination text]
literal destination (Ch character) = Right (number_literal destination (show (ord character)))
literal destination (I value) = Right (number_literal destination (show value))
literal destination (I8 value) = Right (number_literal destination (show value))
literal destination (I16 value) = Right (number_literal destination (show value))
literal destination (I32 value) = Right (number_literal destination (show value))
literal destination (I64 value) = Right (number_literal destination (show value))
literal destination (BI value) = Right (number_literal destination (show value))
literal destination (B8 value) = Right (number_literal destination (show value))
literal destination (B16 value) = Right (number_literal destination (show value))
literal destination (B32 value) = Right (number_literal destination (show value))
literal destination (B64 value) = Right (number_literal destination (show value))
literal destination WorldVal = Right [NullReference destination]
literal destination constant = Left ("Managed DEX unsupported literal " ++ show constant)

private
integer_width : PrimType -> Maybe (Int, Bool)
integer_width IntType = Just (64, True)
integer_width Int8Type = Just (8, True)
integer_width Int16Type = Just (16, True)
integer_width Int32Type = Just (32, True)
integer_width Int64Type = Just (64, True)
integer_width Bits8Type = Just (8, False)
integer_width Bits16Type = Just (16, False)
integer_width Bits32Type = Just (32, False)
integer_width Bits64Type = Just (64, False)
integer_width _ = Nothing

-- Restore the source width after arithmetic. BigInteger storage must never
-- silently turn wrapping Int/Bits arithmetic into unbounded arithmetic.
private
restore_width : Register -> PrimType -> Either String (List Instruction)
restore_width destination IntegerType = Right []
restore_width destination CharType = Right []
restore_width destination type = case integer_width type of
  Nothing => Left ("Managed DEX unsupported numeric width " ++ show type)
  Just (width, signed) =>
    if signed
      then Right
        [ IntegerConstant (register 0) (64 - width)
        , call InvokeVirtual number_type "longValue" [] LongValue [destination] (Just (register 2))
        , call InvokeStatic number_type "valueOf" [LongValue] (ReferenceValue number_type)
            [register 2] (Just destination)
        , IntegerConstant (register 0) (64 - width)
        , call InvokeVirtual number_type "shiftLeft" [integer_value] (ReferenceValue number_type)
            [destination, register 0] (Just destination)
        , call InvokeVirtual number_type "longValue" [] LongValue [destination] (Just (register 2))
        , call InvokeStatic number_type "valueOf" [LongValue] (ReferenceValue number_type)
            [register 2] (Just destination)
        , call InvokeVirtual number_type "shiftRight" [integer_value] (ReferenceValue number_type)
            [destination, register 0] (Just destination)
        ]
      else Right
        (number_literal (register 7) "1" ++
        [ IntegerConstant (register 0) width
        , call InvokeVirtual number_type "shiftLeft" [integer_value] (ReferenceValue number_type)
            [register 7, register 0] (Just (register 7))
        , call InvokeVirtual number_type "mod" [ReferenceValue number_type] (ReferenceValue number_type)
            [destination, register 7] (Just destination)
        ])

private
numeric_binary : PrimFn 2 -> Maybe (String, PrimType)
numeric_binary (Add type) = Just ("add", type)
numeric_binary (Sub type) = Just ("subtract", type)
numeric_binary (Mul type) = Just ("multiply", type)
numeric_binary (Div type) = Just ("divide", type)
numeric_binary (Mod type) = Just ("remainder", type)
numeric_binary (BAnd type) = Just ("and", type)
numeric_binary (BOr type) = Just ("or", type)
numeric_binary (BXOr type) = Just ("xor", type)
numeric_binary _ = Nothing

private
comparison : PrimFn 2 -> Maybe (IntegerCondition, PrimType)
comparison (LT type) = Just (LessThanInteger, type)
comparison (LTE type) = Just (LessEqualInteger, type)
comparison (EQ type) = Just (EqualInteger, type)
comparison (GTE type) = Just (GreaterEqualInteger, type)
comparison (GT type) = Just (GreaterThanInteger, type)
comparison _ = Nothing

private
primitive : Register -> PrimFn arity -> Vect arity Register -> HeapState -> Either String HeapState
primitive destination BelieveMe [_, _, value] state = Right (emit [MoveObject destination value] state)
primitive destination Crash [_, message] state = Right (emit
  [NullReference (register 0), MoveObject (register 1) message
  , CheckCast (register 1) (MkTypeReference "Ljava/lang/String;")
  , call InvokeStatic (MkTypeReference "Ljava/util/Objects;") "requireNonNull"
      [object_value, text_value] object_value [register 0, register 1] (Just destination)] state)
primitive destination (Neg type) [value] state = do
  restored <- restore_width destination type
  Right (emit ([MoveObject (register 8) value, CheckCast (register 8) number_type
    , call InvokeVirtual number_type "negate" [] (ReferenceValue number_type) [register 8] (Just destination)] ++ restored) state)
primitive destination StrHead [value] state = Right (emit
  ([MoveObject (register 8) value, CheckCast (register 8) (MkTypeReference "Ljava/lang/String;")
   , IntegerConstant (register 0) 0
   , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "codePointAt" [integer_value]
       integer_value [register 8, register 0] (Just (register 1))] ++ box_int destination (register 1)) state)
primitive destination StrLength [value] state = Right (emit
  ([MoveObject (register 8) value, CheckCast (register 8) (MkTypeReference "Ljava/lang/String;")
   , IntegerConstant (register 0) 0
   , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "length" [] integer_value [register 8] (Just (register 1))
   , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "codePointCount" [integer_value, integer_value]
       integer_value [register 8, register 0, register 1] (Just (register 1))] ++ box_int destination (register 1)) state)
primitive destination StrAppend [left, right] state = Right (emit
  [ MoveObject (register 8) left, CheckCast (register 8) (MkTypeReference "Ljava/lang/String;")
  , MoveObject (register 9) right, CheckCast (register 9) (MkTypeReference "Ljava/lang/String;")
  , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "concat" [text_value] text_value
      [register 8, register 9] (Just destination)
  ] state)
primitive destination (Cast from StringType) [value] state =
  if from == CharType then Right (emit (unbox_int (register 0) value ++
    [call InvokeStatic (MkTypeReference "Ljava/lang/Character;") "toChars" [integer_value]
       (ReferenceValue (MkTypeReference "[C")) [register 0] (Just (register 8))
    , call InvokeStatic (MkTypeReference "Ljava/lang/String;") "valueOf"
       [ReferenceValue (MkTypeReference "[C")] text_value [register 8] (Just destination)]) state)
  else if from == IntegerType || isJust (integer_width from)
    then Right (emit [call InvokeVirtual (MkTypeReference "Ljava/lang/Object;") "toString" [] text_value [value] (Just destination)] state)
    else Left ("Managed DEX unsupported text cast from " ++ show from)
primitive destination (Cast from CharType) [value] state =
  if from == IntegerType || from == CharType || isJust (integer_width from)
    then Right (emit [call InvokeStatic generated_type "__idricChar" [object_value] object_value [value] (Just destination)] state)
    else Left ("Managed DEX unsupported Char cast from " ++ show from)
primitive destination (Cast from to) [value] state = do
  if from == IntegerType || from == CharType || isJust (integer_width from)
    then Right () else Left ("Managed DEX unsupported numeric cast from " ++ show from)
  restored <- restore_width destination to
  Right (emit ([MoveObject destination value, CheckCast destination number_type] ++ restored) state)
primitive destination operation [left, right] state =
  case numeric_binary operation of
    Just (method, type) => do
      restored <- restore_width destination type
      Right (emit
        ([ MoveObject (register 8) left, CheckCast (register 8) number_type
         , MoveObject (register 9) right, CheckCast (register 9) number_type
         , call InvokeVirtual number_type method [ReferenceValue number_type]
             (ReferenceValue number_type) [register 8, register 9] (Just destination)
         ] ++ restored) state)
    Nothing => case comparison operation of
      Just (condition, type) => do
        let supported = if type == StringType
              then case condition of EqualInteger => True; _ => False
              else type == IntegerType || type == CharType || isJust (integer_width type)
        if supported then Right ()
          else Left ("Managed DEX unsupported comparison " ++ show operation)
        let owner = if type == StringType then MkTypeReference "Ljava/lang/String;" else number_type
        let input_type = if type == StringType then text_value else ReferenceValue number_type
        let (yes, after_yes) = fresh_label state
        let (done, after_done) = fresh_label after_yes
        Right (emit
          ([ MoveObject (register 8) left, CheckCast (register 8) owner
           , MoveObject (register 9) right, CheckCast (register 9) owner
           , call InvokeVirtual owner "compareTo" [input_type] integer_value
               [register 8, register 9] (Just (register 0))
           , IntegerConstant (register 1) 0
           , IntegerBranch condition (register 0) (register 1) yes
           ] ++ number_literal destination "0" ++ [Goto done, Mark yes] ++
           number_literal destination "1" ++ [Mark done]) after_done)
      Nothing => Left ("Managed DEX unsupported primitive " ++ show operation)
primitive destination operation registers state =
  Left ("Managed DEX unsupported primitive " ++ show operation)

mutual
  private
  variables : Administrative_Normal_Form -> List Int
  variables (Administrative_Normal_Form_Binding _ variable value body) =
    variable :: (variables value ++ variables body)
  variables (Administrative_Normal_Form_Constructor_Case _ _ branches fallback) =
    concatMap branch_variables branches ++ maybe [] variables fallback
  variables (Administrative_Normal_Form_Constant_Case _ _ branches fallback) =
    concatMap constant_variables branches ++ maybe [] variables fallback
  variables _ = []

  private
  branch_variables : Administrative_Normal_Form_Constructor_Alternative -> List Int
  branch_variables (Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ fields body) = fields ++ variables body

  private
  constant_variables : Administrative_Normal_Form_Constant_Alternative -> List Int
  constant_variables (Make_Administrative_Normal_Form_Constant_Alternative _ body) = variables body

private
number_locals : Int -> List Int -> List (Int, Register)
number_locals next [] = []
number_locals next (variable :: rest) = (variable, register next) :: number_locals (next + 1) rest

private
returns_bound_variable : Int -> Administrative_Normal_Form -> Bool
returns_bound_variable bound (Administrative_Normal_Form_Variable_Expression _
  (Administrative_Normal_Form_Local_Variable variable)) = bound == variable
returns_bound_variable _ _ = False

-- The transfer is a parallel assignment. Every source reference is staged in
-- a separate slot before a parameter is changed, including swaps and cycles.
private
tail_transfer : TailContext -> Name -> List Register -> HeapState -> Either String HeapState
tail_transfer context name inputs state = do
  (selected, arity) <- maybe (Left ("Managed DEX tail target is absent: " ++ show name)) Right
    (lookup name context.targets)
  if arity /= cast (length inputs)
    then Left ("Managed DEX checked tail-call arity mismatch " ++ show name) else Right ()
  let staged = map register [17 .. 16 + cast (length inputs)]
  let save = zipWith MoveObject staged inputs
  let assign = zipWith MoveObject context.common_parameters staged
  let clear = map NullReference (drop (length inputs) context.common_parameters)
  -- No value in a staging slot, old member local or reference scratch alias
  -- survives the tail transfer. Clear only after all new parameters are safe.
  -- The integer selector and new common parameters are deliberately excluded.
  let release = map NullReference context.temporary_references
  Right (emit (save ++ assign ++ clear ++ release ++
    [IntegerConstant (register 14) selected, Goto context.dispatch_label]) state)

mutual
  private
  lower : Bool -> Register -> Administrative_Normal_Form -> HeapState -> Either String HeapState
  lower in_tail destination expression state = case expression of
    Administrative_Normal_Form_Variable_Expression _ variable => do
      source <- argument variable state
      Right (emit [MoveObject destination source] state)
    Administrative_Normal_Form_Erased_Value _ => Right (emit [NullReference destination] state)
    Administrative_Normal_Form_Crash _ message => Right (emit
      [TextConstant (register 8) message, NullReference (register 0)
      , call InvokeStatic (MkTypeReference "Ljava/util/Objects;") "requireNonNull"
          [object_value, text_value] object_value [register 0, register 8] (Just destination)] state)
    Administrative_Normal_Form_Primitive_Value _ constant => do
      instructions <- literal destination constant
      Right (emit instructions state)
    Administrative_Normal_Form_Primitive_Operation _ Nothing operation arguments => do
      inputs <- traverse (\value => argument value state) arguments
      primitive destination operation inputs state
    Administrative_Normal_Form_Binding _ variable value body => do
      if in_tail && returns_bound_variable variable body
        then lower True destination value state
        else do
          target <- local variable state
          after_value <- lower False target value state
          lower in_tail destination body after_value
    Administrative_Normal_Form_Constructor_Value _ name _ _ fields => do
      inputs <- traverse (\value => argument value state) fields
      layout <- checked_constructor_layout (show name) (length fields)
      instructions <- make_node destination layout inputs
      Right (emit instructions state)
    Administrative_Normal_Form_Named_Function_Application _ Nothing name arguments => do
      inputs <- traverse (\value => argument value state) arguments
      (method, arity) <- maybe (Left ("Managed DEX has no checked target " ++ show name)) Right (lookup name state.methods)
      if arity /= cast (length inputs) then Left ("Managed DEX checked call arity mismatch " ++ show name) else Right ()
      case state.tail_context of
        Just context => if in_tail && isJust (lookup name context.targets)
          then tail_transfer context name inputs state
          else Right (emit [call InvokeStatic generated_type method (replicate (length inputs) object_value)
            object_value inputs (Just destination)] state)
        Nothing => Right (emit [call InvokeStatic generated_type method (replicate (length inputs) object_value)
          object_value inputs (Just destination)] state)
    Administrative_Normal_Form_Partial_Application _ name missing captures => do
      inputs <- traverse (\value => argument value state) captures
      (method, arity) <- maybe (Left ("Managed DEX has no closure target " ++ show name)) Right (lookup name state.methods)
      layout <- checked_closure_layout method arity (length inputs) missing
      instructions <- make_node destination layout inputs
      Right (emit instructions state)
    Administrative_Normal_Form_Closure_Application _ Nothing closure value => do
      function <- argument closure state
      input <- argument value state
      Right (emit [call InvokeStatic generated_type "__idricApply" [object_value, object_value]
        object_value [function, input] (Just destination)] state)
    Administrative_Normal_Form_Constructor_Case _ scrutinee alternatives fallback => do
      source <- argument scrutinee state
      let (done, after_label) = fresh_label state
      after <- lower_branches in_tail destination source done alternatives fallback after_label
      Right (emit [Mark done] after)
    Administrative_Normal_Form_Constant_Case _ scrutinee alternatives fallback => do
      source <- argument scrutinee state
      let (done, after_label) = fresh_label state
      after <- lower_constants in_tail destination source done alternatives fallback after_label
      Right (emit [Mark done] after)
    _ => Left ("Managed DEX unsupported checked expression " ++ show expression)

  private
  lower_fields : Register -> List Int -> List Int -> HeapState -> Either String HeapState
  lower_fields source [] [] state = Right state
  lower_fields source (index :: indices) (field :: rest) state = do
    destination <- local field state
    lower_fields source indices rest (emit (node_get destination source index) state)
  lower_fields _ _ _ _ = Left "Managed DEX constructor projection disagrees with its layout"

  private
  lower_branches : Bool -> Register -> Register -> Label ->
    List Administrative_Normal_Form_Constructor_Alternative -> Maybe Administrative_Normal_Form ->
    HeapState -> Either String HeapState
  lower_branches in_tail destination source done [] (Just fallback) state = lower in_tail destination fallback state
  lower_branches in_tail destination source done [] Nothing state =
    Right (emit [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just destination)] state)
  lower_branches in_tail destination source done
    (Make_Administrative_Normal_Form_Constructor_Alternative name _ _ fields body :: rest) fallback state = do
      layout <- checked_constructor_layout (show name) (length fields)
      let (next, after_label) = fresh_label state
      let (shape_matches, after_shape_label) = fresh_label after_label
      let tested = emit (node_get (register 8) source managed_tag_slot ++
            [CheckCast (register 8) (MkTypeReference "Ljava/lang/String;")
            , TextConstant (register 9) layout.identity, TextEqual (register 0) (register 8) (register 9)
            , IntegerConstant (register 1) 0, IntegerBranch EqualInteger (register 0) (register 1) next
            , MoveObject (register 5) source, CheckCast (register 5) node_type
            , call InvokeVirtual node_type "size" [] integer_value [register 5] (Just (register 0))
            , IntegerConstant (register 1) (managed_node_slots layout)
            , IntegerBranch EqualInteger (register 0) (register 1) shape_matches
            , call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just destination)
            , Mark shape_matches]) after_shape_label
      projected <- lower_fields source (managed_field_slots layout) fields tested
      selected <- lower in_tail destination body projected
      lower_branches in_tail destination source done rest fallback (emit [Goto done, Mark next] selected)

  private
  lower_constants : Bool -> Register -> Register -> Label ->
    List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form ->
    HeapState -> Either String HeapState
  lower_constants in_tail destination source done [] (Just fallback) state = lower in_tail destination fallback state
  lower_constants in_tail destination source done [] Nothing state = Right (emit
    [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just destination)] state)
  lower_constants in_tail destination source done
    (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest) fallback state = do
      let (next, after_label) = fresh_label state
      value <- literal (register 8) constant
      let tested = emit (value ++
            [call InvokeVirtual (MkTypeReference "Ljava/lang/Object;") "equals" [object_value]
              (ExistingValue BooleanValue) [source, register 8] (Just (register 0))
            , IntegerConstant (register 1) 0, IntegerBranch EqualInteger (register 0) (register 1) next]) after_label
      selected <- lower in_tail destination body tested
      lower_constants in_tail destination source done rest fallback (emit [Goto done, Mark next] selected)

public export
heap_method : List (Name, (String, Int)) -> Name -> String ->
  Administrative_Normal_Form_Definition -> Either String MethodPlan
heap_method methods name method (Make_Administrative_Normal_Form_Function arguments body) = do
  let locals = filter (\variable => not (elem variable arguments)) (nub (variables body))
  let parameter_start = 17 + cast (length locals)
  let mapping = number_locals 17 locals ++ number_locals parameter_start arguments
  result <- lower True (register 16) body (MkHeapState methods mapping 0 [NullReference (register 15)] Nothing)
  Right (MkMethodPlan (show name) method (cast (length arguments))
    (replicate (length arguments) object_value) object_value
    (parameter_start + cast (length arguments)) (result.code ++ [ReturnObject (register 16)]))
heap_method methods name method definition = Left ("Managed DEX expected checked function " ++ show name)

mutual
  private
  tail_targets : Administrative_Normal_Form -> List Name
  tail_targets (Administrative_Normal_Form_Named_Function_Application _ Nothing name _) = [name]
  tail_targets (Administrative_Normal_Form_Binding _ variable value body) =
    if returns_bound_variable variable body then tail_targets value else tail_targets body
  tail_targets (Administrative_Normal_Form_Constructor_Case _ _ alternatives fallback) =
    concatMap constructor_tail_targets alternatives ++ maybe [] tail_targets fallback
  tail_targets (Administrative_Normal_Form_Constant_Case _ _ alternatives fallback) =
    concatMap constant_tail_targets alternatives ++ maybe [] tail_targets fallback
  tail_targets _ = []

  private
  constructor_tail_targets : Administrative_Normal_Form_Constructor_Alternative -> List Name
  constructor_tail_targets (Make_Administrative_Normal_Form_Constructor_Alternative _ _ _ _ body) = tail_targets body

  private
  constant_tail_targets : Administrative_Normal_Form_Constant_Alternative -> List Name
  constant_tail_targets (Make_Administrative_Normal_Form_Constant_Alternative _ body) = tail_targets body

private
ordinary_body : Administrative_Normal_Form_Definition -> Maybe (List Int, Administrative_Normal_Form)
ordinary_body (Make_Administrative_Normal_Form_Function arguments body) = Just (arguments, body)
ordinary_body _ = Nothing

private
tail_graph : List (Name, Administrative_Normal_Form_Definition) -> List (Name, List Name)
tail_graph definitions = mapMaybe edge definitions
  where
    edge : (Name, Administrative_Normal_Form_Definition) -> Maybe (Name, List Name)
    edge (name, definition) = case ordinary_body definition of
      Just (_, body) => Just (name, nub (tail_targets body))
      Nothing => Nothing

private
tail_reachable : List (Name, List Name) -> Name -> List Name
tail_reachable graph start = visit (length graph + 1) [] [start]
  where
    visit : Nat -> List Name -> List Name -> List Name
    visit Z seen pending = seen
    visit (S fuel) seen pending =
      let fresh = filter (\name => not (elem name seen)) (nub pending)
          visited = seen ++ fresh
          following = concatMap (\name => maybe [] id (lookup name graph)) fresh
       in if null fresh then visited else visit fuel visited following

private
tail_groups : List (Name, Administrative_Normal_Form_Definition) -> List (List Name)
tail_groups definitions = collect [] (map fst graph)
  where
    graph : List (Name, List Name)
    graph = tail_graph definitions

    collect : List Name -> List Name -> List (List Name)
    collect covered [] = []
    collect covered (name :: rest) =
      if elem name covered then collect covered rest else
        let reachable = tail_reachable graph name
            members = filter (\other => elem other reachable && elem name (tail_reachable graph other)) (map fst graph)
            cyclic = length members > 1 || elem name (maybe [] id (lookup name graph))
         in if cyclic then members :: collect (members ++ covered) rest else collect covered rest

private
number_tail_targets : Int -> List Name -> List (Name, (String, Int)) -> Either String (List (Name, (Int, Int)))
number_tail_targets next [] methods = Right []
number_tail_targets next (name :: rest) methods = do
  (_, arity) <- maybe (Left ("Managed DEX tail ABI is absent: " ++ show name)) Right (lookup name methods)
  following <- number_tail_targets (next + 1) rest methods
  Right ((name, (next, arity)) :: following)

private
group_wrapper : String -> Int -> Int -> List (Name, (String, Int)) -> Name -> Either String MethodPlan
group_wrapper group_name selector maximum_arity methods name = do
  (method, arity) <- maybe (Left ("Managed DEX tail wrapper ABI is absent: " ++ show name)) Right (lookup name methods)
  let entry_parameters = map register [17 .. 16 + arity]
  let padding = replicate (cast (maximum_arity - arity)) (register 15)
  Right (MkMethodPlan (show name ++ " tail-group entry") method arity
    (replicate (cast arity) object_value) object_value (17 + arity)
    [ NullReference (register 15), IntegerConstant (register 0) selector
    , call InvokeStatic generated_type group_name
        (integer_value :: replicate (cast maximum_arity) object_value) object_value
        (register 0 :: entry_parameters ++ padding) (Just (register 16))
    , ReturnObject (register 16)])

private
tail_group_methods : List (Name, (String, Int)) -> List (Name, Administrative_Normal_Form_Definition) ->
  List Name -> Either String (List MethodPlan)
tail_group_methods methods definitions [] = Right []
tail_group_methods methods definitions names@(first :: rest) = do
  (first_method, _) <- maybe (Left "Managed DEX empty tail ABI") Right (lookup first methods)
  targets <- number_tail_targets 0 names methods
  let maximum_arity = foldl max 0 (map (snd . snd) targets)
  if maximum_arity > 254 then Left "Managed DEX tail group exceeds 254 object arguments plus its selector" else Right ()
  bodies <- traverse body_for names
  let local_lists = map (\(arguments, body) => filter (\variable => not (elem variable arguments)) (nub (variables body))) bodies
  let maximum_locals = foldl max 0 (map length local_lists)
  let locals_start = 17 + maximum_arity
  let parameter_start = locals_start + cast maximum_locals
  let parameter_registers = map register [parameter_start + 1 .. parameter_start + maximum_arity]
  let group_name = "__idricTailGroup_" ++ first_method
  let reference_scratch = map register [0, 1, 5, 7, 8, 9, 16]
  let temporary_references = reference_scratch ++ map register [17 .. parameter_start - 1]
  let context = MkTailContext targets parameter_registers temporary_references (MkLabel 0)
  let dispatch = concatMap (\(_, (selected, _)) =>
        [IntegerConstant (register 0) selected,
         IntegerBranch EqualInteger (register 14) (register 0) (MkLabel (selected + 1))]) targets
  let initial = MkHeapState methods [] (cast (length names) + 1)
        ([NullReference (register 15), Move (register 14) (register parameter_start), Mark (MkLabel 0)] ++ dispatch ++
         [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just (register 16)), ReturnObject (register 16)]) (Just context)
  lowered <- lower_members 0 initial (zip bodies local_lists)
  wrappers <- traverse (\(name, (selected, _)) => group_wrapper group_name selected maximum_arity methods name) targets
  let dispatcher = MkMethodPlan ("checked managed tail group " ++ show first) group_name (maximum_arity + 1)
        (integer_value :: replicate (cast maximum_arity) object_value) object_value
        (parameter_start + maximum_arity + 1) lowered.code
  Right (dispatcher :: wrappers)
  where
    body_for : Name -> Either String (List Int, Administrative_Normal_Form)
    body_for name = do
      definition <- maybe (Left ("Managed DEX tail definition is absent: " ++ show name)) Right (lookup name definitions)
      maybe (Left ("Managed DEX tail definition is not ordinary: " ++ show name)) Right (ordinary_body definition)

    lower_members : Int -> HeapState -> List ((List Int, Administrative_Normal_Form), List Int) -> Either String HeapState
    lower_members next state [] = Right state
    lower_members next state (((arguments, body), locals) :: rest) = do
      context <- maybe (Left "Managed DEX tail group lost its context") Right state.tail_context
      let local_start = 17 + cast (length context.common_parameters)
      let mapping = number_locals local_start locals ++ zip arguments context.common_parameters
      result <- lower True (register 16) body
        ({ locals := mapping } (emit [Mark (MkLabel (next + 1))] state))
      lower_members (next + 1) (emit [ReturnObject (register 16)] result) rest

||| Lower direct tail-call cycles together. Original named methods remain ABI
||| wrappers, so ordinary callers and closures do not share invocation state.
public export
heap_tail_methods : List (Name, (String, Int)) -> List (Name, Administrative_Normal_Form_Definition) ->
  Either String (List Name, List MethodPlan)
heap_tail_methods methods definitions = do
  let groups = tail_groups definitions
  lowered <- traverse (tail_group_methods methods definitions) groups
  Right (concat groups, concat lowered)

-- Applying a closure copies its captured fields before appending the argument.
-- Incomplete application returns that copy; complete application invokes the
-- checked method. The dispatch table is drawn solely from the checked graph.
public export
heap_apply : List (Name, (String, Int)) -> MethodPlan
heap_apply methods =
  let maximum_arity = foldl max 0 (map (snd . snd) methods)
      parameter_start = 17 + maximum_arity
   in MkMethodPlan "checked managed closure application" "__idricApply"
  2 [object_value, object_value] object_value (parameter_start + 2)
  ([ MoveObject (register 8) (register parameter_start), CheckCast (register 8) node_type
   , NewObject (register 16) node_type
   , call InvokeDirect node_type "<init>" [ReferenceValue (MkTypeReference "Ljava/util/Collection;")]
       VoidValue [register 16, register 8] Nothing
   , node_add (register 16) (register (parameter_start + 1))
   ] ++ node_get (register 8) (register 16) 0 ++
   dispatch 0 (filter (\(_, (_, arity)) => arity > 0) methods) ++
   [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just (register 16)), ReturnObject (register 16)])
  where
    dispatch : Int -> List (Name, (String, Int)) -> List Instruction
    dispatch label [] = []
    dispatch label ((_, (method, arity)) :: rest) =
      [ CheckCast (register 8) (MkTypeReference "Ljava/lang/String;")
      , TextConstant (register 9) method
      , TextEqual (register 0) (register 8) (register 9)
      , IntegerConstant (register 1) 0
      , IntegerBranch EqualInteger (register 0) (register 1) (MkLabel label)
      , call InvokeVirtual node_type "size" [] integer_value [register 16] (Just (register 0))
      , IntegerConstant (register 1) (arity + 1)
      , IntegerBranch LessEqualInteger (register 0) (register 1) (MkLabel (label + 1))
      , call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just (register 16))
      , ReturnObject (register 16)
      , Mark (MkLabel (label + 1))
      , IntegerBranch EqualInteger (register 0) (register 1) (MkLabel (label + 2))
      , ReturnObject (register 16)
      , Mark (MkLabel (label + 2))
      ] ++ concatMap (\index => node_get (register (17 + index)) (register 16) (index + 1)) [0..arity-1] ++
      [ call InvokeStatic generated_type method (replicate (cast arity) object_value) object_value
          (map (\index => register (17 + index)) [0..arity-1]) (Just (register 16))
      , ReturnObject (register 16), Mark (MkLabel label)
      ] ++ dispatch (label + 3) rest

public export
heap_match_failure : MethodPlan
heap_match_failure = MkMethodPlan "checked nonexhaustive managed match" "__idricMatchFailure"
  0 [] object_value 2
  [ NullReference (register 0), TextConstant (register 1) "Nonexhaustive checked Idriç match"
  , call InvokeStatic (MkTypeReference "Ljava/util/Objects;") "requireNonNull"
      [object_value, text_value] object_value [register 0, register 1] (Just (register 0))
  , ReturnObject (register 0)
  ]

private
cf_equal : CFType -> CFType -> Bool
cf_equal CFWorld CFWorld = True
cf_equal CFInt CFInt = True
cf_equal CFString CFString = True
cf_equal CFChar CFChar = True
cf_equal CFUnit CFUnit = True
cf_equal (CFIORes left) (CFIORes right) = cf_equal left right
cf_equal (CFUser left [CFChar]) (CFUser right [CFChar]) = left == right
cf_equal _ _ = False

private
cf_arguments_equal : List CFType -> List CFType -> Bool
cf_arguments_equal [] [] = True
cf_arguments_equal (left :: more) (right :: rest) = cf_equal left right && cf_arguments_equal more rest
cf_arguments_equal _ _ = False

private
character_list : CFType -> Bool
character_list (CFUser name [CFChar]) = show name == "Prelude.Basics.List"
character_list _ = False

private
unpack_text : Register -> List Instruction
unpack_text input =
  [MoveObject (register 18) input, CheckCast (register 18) (MkTypeReference "Ljava/lang/String;")
  , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "length" [] integer_value [register 18] (Just (register 10))] ++
  emit_node (register 16) (MakeManagedValueLayout ConstructorNode "_builtin.NIL" 0 0 0) [] ++
  [Mark (MkLabel 0), IntegerConstant (register 0) 0
  , IntegerBranch EqualInteger (register 10) (register 0) (MkLabel 1)
  , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "codePointBefore" [integer_value]
      integer_value [register 18, register 10] (Just (register 11))
  , call InvokeStatic (MkTypeReference "Ljava/lang/Character;") "charCount" [integer_value]
      integer_value [register 11] (Just (register 12))
  , IntegerBinary SubtractInteger (register 10) (register 10) (register 12)
  ] ++ box_int (register 17) (register 11) ++ [MoveObject (register 9) (register 16)] ++
  emit_node (register 16) (MakeManagedValueLayout ConstructorNode "_builtin.CONS" 2 0 0) [register 17, register 9] ++
  [Goto (MkLabel 0), Mark (MkLabel 1)]

private
pack_text : Register -> List Instruction
pack_text input =
  [ MoveObject (register 18) input
  , NewObject (register 17) (MkTypeReference "Ljava/lang/StringBuilder;")
  , call InvokeDirect (MkTypeReference "Ljava/lang/StringBuilder;") "<init>" [] VoidValue [register 17] Nothing
  , Mark (MkLabel 0)] ++ node_get (register 8) (register 18) 0 ++
  [CheckCast (register 8) (MkTypeReference "Ljava/lang/String;")
  , TextConstant (register 9) "_builtin.NIL", TextEqual (register 0) (register 8) (register 9)
  , IntegerConstant (register 1) 0, IntegerBranch NotEqualInteger (register 0) (register 1) (MkLabel 1)] ++
  node_get (register 16) (register 18) 1 ++ unbox_int (register 0) (register 16) ++
  [call InvokeVirtual (MkTypeReference "Ljava/lang/StringBuilder;") "appendCodePoint" [integer_value]
    (ReferenceValue (MkTypeReference "Ljava/lang/StringBuilder;")) [register 17, register 0] Nothing] ++
  node_get (register 18) (register 18) 2 ++
  [Goto (MkLabel 0), Mark (MkLabel 1)
  , call InvokeVirtual (MkTypeReference "Ljava/lang/StringBuilder;") "toString" [] text_value [register 17] (Just (register 16))]

-- These are compiler runtime services, admitted only when the checked foreign
-- signature and an exact maintained calling convention both agree. An
-- unrelated user function with the same printed name does not acquire an ABI.
public export
heap_foreign : String -> Administrative_Normal_Form_Definition -> Either String MethodPlan
heap_foreign method (Make_Administrative_Normal_Form_Foreign_Function conventions arguments result) = do
  let count : Int = cast (length arguments)
  let start : Int = 20
  let parameter : Int -> Register = \index => register (start + index)
  instructions <-
    if elem "C:idris2_getArgCount, libidris2_support, idris_support.h" conventions &&
       cf_arguments_equal arguments [CFWorld] && cf_equal result (CFIORes CFInt)
      then Right
        [call InvokeStatic generated_type "__idricArgCount" [] LongValue [] (Just (register 2))
        , call InvokeStatic number_type "valueOf" [LongValue] (ReferenceValue number_type)
            [register 2] (Just (register 16))]
    else if elem "C:idris2_getArg, libidris2_support, idris_support.h" conventions &&
            cf_arguments_equal arguments [CFInt, CFWorld] && cf_equal result (CFIORes CFString)
      then Right
        [call InvokeStatic generated_type "__idricLongExact" [object_value] LongValue [parameter 0] (Just (register 2))
        , call InvokeStatic generated_type "__idricArg" [LongValue] text_value [register 2] (Just (register 16))]
    else if elem "C:idris2_putStr, libidris2_support, idris_support.h" conventions &&
            cf_arguments_equal arguments [CFString, CFWorld] && cf_equal result (CFIORes CFUnit)
      then Right
        [StaticGetObject (register 8)
          (MkFieldReference (MkTypeReference "Ljava/lang/System;") "out"
            (ReferenceValue (MkTypeReference "Ljava/io/PrintStream;")))
        , MoveObject (register 9) (parameter 0), CheckCast (register 9) (MkTypeReference "Ljava/lang/String;")
        , call InvokeVirtual (MkTypeReference "Ljava/io/PrintStream;") "print" [text_value]
            VoidValue [register 8, register 9] Nothing
        , NullReference (register 16)]
    else if elem "C:exit, libc 6" conventions &&
            cf_arguments_equal arguments [CFInt, CFWorld] && cf_equal result (CFIORes CFUnit)
      then Right (unbox_int (register 0) (parameter 0) ++
        [call InvokeStatic (MkTypeReference "Ljava/lang/System;") "exit" [integer_value]
          VoidValue [register 0] Nothing, NullReference (register 16)])
    else if elem "scheme:string-unpack" conventions && cf_arguments_equal arguments [CFString] && character_list result
      then Right (unpack_text (parameter 0))
    else if elem "scheme:string-pack" conventions && cf_equal result CFString &&
            (case arguments of [list] => character_list list; _ => False)
      then Right (pack_text (parameter 0))
    else Left ("Managed DEX unsupported checked foreign declaration: " ++ show conventions)
  Right (MkMethodPlan "checked managed foreign service" method count
    (replicate (length arguments) object_value) object_value (start + count)
    (instructions ++ [ReturnObject (register 16)]))
heap_foreign method definition = Left "Managed DEX expected a checked foreign declaration"

public export
heap_entry : String -> String -> MethodPlan
heap_entry exported checked = MkMethodPlan "checked managed IO entrypoint" exported
  0 [] VoidValue 2
  [ NullReference (register 0)
  , call InvokeStatic generated_type checked [object_value] object_value [register 0] (Just (register 1))
  , ReturnVoid
  ]

public export
record JNIService where
  constructor MkJNIService
  convention : String
  method_name : String
  argument_types : List FrameworkValueType
  result_type : FrameworkValueType
  boundary_contract : NativeBoundaryContract

public export
native_contract : JNIService -> NativeBoundaryContract
native_contract service = service.boundary_contract

private
check_native_string : NativeBoundaryContract -> Register -> String -> List Instruction
check_native_string LegacyUnqualifiedNativeBoundary value description = []
check_native_string SynchronousBorrowedNonNullNativeBoundary value description =
  [ TextConstant (register 1) description
  , call InvokeStatic (MkTypeReference "Ljava/util/Objects;") "requireNonNull"
      [object_value, text_value] object_value [value, register 1] (Just value)
  , CheckCast value (MkTypeReference "Ljava/lang/String;")
  ]

private
native_argument : NativeBoundaryContract -> CFType -> FrameworkValueType -> Register -> Register ->
  Either String (List Instruction)
native_argument contract CFString (ExistingValue TextValue) source destination = Right
  ([MoveObject destination source, CheckCast destination (MkTypeReference "Ljava/lang/String;")] ++
   check_native_string contract destination "JNI contract rejects null String argument")
native_argument contract CFInt (ExistingValue IntegerValue) source destination = Right (unbox_int destination source)
native_argument contract CFInt LongValue source destination = Right
  [call InvokeStatic generated_type "__idricLongExact" [object_value] LongValue [source] (Just destination)]
native_argument contract source_type target_type source destination =
  Left ("Managed JNI argument cannot cross from " ++ show source_type ++ " to " ++ show target_type)

private
native_arguments : NativeBoundaryContract -> List CFType -> List FrameworkValueType -> Int -> Int ->
  Either String (List Instruction, List Register)
native_arguments contract [] [] source target = Right ([], [])
native_arguments contract (source_type :: sources) (target_type :: targets) source target = do
  current <- native_argument contract source_type target_type (register source) (register target)
  let width : Int = if target_type == LongValue then 2 else 1
  (more, registers) <- native_arguments contract sources targets (source + 1) (target + width)
  Right (current ++ more, register target :: registers)
native_arguments _ _ _ _ _ = Left "Managed JNI argument count differs from checked source declaration"

public export
heap_foreign_linked : List JNIService -> String -> Administrative_Normal_Form_Definition -> Either String MethodPlan
heap_foreign_linked services method definition@(Make_Administrative_Normal_Form_Foreign_Function conventions arguments result) =
  case filter (\service => elem service.convention conventions) services of
    [] => heap_foreign method definition
    [service] => do
      ordinary <- case reverse arguments of
        CFWorld :: rest => Right (reverse rest)
        _ => Left "Managed JNI requires checked PrimIO with a trailing World token"
      source_result <- the (Either String CFType) $ case result of
        CFIORes value => Right value
        _ => Left "Managed JNI requires a checked PrimIO result"
      let native_words : Int = sum (map (\type => if type == LongValue then 2 else 1) service.argument_types)
      let parameter_start : Int = max 64 (24 + native_words)
      (prepared, registers) <- native_arguments (native_contract service) ordinary service.argument_types parameter_start 24
      completed <- the (Either String (List Instruction)) $ case (source_result, service.result_type) of
        (CFInt, ExistingValue IntegerValue) => Right (box_int (register 16) (register 0))
        (CFInt, LongValue) => Right
          [call InvokeStatic number_type "valueOf" [LongValue] (ReferenceValue number_type)
            [register 0] (Just (register 16))]
        (CFString, ExistingValue TextValue) => Right
          ([MoveObject (register 16) (register 0)] ++
           check_native_string (native_contract service) (register 16) "JNI contract rejects null String result")
        (CFUnit, VoidValue) => Right [NullReference (register 16)]
        _ => Left "Managed JNI result differs from checked source declaration"
      let invoke = call InvokeStatic generated_type service.method_name service.argument_types service.result_type
            registers (if service.result_type == VoidValue then Nothing else Just (register 0))
      Right (MkMethodPlan (native_contract_description (native_contract service)) method (cast (length arguments))
        (replicate (length arguments) object_value) object_value (parameter_start + cast (length arguments))
        (prepared ++ [invoke] ++ completed ++ [ReturnObject (register 16)]))
    _ => Left "Multiple JNI bindings select the same checked foreign declaration"
heap_foreign_linked services method definition = heap_foreign method definition

public export
heap_native : JNIService -> MethodPlan
heap_native service = MkBoundMethodPlan service.convention service.method_name
  (cast (length service.argument_types)) service.argument_types service.result_type 0 [] NativeStaticMethod

public export
heap_native_loader : String -> MethodPlan
heap_native_loader property = MkBoundMethodPlan "explicit JNI library path property" "<clinit>"
  0 [] VoidValue 1
  [TextConstant (register 0) property
  , call InvokeStatic (MkTypeReference "Ljava/lang/System;") "getProperty" [text_value]
      text_value [register 0] (Just (register 0))
  , call InvokeStatic (MkTypeReference "Ljava/lang/System;") "load" [text_value]
      VoidValue [register 0] Nothing
  , ReturnVoid] ClassInitializerMethod

-- BigInteger's *ValueExact methods are API 31. The supported ART lane is API
-- 29: bitLength plus the API 1 conversions preserves the same signed bounds.
-- bitLength excludes the sign bit, including for the minimum negative value.
public export
heap_exact_number : Bool -> MethodPlan
heap_exact_number wide = MkMethodPlan "checked signed managed integer narrowing"
  (if wide then "__idricLongExact" else "__idricIntExact")
  1 [object_value] (if wide then LongValue else integer_value) 6
  [CheckCast (register 5) number_type
  , call InvokeVirtual number_type "bitLength" [] integer_value [register 5] (Just (register 0))
  , IntegerConstant (register 1) (if wide then 63 else 31)
  , IntegerBranch LessEqualInteger (register 0) (register 1) (MkLabel 0)
  , NewObject (register 2) (MkTypeReference "Ljava/lang/ArithmeticException;")
  , TextConstant (register 3) "Idriç integer exceeds the signed platform boundary"
  , call InvokeDirect (MkTypeReference "Ljava/lang/ArithmeticException;") "<init>" [text_value]
      VoidValue [register 2, register 3] Nothing
  , ThrowObject (register 2)
  , Mark (MkLabel 0)
  , call InvokeVirtual number_type (if wide then "longValue" else "intValue") []
      (if wide then LongValue else integer_value) [register 5] (Just (register 0))
  , if wide then ReturnWide (register 0) else ReturnInteger (register 0)]

-- The pinned frontend maps invalid Unicode scalars to NUL. The surrogate
-- interval and maximum scalar below come from that checked primitive contract.
public export
heap_character : MethodPlan
heap_character = MkMethodPlan "checked numeric Unicode scalar conversion" "__idricChar"
  1 [object_value] object_value 6
  ([CheckCast (register 5) number_type
   , call InvokeVirtual number_type "bitLength" [] integer_value [register 5] (Just (register 0))
   , IntegerConstant (register 1) 21
   , IntegerBranch GreaterThanInteger (register 0) (register 1) (MkLabel 1)
   , call InvokeVirtual number_type "intValue" [] integer_value [register 5] (Just (register 0))
   , IntegerConstant (register 1) 0
   , IntegerBranch LessThanInteger (register 0) (register 1) (MkLabel 1)
   , IntegerConstant (register 1) 0x10ffff
   , IntegerBranch GreaterThanInteger (register 0) (register 1) (MkLabel 1)
   , IntegerConstant (register 1) 0xd800
   , IntegerBranch LessThanInteger (register 0) (register 1) (MkLabel 0)
   , IntegerConstant (register 1) 0xdfff
   , IntegerBranch LessEqualInteger (register 0) (register 1) (MkLabel 1)
   , Mark (MkLabel 0), ReturnObject (register 5), Mark (MkLabel 1)
   ] ++ number_literal (register 2) "0" ++ [ReturnObject (register 2)])
