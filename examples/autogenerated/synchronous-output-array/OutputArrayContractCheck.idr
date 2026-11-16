module OutputArrayContractCheck

import Backend.DEX.Encode
import Backend.DEX.Heap
import Backend.DEX.IR
import Backend.DEX.Invoke
import Backend.DEX.NativeContract
import Backend.DEX.Placement
import Compiler.ANF
import Core.CompileExpr
import Core.Name
import Data.List
import System

%default covering

fail : String -> IO value
fail reason = do
  putStrLn ("FAIL synchronous output-array contract: " ++ reason)
  exitFailure

check : String -> Bool -> IO ()
check _ True = pure ()
check reason False = fail reason

accept : Either String value -> IO value
accept (Left reason) = fail reason
accept (Right value) = pure value

refuse : String -> Either String value -> IO ()
refuse _ (Left _) = pure ()
refuse reason (Right _) = fail (reason ++ " accepted")

policy : List String
policy = ["current-thread", "synchronous", "borrowed-local", "nonnull-output",
          "publish-output-on-success", "propagate-exceptions"]

row : String -> List String
row descriptor = ["C:render_output,librenderoutput", "renderOutput", descriptor] ++ policy

output_domain : CFType
output_domain = CFUser (UN (Basic "PixelOutput")) []

source_arguments : List CFType
source_arguments = [CFInt64, CFInt32, CFInt32, CFInt32, CFDouble, CFDouble, CFDouble,
                    CFDouble, output_domain, CFWorld]

main : IO ()
main = do
  parsed <- accept (parse_native_boundary_row (row "(JIIIDDDD[I)I"))
  check "distinct output policy" (parsed.declared_contract == SynchronousOutputIntArrayNativeBoundary)
  constraints <- accept (native_source_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type source_arguments (CFIORes CFInt32))
  check "one checked output domain" (constraints == [(UN (Basic "PixelOutput"), MkTypeReference "[I")])
  refuse "two outputs" (parse_native_boundary_row (row "([I[I)I"))
  refuse "wrong output kind" (parse_native_boundary_row (row "(J[D)I"))
  refuse "output not final" (parse_native_boundary_row (row "([ID)I"))
  refuse "array returned" (parse_native_boundary_row (row "([I)[I"))
  refuse "wrong status width" (parse_native_boundary_row (row "([I)J"))
  refuse "missing output" (parse_native_boundary_row (row "(JDD)I"))
  refuse "String argument" (parse_native_boundary_row (row "(Ljava/lang/String;[I)I"))
  refuse "async output" (parse_native_boundary_row
    ["C:x", "x", "([I)I", "current-thread", "asynchronous", "borrowed-local",
      "nonnull-output", "publish-output-on-success", "propagate-exceptions"])
  refuse "retained output" (parse_native_boundary_row
    ["C:x", "x", "([I)I", "current-thread", "synchronous", "retained-global",
      "nonnull-output", "publish-output-on-success", "propagate-exceptions"])
  refuse "output policy cannot be legacy input copy" (parse_native_boundary_row
    ["C:x", "x", "(JIIIDDDD[I)I", "current-thread", "synchronous", "borrowed-local",
      "nonnull-inputs", "copy-input-arrays", "propagate-exceptions"])
  refuse "narrow source handle" (native_source_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type
    (CFInt32 :: drop 1 source_arguments) (CFIORes CFInt32))
  refuse "integer posing as Double" (native_source_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type
    ([CFInt64, CFInt32, CFInt32, CFInt32, CFInt64, CFDouble, CFDouble, CFDouble, output_domain, CFWorld])
    (CFIORes CFInt32))
  refuse "ordinary Text posing as output" (native_source_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type
    ([CFInt64, CFInt32, CFInt32, CFInt32, CFDouble, CFDouble, CFDouble, CFDouble, CFString, CFWorld])
    (CFIORes CFInt32))
  refuse "wrong source result" (native_source_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type source_arguments (CFIORes CFInt64))
  let service = MkJNIService parsed.native_convention parsed.native_method_name
        parsed.native_argument_types parsed.native_result_type parsed.declared_contract
  let source = Make_Administrative_Normal_Form_Foreign_Function [parsed.native_convention]
        source_arguments (CFIORes CFInt32)
  adapter <- accept (heap_foreign_linked [service] "render_adapter" source)
  case filter (\instruction => case instruction of
      InvokeMethod invocation => invocation.method.name == "renderOutput"
      _ => False) adapter.instructions of
    [InvokeMethod invocation] => do
      words <- accept (invocation_argument_words invocation)
      check "J and every D consume two words" (words == 14)
      check "mixed native staging register pairs do not overlap"
        (map show invocation.arguments == ["v24", "v26", "v27", "v28", "v29", "v31", "v33", "v35", "v37"])
    _ => fail "native output invocation missing or duplicated"
  frozen <- accept (finalize_file_plan (MkFilePlan "LIdric/OutputArrayContractFixture;"
    [adapter, heap_native service, heap_exact_number False, heap_exact_number True]))
  bytes <- accept (encode_finalized_dex frozen)
  check "real wrapper finalizes and encodes" (length bytes > 112)
  putStrLn "PASS synchronous Int32 output-array contract and exact scalar widths"
