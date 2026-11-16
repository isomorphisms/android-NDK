module CopiedArrayContractCheck

-- Compiler fixture uses the checked bootstrap API; the producer is .idric.
import Backend.DEX.Encode
import Backend.DEX.Foreign
import Backend.DEX.Heap
import Backend.DEX.IR
import Backend.DEX.Invoke
import Backend.DEX.ManagedBoundary
import Backend.DEX.NativeContract
import Backend.DEX.Placement
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
  let scalar = SynchronousBorrowedNonNullNativeBoundary
  let typed_release = MkJNIService "C:typed_release,libcopiedarrays" "typedRelease"
        [LongValue] VoidValue scalar
  let release_source = Make_Administrative_Normal_Form_Foreign_Function
        ["C:typed_release,libcopiedarrays"] [CFInt64, CFWorld] (CFIORes CFUnit)
  release <- accept (heap_foreign_linked [typed_release] "typed_release_adapter" release_source)
  case filter (\instruction => case instruction of
         InvokeMethod invocation => invocation.method.name == "typedRelease"
         _ => False) release.instructions of
    [InvokeMethod invocation] => do
      words <- accept (invocation_argument_words invocation)
      check "typed scalar release takes one long pair" (words == 2)
      check "typed scalar release keeps void result" (invocation.method.result == VoidValue)
    _ => fail "typed release invocation missing or duplicated"
  let getter = MkJNIService "C:typed_getter,libcopiedarrays" "typedGetter"
        [LongValue, ExistingValue IntegerValue] LongValue scalar
  let getter_source = Make_Administrative_Normal_Form_Foreign_Function
        ["C:typed_getter,libcopiedarrays"] [CFInt64, CFInt32, CFWorld] (CFIORes CFInt64)
  getter_plan <- accept (heap_foreign_linked [getter] "typed_getter_adapter" getter_source)
  let count = MkJNIService "C:typed_count,libcopiedarrays" "typedCount" [LongValue]
        (ExistingValue IntegerValue) scalar
  let count_source = Make_Administrative_Normal_Form_Foreign_Function
        ["C:typed_count,libcopiedarrays"] [CFInt64, CFWorld] (CFIORes CFInt32)
  count_plan <- accept (heap_foreign_linked [count] "typed_count_adapter" count_source)
  refuse "Int32 source cannot pass long argument"
    (native_source_reference_constraints scalar [LongValue] VoidValue
      [CFInt32, CFWorld] (CFIORes CFUnit))
  refuse "Int64 source cannot pass int argument"
    (native_source_reference_constraints scalar [ExistingValue IntegerValue] VoidValue
      [CFInt64, CFWorld] (CFIORes CFUnit))
  refuse "Int32 source cannot receive long result"
    (native_source_reference_constraints scalar [] LongValue [CFWorld] (CFIORes CFInt32))
  refuse "Int64 source cannot receive int result"
    (native_source_reference_constraints scalar [] (ExistingValue IntegerValue)
      [CFWorld] (CFIORes CFInt64))
  refuse "legacy policy does not gain fixed-width declarations"
    (heap_foreign_linked [{ boundary_contract := LegacyUnqualifiedNativeBoundary } typed_release]
      "legacy_typed_release" release_source)
  typed_frozen <- accept (finalize_file_plan (MkFilePlan "LIdric/TypedScalarContractFixture;"
    [release, getter_plan, count_plan, heap_native typed_release, heap_native getter,
     heap_native count, heap_exact_number False, heap_exact_number True]))
  typed_bytes <- accept (encode_finalized_dex typed_frozen)
  check "typed scalar adapters finalize and encode" (length typed_bytes > 112)
  identity_bridge <- accept (managed_export_bridge PureForeign "identity_long" "checked_long"
    [LongValue] LongValue)
  check "Int64 export argument remains a long pair"
    (identity_bridge.parameter_types == [LongValue] && identity_bridge.result_type == LongValue &&
     identity_bridge.register_count == 66)
  mixed_bridge <- accept (managed_export_bridge PureForeign "mixed_long" "checked_mixed"
    [LongValue, ExistingValue IntegerValue] LongValue)
  placed_mixed <- accept (prepare_method_invocations mixed_bridge)
  check "mixed export counts three incoming words"
    (placed_mixed.register_count == 74)
  check "mixed export keeps long and int incoming families"
    (map show (take 2 placed_mixed.instructions) == ["move-wide v66, v71", "move v68, v73"])
  reverse_bridge <- accept (managed_export_bridge PrimitiveIOForeign "mixed_io_long" "checked_mixed_io"
    [ExistingValue IntegerValue, LongValue] LongValue)
  placed_reverse <- accept (prepare_method_invocations reverse_bridge)
  check "IO mixed export preserves long pair after narrow input"
    (placed_reverse.register_count == 75 &&
     map show (take 2 placed_reverse.instructions) == ["move v66, v72", "move-wide v67, v73"])
  wide_frozen <- accept (finalize_file_plan (MkFilePlan "LIdric/Int64ExportFixture;"
    [identity_bridge, mixed_bridge, reverse_bridge, heap_exact_number True]))
  wide_bytes <- accept (encode_finalized_dex wide_frozen)
  check "wide source export bridges finalize and encode" (length wide_bytes > 112)
  putStrLn "PASS typed copied-array JNI contracts and preserved refusals"
