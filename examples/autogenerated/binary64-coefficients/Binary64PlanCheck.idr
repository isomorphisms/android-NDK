module Binary64PlanCheck

-- Compiler-IR compatibility fixture: ordinary .idr types name the maintained
-- bootstrap API. The application-facing source probe is Binary64Source.idric.
import Backend.DEX.Binary64
import Backend.DEX.Encode
import Backend.DEX.IR
import Backend.DEX.Foreign
import Backend.DEX.Invoke
import Backend.DEX.ManagedBoundary
import Backend.DEX.Placement
import Backend.DEX.Smali
import Data.List
import Data.String
import Core.CompileExpr
import System

%default covering

fail : String -> IO value
fail reason = do
  putStrLn ("FAIL binary64 plan: " ++ reason)
  exitFailure

check : String -> Bool -> IO ()
check _ True = pure ()
check label False = fail label

equal : Eq value => String -> value -> value -> IO ()
equal label expected actual = check label (expected == actual)

bits : String -> Double -> Integer -> IO ()
bits label value expected = case binary64_literal_bits value of
  Left reason => fail (label ++ ": " ++ reason)
  Right actual => equal label expected actual

refuse : String -> Either String value -> IO ()
refuse _ (Left _) = pure ()
refuse label (Right _) = fail (label ++ " accepted")

encoded : List Instruction -> IO (List Int)
encoded code = case encode_instructions [] [] code of
  Left reason => fail reason
  Right bytes => pure bytes

find_invocation : String -> List Instruction -> Maybe InvocationPlan
find_invocation _ [] = Nothing
find_invocation name (InvokeMethod invocation :: rest) =
  if invocation.method.name == name then Just invocation else find_invocation name rest
find_invocation name (_ :: rest) = find_invocation name rest

platform_plan : String -> List CFType -> CFType -> IO MethodPlan
platform_plan convention arguments result =
  case parse_dex_foreign convention arguments result of
    Left reason => fail reason
    Right foreign => do
      check "platform coefficient operation stays pure" (foreign.effect == PureForeign)
      case managed_foreign_bridge "platform_probe" foreign of
        Left reason => fail reason
        Right method => pure method

main : IO ()
main = do
  bits "positive zero" 0.0 0
  bits "negative zero" (negate 0.0) 0x8000000000000000
  bits "one" 1.0 0x3ff0000000000000
  bits "decimal coefficient" 0.4 0x3fd999999999999a
  bits "Float32-distinguishing literal" 16777217.0 0x4170000010000000
  bits "largest consecutive integer" 9007199254740991.0 0x433fffffffffffff
  bits "least normal" 2.2250738585072014e-308 0x0010000000000000
  bits "least subnormal" 4.9406564584124654e-324 1
  bits "greatest finite" 1.7976931348623157e308 0x7fefffffffffffff
  bits "positive infinity" (1.0 / 0.0) 0x7ff0000000000000
  bits "negative infinity" ((negate 1.0) / 0.0) 0xfff0000000000000
  bits "canonical quiet NaN" (0.0 / 0.0) 0x7ff8000000000000
  literal <- encoded [Binary64Constant (MkRegister 0) 0x8000000000000000]
  equal "exact const-wide negative zero bytes"
    [0x18, 0x00, 0, 0, 0, 0, 0, 0, 0, 0x80] literal
  converted <- encoded [SignedIntToBinary64 (MkRegister 6) (MkRegister 8)]
  equal "signed Int32-to-binary64 format 12x bytes" [0x83, 0x86] converted
  refuse "Int32-to-binary64 source 4-bit overflow"
    (encode_instructions [] [] [SignedIntToBinary64 (MkRegister 0) (MkRegister 16)])
  arithmetic <- encoded
    [ Binary64Binary AddBinary64 (MkRegister 0) (MkRegister 2) (MkRegister 4)
    , Binary64Binary SubtractBinary64 (MkRegister 0) (MkRegister 2) (MkRegister 4)
    , Binary64Binary MultiplyBinary64 (MkRegister 0) (MkRegister 2) (MkRegister 4)
    , Binary64Binary DivideBinary64 (MkRegister 0) (MkRegister 2) (MkRegister 4)
    , NegateBinary64 (MkRegister 6) (MkRegister 8)
    , CompareBinary64 NaNLow (MkRegister 1) (MkRegister 2) (MkRegister 4)
    , CompareBinary64 NaNHigh (MkRegister 1) (MkRegister 2) (MkRegister 4)
    ]
  equal "independent IEEE DEX opcode/format bytes"
    [0xab,0,2,4, 0xac,0,2,4, 0xad,0,2,4, 0xae,0,2,4,
     0x80,0x86, 0x2f,1,2,4, 0x30,1,2,4] arithmetic
  refuse "negative representation"
    (encode_instructions [] [] [Binary64Constant (MkRegister 0) (-1)])
  refuse "more than 64 representation bits"
    (encode_instructions [] [] [Binary64Constant (MkRegister 0) 18446744073709551616])
  refuse "binary64 arithmetic 8-bit overflow"
    (encode_instructions [] [] [Binary64Binary AddBinary64 (MkRegister 256) (MkRegister 0) (MkRegister 2)])
  refuse "binary64 negation 4-bit overflow"
    (encode_instructions [] [] [NegateBinary64 (MkRegister 0) (MkRegister 16)])
  let negation = MkMethodPlan "binary64 placement" "negation" 1
        [ExistingValue DoubleValue] (ExistingValue DoubleValue) 24
        [NegateBinary64 (MkRegister 20) (MkRegister 22), ReturnWide (MkRegister 20)]
  placed <- case prepare_method_invocations negation of
    Left reason => fail reason
    Right method => pure method
  equal "paired incoming placement frame" 28 placed.register_count
  equal "paired incoming and result moves"
    ["move-wide v24, v26", "move-wide v0, v24", "neg-double v0, v0",
     "move-wide v22, v0", "return-wide v22"] (map show placed.instructions)
  let conversion = MkMethodPlan "signed Int32 to binary64 placement" "conversion" 1
        [ExistingValue IntegerValue] (ExistingValue DoubleValue) 24
        [SignedIntToBinary64 (MkRegister 20) (MkRegister 23), ReturnWide (MkRegister 20)]
  converted_method <- case prepare_method_invocations conversion of
    Left reason => fail reason
    Right method => pure method
  equal "conversion keeps narrow input and paired output moves"
    ["move v25, v26", "move v0, v25", "int-to-double v0, v0",
     "move-wide v22, v0", "return-wide v22"] (map show converted_method.instructions)
  equal "conversion staged frame uses one incoming word" 27 converted_method.register_count
  let bad_conversion = MkMethodPlan "truncated conversion pair" "bad_conversion" 0 [] VoidValue 2
        [SignedIntToBinary64 (MkRegister 1) (MkRegister 0), ReturnVoid]
  refuse "Int32-to-binary64 truncated output pair" (prepare_method_invocations bad_conversion)
  let bad_pair = MkMethodPlan "binary64 truncated pair" "bad_pair" 0 [] VoidValue 2
        [Binary64Constant (MkRegister 1) 0, ReturnVoid]
  refuse "truncated frame pair" (prepare_method_invocations bad_pair)
  let high_binary = MkMethodPlan "binary64 high pair" "high_pair" 0 [] VoidValue 302
        [Binary64Binary AddBinary64 (MkRegister 300) (MkRegister 0) (MkRegister 2), ReturnVoid]
  refuse "unsupported high-pair staging" (prepare_method_invocations high_binary)
  let plan = MkFilePlan "LIdric/Binary64Fixture;" [negation]
  frozen <- case finalize_file_plan plan of
    Left reason => fail reason
    Right accepted => pure accepted
  check "readable output uses finalized pair placement"
    (isInfixOf "neg-double v0, v0" (render_finalized_smali frozen))
  first <- case encode_finalized_dex frozen of
    Left reason => fail reason
    Right bytes => pure bytes
  second <- case encode_finalized_dex frozen of
    Left reason => fail reason
    Right bytes => pure bytes
  equal "deterministic finalized encoding" first second
  case finalize_file_plan (MkFilePlan "LIdric/Int32Binary64Fixture;" [conversion]) of
    Left reason => fail reason
    Right converted_plan => case encode_finalized_dex converted_plan of
      Left reason => fail reason
      Right bytes => check "staged signed conversion encodes a DEX" (length bytes > 112)
  parsed <- platform_plan "dex:static:Ljava/lang/Double;:parseDouble:(Ljava/lang/String;)D"
    [CFString] CFDouble
  case find_invocation "valueOf" parsed.instructions of
    Nothing => fail "platform Double result was not boxed"
    Just invocation => do
      equal "platform result boxing preserves Double argument"
        [ExistingValue DoubleValue] invocation.method.argument_types
      equal "platform result boxing consumes two words" (Right 2)
        (invocation_argument_words invocation)
  power <- platform_plan "dex:static:Ljava/lang/Math;:pow:(DD)D"
    [CFDouble, CFDouble] CFDouble
  case find_invocation "pow" power.instructions of
    Nothing => fail "platform pow invocation missing"
    Just invocation => do
      equal "platform pow has four argument words" (Right 4)
        (invocation_argument_words invocation)
      equal "platform Double parameters use disjoint pairs"
        (Right [MkRegister 24, MkRegister 25, MkRegister 26, MkRegister 27])
        (invocation_register_words invocation)
  equal "two Double arguments are unboxed independently" 2
    (length (filter (\instruction => case instruction of
      InvokeMethod invocation => invocation.method.name == "doubleValue"
      _ => False) power.instructions))
  case finalize_file_plan (MkFilePlan "LIdric/Binary64PlatformFixture;" [power]) of
    Left reason => fail reason
    Right frozen => do
      check "paired platform call can be finalized"
        (isInfixOf "pow(DD)D" (render_finalized_smali frozen))
      case encode_finalized_dex frozen of
        Left reason => fail reason
        Right bytes => check "paired platform call encodes a DEX" (length bytes > 112)
  putStrLn "PASS binary64 literal, encoder and placement checks"
