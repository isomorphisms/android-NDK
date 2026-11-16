module Float32IRCheck

-- Compiler-IR fixture, using the retained frontend's ordinary .idr API.
-- Actual source-domain and ART observations are separate checks.
import Backend.DEX.Encode
import Backend.DEX.IR
import Backend.DEX.Placement
import Backend.DEX.Smali
import Data.List
import Data.String
import System

%default covering

fail : String -> IO value
fail reason = do
  putStrLn ("FAIL Float32 IR: " ++ reason)
  exitFailure

check : String -> Bool -> IO ()
check _ True = pure ()
check label False = fail label

equal : Eq value => String -> value -> value -> IO ()
equal label expected actual = check label (expected == actual)

refuse : String -> Either String value -> IO ()
refuse _ (Left _) = pure ()
refuse label (Right _) = fail (label ++ " accepted")

main : IO ()
main = do
  bytes <- case encode_instructions [] []
    [ Binary32Binary AddBinary32 (MkRegister 7) (MkRegister 11) (MkRegister 19)
    , Binary32Binary SubtractBinary32 (MkRegister 7) (MkRegister 11) (MkRegister 19)
    , Binary32Binary MultiplyBinary32 (MkRegister 7) (MkRegister 11) (MkRegister 19)
    , Binary32Binary DivideBinary32 (MkRegister 7) (MkRegister 11) (MkRegister 19)
    ] of
      Left reason => fail reason
      Right accepted => pure accepted
  equal "independent Float32 opcode and 23x operand bytes"
    [0xa6,7,11,19, 0xa7,7,11,19, 0xa8,7,11,19, 0xa9,7,11,19] bytes
  refuse "negative float register"
    (encode_instructions [] [] [Binary32Binary AddBinary32 (MkRegister (-1)) (MkRegister 0) (MkRegister 1)])
  refuse "destination exceeds 23x register width"
    (encode_instructions [] [] [Binary32Binary AddBinary32 (MkRegister 256) (MkRegister 0) (MkRegister 1)])
  refuse "left input exceeds 23x register width"
    (encode_instructions [] [] [Binary32Binary AddBinary32 (MkRegister 0) (MkRegister 256) (MkRegister 1)])
  refuse "right input exceeds 23x register width"
    (encode_instructions [] [] [Binary32Binary AddBinary32 (MkRegister 0) (MkRegister 1) (MkRegister 256)])
  let single_word = MkMethodPlan "Float32 is one register" "single_word" 0 [] VoidValue 1
        [Binary32Binary AddBinary32 (MkRegister 0) (MkRegister 0) (MkRegister 0), ReturnVoid]
  case prepare_method_invocations single_word of
    Left reason => fail reason
    Right accepted => equal "single float operand does not require a pair" 1 accepted.register_count
  let outside_frame = MkMethodPlan "invalid Float32 frame" "outside_frame" 0 [] VoidValue 1
        [Binary32Binary AddBinary32 (MkRegister 0) (MkRegister 0) (MkRegister 1), ReturnVoid]
  refuse "float operand outside declared register frame" (prepare_method_invocations outside_frame)
  let high_alias = MkMethodPlan "high Float32 aliased destination" "high_alias" 0 [] VoidValue 302
        [Binary32Binary SubtractBinary32 (MkRegister 300) (MkRegister 299) (MkRegister 300), ReturnVoid]
  placed <- case prepare_method_invocations high_alias of
    Left reason => fail reason
    Right accepted => pure accepted
  equal "single-word scratch region" 304 placed.register_count
  equal "operand order survives high destination/input alias"
    ["move v0, v301", "move v1, v302", "sub-float v0, v0, v1", "move v302, v0", "return-void"]
    (map show placed.instructions)
  let incoming_float = MkMethodPlan "high Float32 incoming value" "incoming_float" 1
        [ExistingValue FloatValue] (ExistingValue FloatValue) 302
        [Binary32Binary SubtractBinary32 (MkRegister 300) (MkRegister 301) (MkRegister 300),
         ReturnInteger (MkRegister 300)]
  incoming <- case prepare_method_invocations incoming_float of
    Left reason => fail reason
    Right accepted => pure accepted
  equal "Float32 incoming area consumes one word" 305 incoming.register_count
  equal "Float32 incoming and result use plain moves"
    ["move v303, v304", "move v0, v303", "move v1, v302", "sub-float v0, v0, v1",
     "move v302, v0", "move v0, v302", "return v0"]
    (map show incoming.instructions)
  frozen <- case finalize_file_plan (MkFilePlan "LIdric/Float32IRFixture;" [high_alias, incoming_float]) of
    Left reason => fail reason
    Right accepted => pure accepted
  check "finalized Smali keeps Float32 subtraction"
    (isInfixOf "sub-float v0, v0, v1" (render_finalized_smali frozen))
  first <- case encode_finalized_dex frozen of
    Left reason => fail reason
    Right accepted => pure accepted
  second <- case encode_finalized_dex frozen of
    Left reason => fail reason
    Right accepted => pure accepted
  equal "deterministic full DEX encoding" first second
  check "full DEX is present" (length first > 112)
  putStrLn "PASS Float32 opcode, register placement and alias checks"
