module TailTransferTest

import Backend.DEX.Heap
import Backend.DEX.IR
import Backend.DEX.Placement
import Compiler.ANF
import Core.FC
import Core.Name
import Core.TT.Term
import Data.List
import System

%default covering

-- Reference identities have no payload or implementation-specific layout.
data Cell = Uninitialised | NullCell | ReferenceCell Int | IntegerCell Int

Eq Cell where
  Uninitialised == Uninitialised = True
  NullCell == NullCell = True
  ReferenceCell left == ReferenceCell right = left == right
  IntegerCell left == IntegerCell right = left == right
  _ == _ = False

Show Cell where
  show Uninitialised = "uninitialised"
  show NullCell = "null"
  show (ReferenceCell identity) = "reference " ++ show identity
  show (IntegerCell value) = "integer " ++ show value

Cells : Type
Cells = List (Int, Cell)

read_cell : Register -> Cells -> Either String Cell
read_cell slot cells = maybe (Left ("register outside frame: " ++ show slot)) Right
  (lookup slot.number cells)

write_cell : Register -> Cell -> Cells -> Either String Cells
write_cell slot value cells = do
  _ <- read_cell slot cells
  Right (map (\(index, old) => (index, if index == slot.number then value else old)) cells)

read_integer : Register -> Cells -> Either String Int
read_integer slot cells = do
  IntegerCell value <- read_cell slot cells
    | other => Left ("integer instruction read " ++ show other ++ " at " ++ show slot)
  Right value

copy_reference : Register -> Register -> Cells -> Either String Cells
copy_reference target source cells = do
  value <- read_cell source cells
  case value of
    ReferenceCell _ => write_cell target value cells
    NullCell => write_cell target value cells
    _ => Left ("object move read " ++ show value ++ " at " ++ show source)

instruction_at : Int -> List Instruction -> Either String Instruction
instruction_at index instructions =
  if index < 0 then Left "negative execution index" else lookup_instruction (cast index) instructions
  where
    lookup_instruction : Nat -> List Instruction -> Either String Instruction
    lookup_instruction _ [] = Left "execution index outside instruction list"
    lookup_instruction Z (instruction :: _) = Right instruction
    lookup_instruction (S rest) (_ :: instructions) = lookup_instruction rest instructions

label_index : Label -> List Instruction -> Either String Int
label_index target = find_label 0
  where
    find_label : Int -> List Instruction -> Either String Int
    find_label _ [] = Left ("missing branch label " ++ show target)
    find_label index (Mark label :: rest) =
      if label == target then Right index else find_label (index + 1) rest
    find_label index (_ :: rest) = find_label (index + 1) rest

condition_holds : IntegerCondition -> Int -> Int -> Bool
condition_holds EqualInteger left right = left == right
condition_holds NotEqualInteger left right = left /= right
condition_holds LessThanInteger left right = left < right
condition_holds LessEqualInteger left right = left <= right
condition_holds GreaterThanInteger left right = left > right
condition_holds GreaterEqualInteger left right = left >= right

-- Stop on the requested backward transfer. No register number, selector or
-- dispatch-label identity is assumed by this interpreter.
run_until_transfers : Nat -> Nat -> List Instruction -> Int -> Cells -> Either String Cells
run_until_transfers Z transfers instructions index cells = Left "register machine exhausted its instruction budget"
run_until_transfers (S fuel) transfers instructions index cells = do
  instruction <- instruction_at index instructions
  case instruction of
    Mark _ => run_until_transfers fuel transfers instructions (index + 1) cells
    MoveObject target source => do
      next <- copy_reference target source cells
      run_until_transfers fuel transfers instructions (index + 1) next
    Move target source => do
      value <- read_integer source cells
      next <- write_cell target (IntegerCell value) cells
      run_until_transfers fuel transfers instructions (index + 1) next
    NullReference target => do
      next <- write_cell target NullCell cells
      run_until_transfers fuel transfers instructions (index + 1) next
    IntegerConstant target value => do
      next <- write_cell target (IntegerCell value) cells
      run_until_transfers fuel transfers instructions (index + 1) next
    IntegerBranch condition left right target => do
      first <- read_integer left cells
      second <- read_integer right cells
      next <- if condition_holds condition first second
        then label_index target instructions else Right (index + 1)
      run_until_transfers fuel transfers instructions next cells
    Goto target => jump target
    Goto16 target => jump target
    Goto32 target => jump target
    InvokeMethod invocation =>
      if invocation.method.name == "choose_second" then case (invocation.arguments, invocation.result_register) of
        ([_, second], Just target) => do
          next <- copy_reference target second cells
          run_until_transfers fuel transfers instructions (index + 1) next
        _ => Left "choose_second call has an invalid ABI"
      else Left ("unexpected invoked method " ++ invocation.method.name)
    _ => Left ("unexpected instruction before tail transfer: " ++ show instruction)
  where
    jump : Label -> Either String Cells
    jump target = do
      next <- label_index target instructions
      if next <= index
        then case transfers of
          Z => Left "zero requested tail transfers"
          S Z => Right cells
          S remaining => run_until_transfers fuel remaining instructions next cells
        else run_until_transfers fuel transfers instructions next cells

checked_name : String -> Name
checked_name text = UN (Basic text)

local_value : Int -> Administrative_Normal_Form
local_value index = Administrative_Normal_Form_Variable_Expression emptyFC
  (Administrative_Normal_Form_Local_Variable index)

checked_call : String -> List Int -> Administrative_Normal_Form
checked_call target inputs = Administrative_Normal_Form_Named_Function_Application emptyFC Nothing
  (checked_name target) (map Administrative_Normal_Form_Local_Variable inputs)

swap_definitions : List (Name, Administrative_Normal_Form_Definition)
swap_definitions =
  [(checked_name "swap", Make_Administrative_Normal_Form_Function [0, 1]
    (Administrative_Normal_Form_Binding emptyFC 2 (checked_call "choose_second" [1, 0])
      (checked_call "swap" [1, 0]))),
   (checked_name "choose_second", Make_Administrative_Normal_Form_Function [0, 1] (local_value 1))]

mutual_definitions : List (Name, Administrative_Normal_Form_Definition)
mutual_definitions =
  [(checked_name "large", Make_Administrative_Normal_Form_Function [0, 1, 2]
    (Administrative_Normal_Form_Binding emptyFC 3 (local_value 2)
      (checked_call "small" [1]))),
   (checked_name "small", Make_Administrative_Normal_Form_Function [0]
    (checked_call "large" [0, 0, 0]))]

dispatcher : List (Name, (String, Int)) -> List (Name, Administrative_Normal_Form_Definition) -> Either String MethodPlan
dispatcher abis definitions = do
  (_, methods) <- heap_tail_methods abis definitions
  case filter (\method => case method.parameter_types of
          ExistingValue IntegerValue :: _ => True
          _ => False) methods of
    [method] => Right method
    _ => Left "expected one integer-selected tail-group method"

initial_frame : MethodPlan -> Int -> List Cell -> Either String Cells
initial_frame method selector arguments = do
  let incoming_start = method.register_count - method.parameter_count
  let cells = map (\index => (index, Uninitialised)) [0 .. method.register_count - 1]
  selected <- write_cell (MkRegister incoming_start) (IntegerCell selector) cells
  seed (incoming_start + 1) arguments selected
  where
    seed : Int -> List Cell -> Cells -> Either String Cells
    seed next [] cells = Right cells
    seed next (value :: rest) cells = do
      assigned <- write_cell (MkRegister next) value cells
      seed (next + 1) rest assigned

parameter_values : MethodPlan -> Cells -> Either String (List Cell)
parameter_values method cells =
  traverse (\index => read_cell (MkRegister index) cells)
    [method.register_count - method.parameter_count + 1 .. method.register_count - 1]

temporary_roots_cleared : MethodPlan -> Cells -> Bool
temporary_roots_cleared method cells =
  let parameters_start = method.register_count - method.parameter_count + 1 in
  all (\(index, value) => case value of
    ReferenceCell _ => index >= parameters_start
    _ => True) cells

require : String -> Bool -> Either String ()
require description True = Right ()
require description False = Left description

check_swap : Either String ()
check_swap = do
  method <- dispatcher [(checked_name "swap", ("swap", 2)),
    (checked_name "choose_second", ("choose_second", 2))] swap_definitions
  before <- initial_frame method 0 [ReferenceCell 11, ReferenceCell 22]
  after <- run_until_transfers 2048 1 method.instructions 0 before
  values <- parameter_values method after
  require ("simultaneous parameter swap: " ++ show values)
    (values == [ReferenceCell 22, ReferenceCell 11])
  require "dead staging or member-local reference survived swap" (temporary_roots_cleared method after)

-- Placement may move incoming arguments into a disjoint logical frame. Read
-- those destinations from its actual typed prologue, then demand that the
-- incoming and outgoing aliases have ceased to retain reference identities.
copied_parameter_targets : Nat -> List Instruction -> Either String (List Register)
copied_parameter_targets Z _ = Right []
copied_parameter_targets (S remaining) (Move target _ :: rest) =
  (target ::) <$> copied_parameter_targets remaining rest
copied_parameter_targets (S remaining) (MoveObject target _ :: rest) =
  (target ::) <$> copied_parameter_targets remaining rest
copied_parameter_targets _ _ = Left "placement did not start with a complete typed parameter copy"

check_placed_swap : Either String ()
check_placed_swap = do
  original <- dispatcher [(checked_name "swap", ("swap", 2)),
    (checked_name "choose_second", ("choose_second", 2))] swap_definitions
  placed <- prepare_method_invocations original
  require "test did not exercise invocation placement" (placed.register_count > original.register_count)
  targets <- copied_parameter_targets (cast placed.parameter_count) placed.instructions
  let object_targets = drop 1 targets
  before <- initial_frame placed 0 [ReferenceCell 11, ReferenceCell 22]
  after <- run_until_transfers 2048 1 placed.instructions 0 before
  values <- traverse (\slot => read_cell slot after) object_targets
  require ("placed simultaneous parameter swap: " ++ show values)
    (values == [ReferenceCell 22, ReferenceCell 11])
  require "placed incoming/outgoing aliases retained old references"
    (all (\(index, value) => case value of
      ReferenceCell _ => elem (MkRegister index) object_targets
      _ => True) after)

check_varying_arity : Either String ()
check_varying_arity = do
  method <- dispatcher [(checked_name "large", ("large", 3)),
    (checked_name "small", ("small", 1))] mutual_definitions
  before <- initial_frame method 0 [ReferenceCell 11, ReferenceCell 22, ReferenceCell 33]
  smaller <- run_until_transfers 2048 1 method.instructions 0 before
  smaller_values <- parameter_values method smaller
  require ("varying arity clears unused parameters: " ++ show smaller_values)
    (smaller_values == [ReferenceCell 22, NullCell, NullCell])
  require "dead staging or member-local reference survived arity reduction" (temporary_roots_cleared method smaller)
  larger <- run_until_transfers 2048 2 method.instructions 0 before
  larger_values <- parameter_values method larger
  require ("mutual redispatch selects the next member: " ++ show larger_values)
    (larger_values == [ReferenceCell 22, ReferenceCell 22, ReferenceCell 22])
  require "dead staging or member-local reference survived mutual redispatch" (temporary_roots_cleared method larger)

checks : Either String ()
checks = do
  check_swap
  check_varying_arity
  check_placed_swap

main : IO ()
main = case checks of
  Left explanation => do
    putStrLn ("FAIL tail transfer: " ++ explanation)
    exitFailure
  Right () => putStrLn "PASS actual tail plans preserve swaps, varying arities and reference liveness"
