module Backend.DEX.NativeContract

import Backend.DEX.Foreign
import Backend.DEX.IR
import Backend.DEX.Lower
import Core.CompileExpr
import Core.Name
import Data.List

%default total

||| Legacy maps carry no newly inferred lifetime or nullability guarantee.
||| The explicit contract is a declaration checked at the generated boundary,
||| not a proof that an arbitrary native implementation obeys it.
public export
data NativeBoundaryContract
  = LegacyUnqualifiedNativeBoundary
  | SynchronousBorrowedNonNullNativeBoundary
  | SynchronousCopiedInputArrayNativeBoundary
  | SynchronousOutputIntArrayNativeBoundary

public export
Eq NativeBoundaryContract where
  LegacyUnqualifiedNativeBoundary == LegacyUnqualifiedNativeBoundary = True
  SynchronousBorrowedNonNullNativeBoundary == SynchronousBorrowedNonNullNativeBoundary = True
  SynchronousCopiedInputArrayNativeBoundary == SynchronousCopiedInputArrayNativeBoundary = True
  SynchronousOutputIntArrayNativeBoundary == SynchronousOutputIntArrayNativeBoundary = True
  _ == _ = False

public export
record ParsedNativeBoundary where
  constructor MkParsedNativeBoundary
  native_convention : String
  native_method_name : String
  native_argument_types : List FrameworkValueType
  native_result_type : FrameworkValueType
  declared_contract : NativeBoundaryContract

private
scalar_or_string : FrameworkValueType -> Bool
scalar_or_string (ExistingValue IntegerValue) = True
scalar_or_string LongValue = True
scalar_or_string (ExistingValue TextValue) = True
scalar_or_string _ = False

private
validate_explicit_signature : List FrameworkValueType -> FrameworkValueType -> Either String ()
validate_explicit_signature arguments result =
  if all scalar_or_string arguments && (result == VoidValue || scalar_or_string result)
    then Right ()
    else Left "Explicit JNI contract supports int/long/String arguments and int/long/String/void results; object handles, arrays and callbacks need a separate ownership contract"

public export
copied_input_array : FrameworkValueType -> Bool
copied_input_array (ReferenceValue descriptor) =
  descriptor.descriptor == "[D" || descriptor.descriptor == "[I"
copied_input_array _ = False

private
copy_input_value : FrameworkValueType -> Bool
copy_input_value (ExistingValue IntegerValue) = True
copy_input_value LongValue = True
copy_input_value value = copied_input_array value

private
validate_copy_signature : List FrameworkValueType -> FrameworkValueType -> Either String ()
validate_copy_signature arguments result =
  if any copied_input_array arguments && all copy_input_value arguments &&
     (result == LongValue || result == VoidValue)
    then Right ()
    else Left "Copy-input-array JNI contract requires int/long or nonnull [D/[I inputs, at least one input array, and a long/void result"

private
output_scalar : FrameworkValueType -> Bool
output_scalar (ExistingValue IntegerValue) = True
output_scalar LongValue = True
output_scalar (ExistingValue DoubleValue) = True
output_scalar _ = False

private
validate_output_signature : List FrameworkValueType -> FrameworkValueType -> Either String ()
validate_output_signature arguments result = case reverse arguments of
  ReferenceValue descriptor :: scalars =>
    if descriptor.descriptor == "[I" && all output_scalar scalars && result == ExistingValue IntegerValue
      then Right ()
      else Left "Synchronous output-array JNI contract requires exact int/long/double scalars, one final nonnull [I output, and an int status result"
  _ => Left "Synchronous output-array JNI contract requires one final nonnull [I output"

private
parse_signature : String -> String -> String -> NativeBoundaryContract ->
  Either String ParsedNativeBoundary
parse_signature convention method descriptor contract = do
  name <- validate_method_name method
  (arguments, result) <- parse_method_descriptor descriptor
  case contract of
    LegacyUnqualifiedNativeBoundary =>
      if any copied_input_array arguments || copied_input_array result
        then Left "Legacy JNI maps do not admit array descriptors; declare the explicit synchronous copy-input-array contract"
        else Right ()
    SynchronousBorrowedNonNullNativeBoundary => validate_explicit_signature arguments result
    SynchronousCopiedInputArrayNativeBoundary => validate_copy_signature arguments result
    SynchronousOutputIntArrayNativeBoundary => validate_output_signature arguments result
  Right (MkParsedNativeBoundary convention name arguments result contract)

||| Each complete opt-in policy names its implemented boundary. The scalar
||| contract remains unchanged; copied arrays require the separate six-column
||| policy. Unknown/retained/asynchronous variants are refused rather than guessed.
public export
parse_native_boundary_row : List String -> Either String ParsedNativeBoundary
parse_native_boundary_row [convention, method, descriptor] =
  parse_signature convention method descriptor LegacyUnqualifiedNativeBoundary
parse_native_boundary_row
  [convention, method, descriptor, "current-thread", "synchronous", "borrowed-local",
   "nonnull-strings", "propagate-exceptions"] =
  parse_signature convention method descriptor SynchronousBorrowedNonNullNativeBoundary
parse_native_boundary_row
  [convention, method, descriptor, "current-thread", "synchronous", "borrowed-local",
   "nonnull-inputs", "copy-input-arrays", "propagate-exceptions"] =
  parse_signature convention method descriptor SynchronousCopiedInputArrayNativeBoundary
parse_native_boundary_row
  [convention, method, descriptor, "current-thread", "synchronous", "borrowed-local",
   "nonnull-output", "publish-output-on-success", "propagate-exceptions"] =
  parse_signature convention method descriptor SynchronousOutputIntArrayNativeBoundary
parse_native_boundary_row [_, _, _, _, _, _, _, _, _] =
  Left "Unsupported JNI copy-input-array contract: expected current-thread synchronous borrowed-local nonnull-inputs copy-input-arrays propagate-exceptions; retained/asynchronous references and array outputs are not supported"
parse_native_boundary_row [_, _, _, _, _, _, _, _] =
  Left "Unsupported JNI contract: expected current-thread synchronous borrowed-local nonnull-strings propagate-exceptions; retention, asynchronous calls and callbacks require an implemented ownership contract"
parse_native_boundary_row _ =
  Left "JNI map row requires convention method descriptor, optionally followed by a complete scalar/String or synchronous copy-input-array policy"

public export
native_contract_description : NativeBoundaryContract -> String
native_contract_description LegacyUnqualifiedNativeBoundary =
  "legacy JNI boundary: ownership, thread and nullability unqualified; historical conversions retained"
native_contract_description SynchronousBorrowedNonNullNativeBoundary =
  "declared JNI boundary: calling thread, synchronous, local references borrowed until return, nonnull strings, pending exceptions propagated by ART"
native_contract_description SynchronousCopiedInputArrayNativeBoundary =
  "declared JNI boundary: calling thread, synchronous nonnull [D/[I inputs copied to native ownership before return, borrowed local references never retained, pending exceptions propagated by ART"
native_contract_description SynchronousOutputIntArrayNativeBoundary =
  "declared JNI boundary: calling thread, synchronous exact int/long/double scalars and one nonnull [I output, local reference never retained, native implementation publishes output only on success, pending exceptions propagated by ART"

private
copy_argument_constraint : CFType -> FrameworkValueType -> Either String (List (Name, TypeReference))
copy_argument_constraint CFInt32 (ExistingValue IntegerValue) = Right []
copy_argument_constraint CFInt64 LongValue = Right []
copy_argument_constraint (CFUser name []) target@(ReferenceValue descriptor) =
  if copied_input_array target then Right [(name, descriptor)]
    else Left "JNI copy-input-array reference requires [D or [I"
copy_argument_constraint _ _ = Left "JNI copy-input-array source argument type does not match its descriptor"

private
copy_argument_constraints : List CFType -> List FrameworkValueType ->
  Either String (List (Name, TypeReference))
copy_argument_constraints [] [] = Right []
copy_argument_constraints (source :: sources) (target :: targets) = do
  current <- copy_argument_constraint source target
  more <- copy_argument_constraints sources targets
  Right (current ++ more)
copy_argument_constraints _ _ = Left "JNI copy-input-array source argument count does not match its descriptor"

private
output_argument_constraint : CFType -> FrameworkValueType -> Either String (List (Name, TypeReference))
output_argument_constraint CFInt32 (ExistingValue IntegerValue) = Right []
output_argument_constraint CFInt64 LongValue = Right []
output_argument_constraint CFDouble (ExistingValue DoubleValue) = Right []
output_argument_constraint (CFUser name []) (ReferenceValue descriptor) =
  if descriptor.descriptor == "[I" then Right [(name, descriptor)]
    else Left "JNI output-array source reference requires [I"
output_argument_constraint _ _ = Left "JNI output-array source argument type does not match its descriptor"

private
output_argument_constraints : List CFType -> List FrameworkValueType ->
  Either String (List (Name, TypeReference))
output_argument_constraints [] [] = Right []
output_argument_constraints (source :: sources) (target :: targets) = do
  current <- output_argument_constraint source target
  more <- output_argument_constraints sources targets
  Right (current ++ more)
output_argument_constraints _ _ = Left "JNI output-array source argument count does not match its descriptor"

||| Resolve these constraints together with framework-call domains. Codegen
||| verifies the checked external flag and one consistent descriptor per name;
||| ordinary lists/records cannot claim a primitive array ABI.
public export
native_copy_reference_constraints : NativeBoundaryContract ->
  List FrameworkValueType -> FrameworkValueType -> List CFType -> CFType ->
  Either String (List (Name, TypeReference))
native_copy_reference_constraints SynchronousCopiedInputArrayNativeBoundary targets result sources source_result = do
  ordinary <- case reverse sources of
    CFWorld :: rest => Right (reverse rest)
    _ => Left "JNI copy-input-array requires PrimIO with a trailing World token"
  case (source_result, result) of
    (CFIORes CFInt64, LongValue) => Right ()
    (CFIORes CFUnit, VoidValue) => Right ()
    _ => Left "JNI copy-input-array source result type does not match its descriptor"
  copy_argument_constraints ordinary targets
native_copy_reference_constraints _ _ _ _ _ = Right []

private
scalar_source_matches : CFType -> FrameworkValueType -> Bool
scalar_source_matches CFInt (ExistingValue IntegerValue) = True
scalar_source_matches CFInt LongValue = True
scalar_source_matches CFInt32 (ExistingValue IntegerValue) = True
scalar_source_matches CFInt64 LongValue = True
scalar_source_matches CFString (ExistingValue TextValue) = True
scalar_source_matches CFUnit VoidValue = True
scalar_source_matches _ _ = False

private
scalar_arguments_match : List CFType -> List FrameworkValueType -> Bool
scalar_arguments_match [] [] = True
scalar_arguments_match (source :: sources) (target :: targets) =
  scalar_source_matches source target && scalar_arguments_match sources targets
scalar_arguments_match _ _ = False

||| Fixed-width scalar handles do not acquire a reference lifetime contract.
||| Their checked primitive widths must match exactly; historical unbounded
||| Int conversions remain supported by the existing explicit scalar policy.
public export
native_source_reference_constraints : NativeBoundaryContract ->
  List FrameworkValueType -> FrameworkValueType -> List CFType -> CFType ->
  Either String (List (Name, TypeReference))
native_source_reference_constraints SynchronousBorrowedNonNullNativeBoundary targets result sources source_result = do
  ordinary <- case reverse sources of
    CFWorld :: rest => Right (reverse rest)
    _ => Left "JNI synchronous scalar contract requires PrimIO with a trailing World token"
  if scalar_arguments_match ordinary targets then Right ()
    else Left "JNI synchronous scalar source argument type does not match its descriptor"
  case source_result of
    CFIORes value =>
      if scalar_source_matches value result then Right []
        else Left "JNI synchronous scalar source result type does not match its descriptor"
    _ => Left "JNI synchronous scalar contract requires a checked PrimIO result"
native_source_reference_constraints SynchronousOutputIntArrayNativeBoundary targets result sources source_result = do
  validate_output_signature targets result
  ordinary <- case reverse sources of
    CFWorld :: rest => Right (reverse rest)
    _ => Left "JNI synchronous output-array contract requires PrimIO with a trailing World token"
  case source_result of
    CFIORes CFInt32 => output_argument_constraints ordinary targets
    _ => Left "JNI synchronous output-array source result must be exact Int32"
native_source_reference_constraints contract targets result sources source_result =
  native_copy_reference_constraints contract targets result sources source_result
