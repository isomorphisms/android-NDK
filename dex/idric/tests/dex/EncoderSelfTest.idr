module EncoderSelfTest

import Backend.DEX.Encode
import Backend.DEX.Hash
import Backend.DEX.IR
import Data.List
import System

%default covering

private
fail : String -> IO a
fail message = do
  putStrLn ("FAIL: " ++ message)
  exitFailure

private
expect_equal : Eq value => Show value => String -> value -> value -> IO ()
expect_equal label expected actual =
  if expected == actual
    then pure ()
    else fail (label ++ ": expected " ++ show expected ++ ", got " ++ show actual)

private
expect_left : String -> Either String value -> IO ()
expect_left label (Left explanation) = pure ()
expect_left label (Right value) = fail (label ++ ": malformed plan was accepted")

private
encoded_stream : String -> List Instruction -> IO (List Int)
encoded_stream label instructions =
  case encode_instructions [] [] instructions of
    Left explanation => fail (label ++ ": " ++ explanation)
    Right bytes => pure bytes

private
edge_method : MethodPlan
edge_method =
  MkMethodPlan "selftest" "edge_constants" 0 [] (ExistingValue IntegerValue) 1
    [ IntegerConstant (MkRegister 0) (-2147483648)
    , IntegerConstant (MkRegister 0) 2147483647
    , ReturnInteger (MkRegister 0)
    ]

private
wide_move_method : MethodPlan
wide_move_method =
  MkMethodPlan "selftest" "wide_moves" 0 [] (ExistingValue IntegerValue) 257
    [ IntegerConstant (MkRegister 255) 7
    , Move (MkRegister 256) (MkRegister 255)
    , Move (MkRegister 254) (MkRegister 256)
    , ReturnInteger (MkRegister 254)
    ]

private
text_identity_method : MethodPlan
text_identity_method =
  MkMethodPlan "selftest" "echo_text" 1 [ExistingValue TextValue] (ExistingValue TextValue) 2
    [ MoveObject (MkRegister 0) (MkRegister 1)
    , ReturnObject (MkRegister 0)
    ]

private
text_constant_method : MethodPlan
text_constant_method =
  MkMethodPlan "selftest" "icu_word" 0 [] (ExistingValue TextValue) 1
    [ TextConstant (MkRegister 0) "icu"
    , ReturnObject (MkRegister 0)
    ]

private
bad_arithmetic_method : MethodPlan
bad_arithmetic_method =
  MkMethodPlan "selftest" "bad_arithmetic_register" 0 [] (ExistingValue IntegerValue) 257
    [ IntegerBinary AddInteger (MkRegister 256) (MkRegister 0) (MkRegister 1)
    , ReturnInteger (MkRegister 0)
    ]

private
bad_branch_method : MethodPlan
bad_branch_method =
  MkMethodPlan "selftest" "bad_branch_register" 0 [] (ExistingValue IntegerValue) 18
    [ IntegerBranch LessThanInteger (MkRegister 16) (MkRegister 17) (MkLabel 0)
    , IntegerConstant (MkRegister 0) 0
    , Mark (MkLabel 0)
    , ReturnInteger (MkRegister 0)
    ]

private
long_goto_method : MethodPlan
long_goto_method =
  MkMethodPlan "selftest" "long_goto" 0 [] (ExistingValue IntegerValue) 1
    (Goto (MkLabel 0) ::
     replicate 128 (IntegerConstant (MkRegister 0) 0) ++
     [Mark (MkLabel 0), ReturnInteger (MkRegister 0)])

private
single_method_file : MethodPlan -> FilePlan
single_method_file method = MkFilePlan "LIdric/SelfTest;" [method]

main : IO ()
main = do
  expect_equal "SHA-1 abc"
    [169, 153, 62, 54, 71, 6, 129, 106, 186, 62,
     37, 113, 120, 80, 194, 108, 156, 208, 216, 157]
    (sha1 [97, 98, 99])
  expect_equal "Adler-32 Wikipedia" 0x11e60398
    (adler32 (map ord (unpack "Wikipedia")))
  let plan =
        MkFilePlan "LIdric/SelfTest;"
          [edge_method, wide_move_method, text_identity_method, text_constant_method]
  first <- case encode_dex plan of
    Left explanation => fail explanation
    Right bytes => pure bytes
  second <- case encode_dex plan of
    Left explanation => fail explanation
    Right bytes => pure bytes
  expect_equal "deterministic direct encoding" first second
  expect_equal "DEX 035 magic" [100, 101, 120, 10, 48, 51, 53, 0]
    (take 8 first)
  expect_left "format 23x register limit"
    (encode_dex (single_method_file bad_arithmetic_method))
  expect_left "format 22t register limit"
    (encode_dex (single_method_file bad_branch_method))
  -- Short forward offsets keep compact 10t encoding (1 code unit).
  let r0 = MkRegister 0
  let destination = MkLabel 0
  short <- encoded_stream "short goto"
    [ Goto destination, IntegerConstant r0 0, Mark destination
    , ReturnInteger r0 ]
  expect_equal "short goto byte encoding"
    [0x28, 0x02, 0x12, 0x00, 0x0f, 0x00] short

  -- The earlier 10t overflow now becomes valid signed 20t, not a refusal.
  medium <- encoded_stream "forward goto/16"
    (Goto destination :: replicate 128 (IntegerConstant r0 0) ++
      [Mark destination, ReturnInteger r0])
  expect_equal "promoted forward goto/16 bytes" [0x29, 0x00, 0x82, 0x00]
    (take 4 medium)
  case encode_dex (single_method_file long_goto_method) of
    Left explanation => fail ("long goto is still rejected: " ++ explanation)
    Right bytes => expect_equal "long goto DEX signature"
                     [100, 101, 120, 10] (take 4 bytes)

  -- Backward offsets are relative to the jump's own address and signed.
  backward <- encoded_stream "backward goto/16"
    ([Mark destination] ++ replicate 129 (IntegerConstant r0 0) ++
     [Goto destination])
  expect_equal "negative goto/16 bytes" [0x29, 0x00, 0x7f, 0xff]
    (drop 258 backward)

  -- One promotion can push a previously short forward branch out of 10t.
  -- A single one-shot widening pass would encode a wrong instruction width.
  cascade <- encoded_stream "cascading goto widening"
    ([Goto (MkLabel 1), Goto (MkLabel 2)] ++
      replicate 125 (IntegerConstant r0 0) ++
     [Mark (MkLabel 1), ReturnInteger r0] ++
      replicate 5 (IntegerConstant r0 0) ++
     [Mark (MkLabel 2), ReturnInteger r0])
  expect_equal "cascading first and second /16 offsets"
    [0x29, 0x00, 0x81, 0x00, 0x29, 0x00, 0x85, 0x00]
    (take 8 cascade)

  -- Direct 30t uses the prescribed signed 32-bit little-endian offset.
  wide <- encoded_stream "explicit goto/32"
    [Goto32 destination, IntegerConstant r0 0, Mark destination]
  expect_equal "goto/32 opcode and offset"
    [0x2a, 0x00, 0x04, 0x00, 0x00, 0x00, 0x12, 0x00] wide

  expect_left "zero-offset goto is forbidden"
    (encode_instructions [] [] [Mark destination, Goto destination])
  expect_left "undefined goto label is forbidden"
    (encode_instructions [] [] [Goto (MkLabel 12)])
  expect_left "duplicate goto label is forbidden"
    (encode_instructions [] [] [Mark destination, Mark destination])
  putStrLn "PASS: DEX encoder self-test"
