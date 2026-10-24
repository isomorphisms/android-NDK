module ArgvBridgeTest

import Backend.DEX.Encode
import Backend.DEX.IR
import Backend.DEX.Smali
import Data.String
import System

%default covering

private
fail : String -> IO a
fail message = do
  putStrLn ("FAIL: " ++ message)
  exitFailure

private
check : String -> Bool -> IO ()
check label True = pure ()
check label False = fail label

private
arguments_type : FrameworkValueType
arguments_type = ReferenceValue (MkTypeReference "[Ljava/lang/String;")

-- A real DEX method boundary that accepts ART's String[] and widens the
-- argument count to the 64-bit source Int representation. Slot zero is
-- reserved for the executable name by System.getArgs.
private
count_method : MethodPlan
count_method =
  MkMethodPlan "runtime boundary fixture" "commandLineCount"
    1 [arguments_type] LongValue 4
    [ ArrayLength (MkRegister 0) (MkRegister 3)
    , IntegerConstant (MkRegister 1) 1
    , IntegerBinary AddInteger (MkRegister 0) (MkRegister 0) (MkRegister 1)
    , IntToLong (MkRegister 1) (MkRegister 0)
    , ReturnWide (MkRegister 1)
    ]

-- Probe only: the actual checked System.getArg boundary still needs Int64
-- indexing, argument-array lifetime, and explicit invalid-index semantics.
private
argument_method : MethodPlan
argument_method =
  MkMethodPlan "runtime boundary fixture" "commandLineArg32"
    2 [arguments_type, ExistingValue IntegerValue] (ExistingValue TextValue) 5
    [ IntegerConstant (MkRegister 0) 0
    , IntegerBranch EqualInteger (MkRegister 4) (MkRegister 0) (MkLabel 0)
    , IntegerConstant (MkRegister 1) 1
    , IntegerBinary SubtractInteger (MkRegister 2) (MkRegister 4) (MkRegister 1)
    , ArrayGetObject (MkRegister 0) (MkRegister 3) (MkRegister 2)
    , ReturnObject (MkRegister 0)
    , Mark (MkLabel 0)
    , TextConstant (MkRegister 0) "icu"
    , ReturnObject (MkRegister 0)
    ]

private
fixture : FilePlan
fixture = MkFilePlan "LIdric/ArgvBoundary;" [count_method, argument_method]

main : IO ()
main = do
  finalized <- case finalize_file_plan fixture of
    Left explanation => fail explanation
    Right value => pure value
  first <- case encode_finalized_dex finalized of
    Left explanation => fail explanation
    Right value => pure value
  second <- case encode_dex fixture of
    Left explanation => fail explanation
    Right value => pure value
  check "deterministic argument DEX" (first == second)
  let plan = finalized_plan finalized
  let smali = render_finalized_smali finalized
  check "actual String[] descriptor"
    (isInfixOf "commandLineCount([Ljava/lang/String;)J" smali)
  check "array length instruction" (isInfixOf "array-length " smali)
  check "object indexed load" (isInfixOf "aget-object " smali)
  check "widened Idriç Int result" (isInfixOf "int-to-long " smali)
  check "wide return" (isInfixOf "return-wide " smali)
  case encode_dex
    (MkFilePlan "LIdric/InvalidArgv;"
      [MkMethodPlan "invalid" "badCount" 1 [arguments_type] LongValue 3
        [ArrayLength (MkRegister 0) (MkRegister 3),
         IntToLong (MkRegister 1) (MkRegister 0),
         ReturnWide (MkRegister 1)]]) of
    Left explanation => pure ()
    Right bytes => fail "accepted argument register outside its frame"
  case encode_dex
    (MkFilePlan "LIdric/InvalidArgv;"
      [MkMethodPlan "invalid" "badWide" 0 [] LongValue 1
        [IntToLong (MkRegister 0) (MkRegister 0),
         ReturnWide (MkRegister 0)]]) of
    Left explanation => pure ()
    Right bytes => fail "accepted 64-bit return without second register"
  result <- write_dex "build/argv-boundary.dex" first
  case result of
    Left explanation => fail explanation
    Right () => pure ()
  putStrLn "PASS: DEX ART argument-array bridge plan and refusal controls"
