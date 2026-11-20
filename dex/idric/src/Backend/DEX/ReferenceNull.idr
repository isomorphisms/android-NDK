module Backend.DEX.ReferenceNull

import Backend.DEX.IR

%default total

||| Inspect the reference before overwriting the result, even when a caller's
||| input and result registers alias. No platform API supplies this primitive.
public export
reference_null_instructions : Register -> Register -> Label -> Label -> List Instruction
reference_null_instructions reference result null_case finished =
  [ ReferenceNullBranch EqualNull reference null_case
  , IntegerConstant result 0
  , Goto finished
  , Mark null_case
  , IntegerConstant result 1
  , Mark finished
  ]
