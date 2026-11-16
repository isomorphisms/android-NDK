module CopiedArrayContractCheck

-- Compiler fixture uses the checked bootstrap API; the producer is .idric.
import Backend.DEX.Encode
import Backend.DEX.Foreign
import Backend.DEX.Heap
import Backend.DEX.IR
import Backend.DEX.Invoke
import Backend.DEX.NativeContract
import Compiler.ANF
import Core.CompileExpr
import Core.Name
import Data.List
import System

%default covering

fail : String -> IO value
fail message = do
  putStrLn ("FAIL copied array contract: " ++ message)
  exitFailure

check : String -> Bool -> IO ()
check _ True = pure ()
check message False = fail message

accept : Either String value -> IO value
accept (Left reason) = fail reason
accept (Right value) = pure value

refuse : String -> Either String value -> IO ()
refuse _ (Left _) = pure ()
refuse message (Right _) = fail (message ++ " accepted")

policy : List String
policy = ["current-thread", "synchronous", "borrowed-local", "nonnull-inputs",
          "copy-input-arrays", "propagate-exceptions"]

row : List String
row = ["C:copied_surface,libcopiedarrays", "copySurface", "(IIIIIII[D[I)J"]

coefficient_domain : CFType
coefficient_domain = CFUser (UN (Basic "CoefficientArray")) []

exponent_domain : CFType
exponent_domain = CFUser (UN (Basic "ExponentArray")) []

source_arguments : List CFType
source_arguments = replicate 7 CFInt32 ++ [coefficient_domain, exponent_domain, CFWorld]

source : Administrative_Normal_Form_Definition
source = Make_Administrative_Normal_Form_Foreign_Function
  ["C:copied_surface,libcopiedarrays"] source_arguments (CFIORes CFInt64)

is_null_check : Instruction -> Bool
is_null_check (InvokeMethod invocation) = invocation.method.name == "requireNonNull"
is_null_check _ = False

is_array_cast : Instruction -> Bool
is_array_cast (CheckCast _ descriptor) = descriptor.descriptor == "[D" || descriptor.descriptor == "[I"
is_array_cast _ = False

main : IO ()
main = do
  parsed <- accept (parse_native_boundary_row (row ++ policy))
  check "explicit new policy" (parsed.declared_contract == SynchronousCopiedInputArrayNativeBoundary)
  constraints <- accept (native_copy_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type source_arguments (CFIORes CFInt64))
  check "separate typed array constraints"
    (constraints == [(UN (Basic "CoefficientArray"), MkTypeReference "[D"),
                     (UN (Basic "ExponentArray"), MkTypeReference "[I")])
  refuse "legacy scalar contract arrays" (parse_native_boundary_row
    (row ++ ["current-thread", "synchronous", "borrowed-local", "nonnull-strings", "propagate-exceptions"]))
  refuse "unqualified legacy array declaration" (parse_native_boundary_row row)
  refuse "retained copied arrays" (parse_native_boundary_row
    (row ++ ["current-thread", "synchronous", "retained-global", "nonnull-inputs", "copy-input-arrays", "propagate-exceptions"]))
  refuse "asynchronous copied arrays" (parse_native_boundary_row
    (row ++ ["current-thread", "asynchronous", "borrowed-local", "nonnull-inputs", "copy-input-arrays", "propagate-exceptions"]))
  refuse "array output" (parse_native_boundary_row
    (["C:x", "x", "([I)[I"] ++ policy))
  refuse "unowned object input" (parse_native_boundary_row
    (["C:x", "x", "([ILjava/lang/Object;)J"] ++ policy))
  refuse "missing input array" (parse_native_boundary_row
    (["C:x", "x", "(I)J"] ++ policy))
  refuse "source scalar width mismatch" (native_copy_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type
    (CFInt64 :: drop 1 source_arguments) (CFIORes CFInt64))
  refuse "source result width mismatch" (native_copy_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type source_arguments (CFIORes CFInt32))
  refuse "ordinary Text posing as array" (native_copy_reference_constraints parsed.declared_contract
    parsed.native_argument_types parsed.native_result_type
    (replicate 7 CFInt32 ++ [CFString, exponent_domain, CFWorld]) (CFIORes CFInt64))
  let service = MkJNIService parsed.native_convention parsed.native_method_name
        parsed.native_argument_types parsed.native_result_type parsed.declared_contract
  adapter <- accept (heap_foreign_linked [service] "copy_adapter" source)
  check "both arrays nonnull before native" (length (filter is_null_check adapter.instructions) == 2)
  check "both arrays checked before and after nonnull call" (length (filter is_array_cast adapter.instructions) == 4)
  case filter (\instruction => case instruction of
         InvokeMethod invocation => invocation.method.name == "copySurface"
         _ => False) adapter.instructions of
    [InvokeMethod invocation] => do
      words <- accept (invocation_argument_words invocation)
      check "seven narrow scalars and two reference words" (words == 9)
      check "native handle stays long" (invocation.method.result == LongValue)
    _ => fail "native call missing or duplicated"
  let legacy = { boundary_contract := LegacyUnqualifiedNativeBoundary } service
  refuse "legacy arrays stay unsupported" (heap_foreign_linked [legacy] "legacy_copy" source)
  frozen <- accept (finalize_file_plan (MkFilePlan "LIdric/CopiedArrayContractFixture;"
    [adapter, heap_native service, heap_exact_number False, heap_exact_number True]))
  bytes <- accept (encode_finalized_dex frozen)
  check "checked bridge finalizes and encodes" (length bytes > 112)
  putStrLn "PASS typed copied-array JNI contracts and preserved refusals"
