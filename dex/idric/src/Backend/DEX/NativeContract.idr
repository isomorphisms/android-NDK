module Backend.DEX.NativeContract

import Backend.DEX.Foreign
import Backend.DEX.IR
import Backend.DEX.Lower
import Data.List

%default total

||| Legacy maps carry no newly inferred lifetime or nullability guarantee.
||| The explicit contract is a declaration checked at the generated boundary,
||| not a proof that an arbitrary native implementation obeys it.
public export
data NativeBoundaryContract
  = LegacyUnqualifiedNativeBoundary
  | SynchronousBorrowedNonNullNativeBoundary

public export
Eq NativeBoundaryContract where
  LegacyUnqualifiedNativeBoundary == LegacyUnqualifiedNativeBoundary = True
  SynchronousBorrowedNonNullNativeBoundary == SynchronousBorrowedNonNullNativeBoundary = True
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

private
parse_signature : String -> String -> String -> NativeBoundaryContract ->
  Either String ParsedNativeBoundary
parse_signature convention method descriptor contract = do
  name <- validate_method_name method
  (arguments, result) <- parse_method_descriptor descriptor
  case contract of
    LegacyUnqualifiedNativeBoundary => Right ()
    SynchronousBorrowedNonNullNativeBoundary => validate_explicit_signature arguments result
  Right (MkParsedNativeBoundary convention name arguments result contract)

||| The optional five policy columns are deliberately one supported contract.
||| Unknown/retained/asynchronous variants are refused rather than guessed.
public export
parse_native_boundary_row : List String -> Either String ParsedNativeBoundary
parse_native_boundary_row [convention, method, descriptor] =
  parse_signature convention method descriptor LegacyUnqualifiedNativeBoundary
parse_native_boundary_row
  [convention, method, descriptor, "current-thread", "synchronous", "borrowed-local",
   "nonnull-strings", "propagate-exceptions"] =
  parse_signature convention method descriptor SynchronousBorrowedNonNullNativeBoundary
parse_native_boundary_row [_, _, _, _, _, _, _, _] =
  Left "Unsupported JNI contract: expected current-thread synchronous borrowed-local nonnull-strings propagate-exceptions; retention, asynchronous calls and callbacks require an implemented ownership contract"
parse_native_boundary_row _ =
  Left "JNI map row requires convention method descriptor, optionally followed by current-thread synchronous borrowed-local nonnull-strings propagate-exceptions"

public export
native_contract_description : NativeBoundaryContract -> String
native_contract_description LegacyUnqualifiedNativeBoundary =
  "legacy JNI boundary: ownership, thread and nullability unqualified; historical conversions retained"
native_contract_description SynchronousBorrowedNonNullNativeBoundary =
  "declared JNI boundary: calling thread, synchronous, local references borrowed until return, nonnull strings, pending exceptions propagated by ART"
