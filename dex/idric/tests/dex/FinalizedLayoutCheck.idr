module FinalizedLayoutCheck

import Backend.DEX.Encode
import Backend.DEX.IR
import Backend.DEX.Smali
import Data.List
import Data.String
import System
import System.File

%default covering

fail : String -> IO a
fail message = do
  putStrLn ("FAIL: " ++ message)
  exitFailure

check : String -> Bool -> IO ()
check label True = pure ()
check label False = fail label

r0 : Register
r0 = MkRegister 0

method : String -> List Instruction -> MethodPlan
method name instructions =
  MkMethodPlan "finalized-layout-fixture" name 0 [] (ExistingValue IntegerValue) 1 instructions

fixture : FilePlan
fixture = MkFilePlan "LIdric/LayoutFixture;"
  [ method "forward16"
      (Goto (MkLabel 0) :: replicate 128 (IntegerConstant r0 0) ++
       [Mark (MkLabel 0), IntegerConstant r0 1, ReturnInteger r0])
  , method "backward16"
      ([Mark (MkLabel 0)] ++ replicate 129 (IntegerConstant r0 0) ++
       [Goto (MkLabel 0)])
  , method "explicit32"
      [Goto32 (MkLabel 0), IntegerConstant r0 0,
       Mark (MkLabel 0), IntegerConstant r0 1, ReturnInteger r0]
  , method "cascade"
      ([Goto (MkLabel 1), Goto (MkLabel 2)] ++
       replicate 125 (IntegerConstant r0 0) ++
       [Mark (MkLabel 1), IntegerConstant r0 1, ReturnInteger r0] ++
       replicate 5 (IntegerConstant r0 0) ++
       [Mark (MkLabel 2), IntegerConstant r0 2, ReturnInteger r0])
  , method "escaped_text"
      [TextConstant r0 "quote=\" slash=\\ tab=\t line=\n return=\r",
       IntegerConstant r0 1, ReturnInteger r0]
  ]

jump_names : Instruction -> List String
jump_names (Goto label) = ["goto"]
jump_names (Goto16 label) = ["goto/16"]
jump_names (Goto32 label) = ["goto/32"]
jump_names _ = []

write_text : String -> String -> IO ()
write_text path value = do
  Right () <- writeFile path value
    | Left error => fail ("could not write evidence: " ++ show error)
  pure ()

main : IO ()
main = do
  finalized <- case finalize_file_plan fixture of
    Left explanation => fail explanation
    Right accepted => pure accepted
  let plan = finalized_plan finalized
  let listing = render_file_plan plan
  let smali = render_finalized_smali finalized
  let jumps = concat (map (concat . map jump_names . instructions) plan.methods)
  check "finalized method order" (map method_name plan.methods ==
    ["backward16", "cascade", "escaped_text", "explicit32", "forward16"])
  check "all required goto promotions are represented in final plan"
    (jumps == ["goto/16", "goto/16", "goto/16", "goto/32", "goto/16"])
  check "finalized smali includes promoted jumps" (isInfixOf "goto/16 " smali)
  check "finalized smali includes explicit wide jump" (isInfixOf "goto/32 " smali)
  check "plan includes promoted jumps" (isInfixOf "goto/16 " listing)
  check "literal escaping preserves quote and slash"
    (isInfixOf "quote=\\\" slash=\\\\" smali)
  check "literal escaping preserves tab, LF and CR"
    (isInfixOf "tab=\\t line=\\n return=\\r" smali)
  check "compatibility smali uses the same finalization"
    (render_smali fixture == smali)
  bytes <- case encode_finalized_dex finalized of
    Left explanation => fail explanation
    Right encoded => pure encoded
  check "byte-only compatibility entry is unchanged"
    (encode_dex fixture == Right bytes)
  -- Finalized values are opaque. Accessors can inspect the plan but cannot
  -- forge a FinalizedFilePlan or silently feed a stale plan to the encoder.
  case !(getArgs) of
    [_, output_prefix] => do
      Right () <- write_dex (output_prefix ++ ".dex") bytes
        | Left explanation => fail explanation
      write_text (output_prefix ++ ".dex.plan") listing
      write_text (output_prefix ++ ".smali") smali
    [_] => pure ()
    _ => fail "usage: finalized-layout-check [absolute-output-prefix]"
  putStrLn "PASS: DEX finalized plan and readable evidence"
