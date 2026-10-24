module RuntimeArgsTest

import Backend.DEX.Encode
import Backend.DEX.IR
import Backend.DEX.RuntimeArgs
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
checked_entry : MethodPlan
checked_entry =
  MkMethodPlan "checked entrypoint fixture" "checkedStart" 0 [] VoidValue 1 [ReturnVoid]

private
base : FilePlan
base = MkFilePlan "LIdric/RuntimeArguments;" [checked_entry]

private
argument_type : FrameworkValueType
argument_type = ReferenceValue (MkTypeReference "[Ljava/lang/String;")

private
wrong_count : MethodPlan
wrong_count =
  MkMethodPlan "faulty runtime argument count" "__idricArgCount" 0 [] LongValue 6
    [ StaticGetObject (MkRegister 5)
        (MkFieldReference (MkTypeReference "LIdric/RuntimeArguments;")
          "__idric_arguments" argument_type)
    , ArrayLength (MkRegister 0) (MkRegister 5)
    , IntToLong (MkRegister 1) (MkRegister 0)
    , LongConstant (MkRegister 3) 2
    , AddLong (MkRegister 1) (MkRegister 1) (MkRegister 3)
    , ReturnWide (MkRegister 1)
    ]

main : IO ()
main = do
  plan <- case with_runtime_arguments "icu" "checkedStart" base of
    Left error => fail error
    Right value => pure value
  bytes <- case encode_dex plan of
    Left error => fail error
    Right encoded => pure encoded
  repeated <- case encode_dex plan of
    Left error => fail error
    Right encoded => pure encoded
  check "stable runtime argument DEX" (bytes == repeated)
  let smali = render_smali plan
  check "candidate declares real ART main"
    (isInfixOf ".method public static main([Ljava/lang/String;)V" smali)
  check "candidate retains private String[]"
    (isInfixOf ".field private static __idric_arguments:[Ljava/lang/String;" smali)
  check "source Int count is a long"
    (isInfixOf "__idricArgCount()J" smali)
  check "source Int index is a long"
    (isInfixOf "__idricArg(J)Ljava/lang/String;" smali)
  check "count uses wide addition" (isInfixOf "add-long " smali)
  check "index conversion is checked" (isInfixOf "toIntExact(J)I" smali)
  check "entry calls checked method"
    (isInfixOf "checkedStart()V" smali)
  let broken = { methods := map (\method => if method.method_name == "__idricArgCount" then wrong_count else method) plan.methods } plan
  wrong <- case encode_dex broken of
    Left error => fail error
    Right encoded => pure encoded
  check "compiled wrong-count mutation differs" (bytes /= wrong)
  case with_runtime_arguments "" "checkedStart" base of
    Left error => pure ()
    Right plan => fail "accepted empty argv executable name"
  case with_runtime_arguments "icu" "missingEntry" base of
    Left error => pure ()
    Right plan => fail "accepted nonexistent checked entrypoint"
  case with_runtime_arguments "icu" "checkedStart" plan of
    Left error => pure ()
    Right plan => fail "accepted duplicate runtime attachment"
  case encode_instructions [] [] [LongConstant (MkRegister 0) 32768] of
    Left error => pure ()
    Right bytes => fail "accepted wide literal outside signed16 range"
  case encode_instructions [] [] [AddLong (MkRegister 256) (MkRegister 0) (MkRegister 2)] of
    Left error => pure ()
    Right bytes => fail "accepted add-long destination outside byte register"
  result <- write_dex "build/runtime-arguments.dex" bytes
  case result of
    Left error => fail error
    Right () => pure ()
  changed <- write_dex "build/runtime-arguments-wrong.dex" wrong
  case changed of
    Left error => fail error
    Right () => pure ()
  putStrLn "PASS: reusable Idriç ART runtime arguments and wrong-count mutation"
