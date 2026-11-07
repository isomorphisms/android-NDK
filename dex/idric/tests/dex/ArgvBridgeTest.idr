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
argv_field : FieldReference
argv_field = MkFieldReference
  (MkTypeReference "LIdric/ArgvBoundary;") "arguments" arguments_type

private
saved_field : StaticFieldPlan
saved_field = MkStaticFieldPlan "arguments" arguments_type 10

private
remember_method : MethodPlan
remember_method =
  MkMethodPlan "saved argv proof" "rememberArguments"
    1 [arguments_type] VoidValue 1
    [StaticPutObject (MkRegister 0) argv_field, ReturnVoid]

private
saved_count_method : MethodPlan
saved_count_method =
  MkMethodPlan "saved argv proof" "savedCommandLineCount"
    0 [] LongValue 4
    [ StaticGetObject (MkRegister 3) argv_field
    , ArrayLength (MkRegister 0) (MkRegister 3)
    , IntegerConstant (MkRegister 1) 1
    , IntegerBinary AddInteger (MkRegister 0) (MkRegister 0) (MkRegister 1)
    , IntToLong (MkRegister 1) (MkRegister 0)
    , ReturnWide (MkRegister 1)
    ]

private
saved_argument_method : MethodPlan
saved_argument_method =
  MkMethodPlan "saved argv proof" "savedCommandLineArg32"
    1 [ExistingValue IntegerValue] (ExistingValue TextValue) 5
    [ StaticGetObject (MkRegister 3) argv_field
    , IntegerConstant (MkRegister 0) 0
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
fixture = { fields := [saved_field] }
  (MkFilePlan "LIdric/ArgvBoundary;"
    [count_method, argument_method, remember_method, saved_count_method, saved_argument_method])

-- Same checked target plan, one deliberately incorrect runtime count.
-- An independent ART observer must reject this actual candidate mutation.
private
wrong_count_method : MethodPlan
wrong_count_method =
  MkMethodPlan "runtime boundary deliberate mutation" "commandLineCount"
    1 [arguments_type] LongValue 4
    [ ArrayLength (MkRegister 0) (MkRegister 3)
    , IntegerConstant (MkRegister 1) 2
    , IntegerBinary AddInteger (MkRegister 0) (MkRegister 0) (MkRegister 1)
    , IntToLong (MkRegister 1) (MkRegister 0)
    , ReturnWide (MkRegister 1)
    ]

private
wrong_fixture : FilePlan
wrong_fixture = { fields := [saved_field] }
  (MkFilePlan "LIdric/ArgvBoundary;"
    [wrong_count_method, argument_method, remember_method, saved_count_method, saved_argument_method])

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
  check "declared private static argument field"
    (isInfixOf ".field private static arguments:[Ljava/lang/String;" smali)
  check "stored argv read and write" (isInfixOf "sget-object " smali &&
                                       isInfixOf "sput-object " smali)
  case encode_dex ({ fields := [saved_field, saved_field] } fixture) of
    Left explanation => pure ()
    Right bytes => fail "accepted duplicate static field"
  case encode_dex
    ({ fields := [MkStaticFieldPlan "arguments" (ExistingValue IntegerValue) 10] }
      fixture) of
    Left explanation => pure ()
    Right bytes => fail "accepted integer field with object read/write"
  case encode_dex
    ({ fields := [MkStaticFieldPlan "arguments" arguments_type 2] } fixture) of
    Left explanation => pure ()
    Right bytes => fail "accepted nonstatic field in static field set"
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
  mutated <- case encode_dex wrong_fixture of
    Left explanation => fail explanation
    Right value => pure value
  check "wrong count changes actual candidate bytes" (first /= mutated)
  result <- write_dex "build/argv-boundary.dex" first
  case result of
    Left explanation => fail explanation
    Right () => pure ()
  wrong_result <- write_dex "build/argv-wrong.dex" mutated
  case wrong_result of
    Left explanation => fail explanation
    Right () => pure ()
  putStrLn "PASS: DEX ART argument-array bridge plan and refusal controls"
