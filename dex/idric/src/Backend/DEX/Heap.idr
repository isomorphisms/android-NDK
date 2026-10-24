module Backend.DEX.Heap

import Backend.DEX.IR
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
node_type = MkTypeReference "Ljava/util/ArrayList;"

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
record HeapState where
  constructor MkHeapState
  methods : List (Name, (String, Int))
  locals : List (Int, Register)
  next_label : Int
  code : List Instruction

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
  [ MoveObject (register 4) source
  , CheckCast (register 4) number_type
  , call InvokeVirtual number_type "intValueExact" [] integer_value
      [register 4] (Just destination)
  ]

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
make_node : Register -> String -> List Register -> List Instruction
make_node destination tag fields =
  [ NewObject destination node_type
  , call InvokeDirect node_type "<init>" [] VoidValue [destination] Nothing
  , TextConstant (register 0) tag
  , node_add destination (register 0)
  ] ++ map (node_add destination) fields

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
primitive destination (Cast from to) [value] state = do
  if from == IntegerType || from == CharType || isJust (integer_width from)
    then Right () else Left ("Managed DEX unsupported numeric cast from " ++ show from)
  if to == CharType && from /= CharType
    then Left "Managed DEX numeric-to-Char conversion is not qualified"
    else Right ()
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

mutual
  private
  lower : Register -> Administrative_Normal_Form -> HeapState -> Either String HeapState
  lower destination expression state = case expression of
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
      target <- local variable state
      after_value <- lower target value state
      lower destination body after_value
    Administrative_Normal_Form_Constructor_Value _ name _ _ fields => do
      inputs <- traverse (\value => argument value state) fields
      Right (emit (make_node destination (show name) inputs) state)
    Administrative_Normal_Form_Named_Function_Application _ Nothing name arguments => do
      inputs <- traverse (\value => argument value state) arguments
      (method, arity) <- maybe (Left ("Managed DEX has no checked target " ++ show name)) Right (lookup name state.methods)
      if arity /= cast (length inputs) then Left ("Managed DEX checked call arity mismatch " ++ show name) else Right ()
      Right (emit [call InvokeStatic generated_type method (replicate (length inputs) object_value)
        object_value inputs (Just destination)] state)
    Administrative_Normal_Form_Partial_Application _ name missing captures => do
      inputs <- traverse (\value => argument value state) captures
      (method, arity) <- maybe (Left ("Managed DEX has no closure target " ++ show name)) Right (lookup name state.methods)
      if cast (length inputs + missing) /= arity then Left ("Managed DEX closure arity mismatch " ++ show name) else Right ()
      Right (emit (make_node destination method inputs) state)
    Administrative_Normal_Form_Closure_Application _ Nothing closure value => do
      function <- argument closure state
      input <- argument value state
      Right (emit [call InvokeStatic generated_type "__idricApply" [object_value, object_value]
        object_value [function, input] (Just destination)] state)
    Administrative_Normal_Form_Constructor_Case _ scrutinee alternatives fallback => do
      source <- argument scrutinee state
      let (done, after_label) = fresh_label state
      after <- lower_branches destination source done alternatives fallback after_label
      Right (emit [Mark done] after)
    Administrative_Normal_Form_Constant_Case _ scrutinee alternatives fallback => do
      source <- argument scrutinee state
      let (done, after_label) = fresh_label state
      after <- lower_constants destination source done alternatives fallback after_label
      Right (emit [Mark done] after)
    _ => Left ("Managed DEX unsupported checked expression " ++ show expression)

  private
  lower_fields : Register -> Int -> List Int -> HeapState -> Either String HeapState
  lower_fields source index [] state = Right state
  lower_fields source index (field :: rest) state = do
    destination <- local field state
    lower_fields source (index + 1) rest (emit (node_get destination source index) state)

  private
  lower_branches : Register -> Register -> Label ->
    List Administrative_Normal_Form_Constructor_Alternative -> Maybe Administrative_Normal_Form ->
    HeapState -> Either String HeapState
  lower_branches destination source done [] (Just fallback) state = lower destination fallback state
  lower_branches destination source done [] Nothing state =
    Right (emit [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just destination)] state)
  lower_branches destination source done
    (Make_Administrative_Normal_Form_Constructor_Alternative name _ _ fields body :: rest) fallback state = do
      let (next, after_label) = fresh_label state
      let tested = emit (node_get (register 8) source 0 ++
            [TextConstant (register 9) (show name), TextEqual (register 0) (register 8) (register 9)
            , IntegerConstant (register 1) 0, IntegerBranch EqualInteger (register 0) (register 1) next]) after_label
      projected <- lower_fields source 1 fields tested
      selected <- lower destination body projected
      lower_branches destination source done rest fallback (emit [Goto done, Mark next] selected)

  private
  lower_constants : Register -> Register -> Label ->
    List Administrative_Normal_Form_Constant_Alternative -> Maybe Administrative_Normal_Form ->
    HeapState -> Either String HeapState
  lower_constants destination source done [] (Just fallback) state = lower destination fallback state
  lower_constants destination source done [] Nothing state = Right (emit
    [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just destination)] state)
  lower_constants destination source done
    (Make_Administrative_Normal_Form_Constant_Alternative constant body :: rest) fallback state = do
      let (next, after_label) = fresh_label state
      value <- literal (register 8) constant
      let tested = emit (value ++
            [call InvokeVirtual (MkTypeReference "Ljava/lang/Object;") "equals" [object_value]
              (ExistingValue BooleanValue) [source, register 8] (Just (register 0))
            , IntegerConstant (register 1) 0, IntegerBranch EqualInteger (register 0) (register 1) next]) after_label
      selected <- lower destination body tested
      lower_constants destination source done rest fallback (emit [Goto done, Mark next] selected)

public export
heap_method : List (Name, (String, Int)) -> Name -> String ->
  Administrative_Normal_Form_Definition -> Either String MethodPlan
heap_method methods name method (Make_Administrative_Normal_Form_Function arguments body) = do
  let locals = filter (\variable => not (elem variable arguments)) (nub (variables body))
  let parameter_start = 17 + cast (length locals)
  let mapping = number_locals 17 locals ++ number_locals parameter_start arguments
  result <- lower (register 16) body (MkHeapState methods mapping 0 [NullReference (register 15)])
  Right (MkMethodPlan (show name) method (cast (length arguments))
    (replicate (length arguments) object_value) object_value
    (parameter_start + cast (length arguments)) (result.code ++ [ReturnObject (register 16)]))
heap_method methods name method definition = Left ("Managed DEX expected checked function " ++ show name)

-- Applying a closure copies its captured fields before appending the argument.
-- Incomplete application returns that copy; complete application invokes the
-- checked method. The dispatch table is drawn solely from the checked graph.
public export
heap_apply : List (Name, (String, Int)) -> MethodPlan
heap_apply methods = MkMethodPlan "checked managed closure application" "__idricApply"
  2 [object_value, object_value] object_value 32
  ([ MoveObject (register 8) (register 30), CheckCast (register 8) node_type
   , NewObject (register 16) node_type
   , call InvokeDirect node_type "<init>" [ReferenceValue (MkTypeReference "Ljava/util/Collection;")]
       VoidValue [register 16, register 8] Nothing
   , node_add (register 16) (register 31)
   ] ++ node_get (register 8) (register 16) 0 ++
   dispatch 0 (filter (\(_, (_, arity)) => arity > 0) methods) ++
   [call InvokeStatic generated_type "__idricMatchFailure" [] object_value [] (Just (register 16)), ReturnObject (register 16)])
  where
    dispatch : Int -> List (Name, (String, Int)) -> List Instruction
    dispatch label [] = []
    dispatch label ((_, (method, arity)) :: rest) =
      [ TextConstant (register 9) method
      , TextEqual (register 0) (register 8) (register 9)
      , IntegerConstant (register 1) 0
      , IntegerBranch EqualInteger (register 0) (register 1) (MkLabel label)
      , call InvokeVirtual node_type "size" [] integer_value [register 16] (Just (register 0))
      , IntegerConstant (register 1) (arity + 1)
      , IntegerBranch EqualInteger (register 0) (register 1) (MkLabel (label + 1))
      , ReturnObject (register 16)
      , Mark (MkLabel (label + 1))
      ] ++ concatMap (\index => node_get (register (17 + index)) (register 16) (index + 1)) [0..arity-1] ++
      [ call InvokeStatic generated_type method (replicate (cast arity) object_value) object_value
          (map (\index => register (17 + index)) [0..arity-1]) (Just (register 16))
      , ReturnObject (register 16), Mark (MkLabel label)
      ] ++ dispatch (label + 2) rest

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
  make_node (register 16) "_builtin.NIL" [] ++
  [Mark (MkLabel 0), IntegerConstant (register 0) 0
  , IntegerBranch EqualInteger (register 10) (register 0) (MkLabel 1)
  , call InvokeVirtual (MkTypeReference "Ljava/lang/String;") "codePointBefore" [integer_value]
      integer_value [register 18, register 10] (Just (register 11))
  , call InvokeStatic (MkTypeReference "Ljava/lang/Character;") "charCount" [integer_value]
      integer_value [register 11] (Just (register 12))
  , IntegerBinary SubtractInteger (register 10) (register 10) (register 12)
  ] ++ box_int (register 17) (register 11) ++ [MoveObject (register 9) (register 16)] ++
  make_node (register 16) "_builtin.CONS" [register 17, register 9] ++
  [Goto (MkLabel 0), Mark (MkLabel 1)]

private
pack_text : Register -> List Instruction
pack_text input =
  [ MoveObject (register 18) input
  , NewObject (register 17) (MkTypeReference "Ljava/lang/StringBuilder;")
  , call InvokeDirect (MkTypeReference "Ljava/lang/StringBuilder;") "<init>" [] VoidValue [register 17] Nothing
  , Mark (MkLabel 0)] ++ node_get (register 8) (register 18) 0 ++
  [TextConstant (register 9) "_builtin.NIL", TextEqual (register 0) (register 8) (register 9)
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
        [MoveObject (register 4) (parameter 0), CheckCast (register 4) number_type
        , call InvokeVirtual number_type "longValueExact" [] LongValue [register 4] (Just (register 2))
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

private
native_argument : CFType -> FrameworkValueType -> Register -> Register ->
  Either String (List Instruction)
native_argument CFString (ExistingValue TextValue) source destination = Right
  [MoveObject destination source, CheckCast destination (MkTypeReference "Ljava/lang/String;")]
native_argument CFInt (ExistingValue IntegerValue) source destination = Right (unbox_int destination source)
native_argument CFInt LongValue source destination = Right
  [MoveObject (register 4) source, CheckCast (register 4) number_type
  , call InvokeVirtual number_type "longValueExact" [] LongValue [register 4] (Just destination)]
native_argument source_type target_type source destination =
  Left ("Managed JNI argument cannot cross from " ++ show source_type ++ " to " ++ show target_type)

private
native_arguments : List CFType -> List FrameworkValueType -> Int -> Int ->
  Either String (List Instruction, List Register)
native_arguments [] [] source target = Right ([], [])
native_arguments (source_type :: sources) (target_type :: targets) source target = do
  current <- native_argument source_type target_type (register source) (register target)
  let width : Int = if target_type == LongValue then 2 else 1
  (more, registers) <- native_arguments sources targets (source + 1) (target + width)
  Right (current ++ more, register target :: registers)
native_arguments _ _ _ _ = Left "Managed JNI argument count differs from checked source declaration"

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
      (prepared, registers) <- native_arguments ordinary service.argument_types 64 24
      completed <- the (Either String (List Instruction)) $ case (source_result, service.result_type) of
        (CFInt, ExistingValue IntegerValue) => Right (box_int (register 16) (register 0))
        (CFInt, LongValue) => Right
          [call InvokeStatic number_type "valueOf" [LongValue] (ReferenceValue number_type)
            [register 0] (Just (register 16))]
        (CFString, ExistingValue TextValue) => Right [MoveObject (register 16) (register 0)]
        (CFUnit, VoidValue) => Right [NullReference (register 16)]
        _ => Left "Managed JNI result differs from checked source declaration"
      let invoke = call InvokeStatic generated_type service.method_name service.argument_types service.result_type
            registers (if service.result_type == VoidValue then Nothing else Just (register 0))
      Right (MkMethodPlan "checked managed JNI boundary" method (cast (length arguments))
        (replicate (length arguments) object_value) object_value (64 + cast (length arguments))
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
