module Backend.DEX.Foreign

import Backend.DEX.IR
import Compiler.ANF
import Core.CompileExpr
import Data.List
import Data.String

%default total

public export
data ForeignEffect
  = PureForeign
  | PrimitiveIOForeign

public export
Eq ForeignEffect where
  PureForeign == PureForeign = True
  PrimitiveIOForeign == PrimitiveIOForeign = True
  _ == _ = False

public export
record DEXForeign where
  constructor MkDEXForeign
  effect : ForeignEffect
  invocation_kind : InvokeKind
  method : MethodReference

private
starts_with : List Char -> List Char -> Bool
starts_with [] value = True
starts_with (wanted :: more) [] = False
starts_with (wanted :: more) (actual :: rest) =
  wanted == actual && starts_with more rest

private
drop_prefix : List Char -> List Char -> Maybe (List Char)
drop_prefix prefix value =
  if starts_with prefix value
    then Just (drop (length prefix) value)
    else Nothing

private
split_once : Char -> List Char -> Maybe (List Char, List Char)
split_once delimiter = go []
  where
    go : List Char -> List Char -> Maybe (List Char, List Char)
    go prefix [] = Nothing
    go prefix (character :: rest) =
      if character == delimiter
        then Just (reverse prefix, rest)
        else go (character :: prefix) rest

private
take_reference_descriptor :
  List Char -> Maybe (List Char, List Char)
take_reference_descriptor = go ['L']
  where
    go : List Char -> List Char -> Maybe (List Char, List Char)
    go prefix [] = Nothing
    go prefix (';' :: rest) = Just (reverse (';' :: prefix), rest)
    go prefix (character :: rest) = go (character :: prefix) rest

private
reference_type : List Char -> FrameworkValueType
reference_type descriptor =
  let text = pack descriptor in
  if text == "Ljava/lang/String;"
    then ExistingValue TextValue
    else if text == "Ljava/lang/Object;"
      then ExistingValue ObjectValue
      else ReferenceValue (MkTypeReference text)

private
parse_type :
  (allow_void : Bool) -> List Char ->
  Either String (FrameworkValueType, List Char)
parse_type allow_void [] = Left "DEX descriptor ended before a value type"
parse_type allow_void ('I' :: rest) =
  Right (ExistingValue IntegerValue, rest)
parse_type allow_void ('Z' :: rest) =
  Right (ExistingValue BooleanValue, rest)
parse_type allow_void ('J' :: rest) =
  Right (LongValue, rest)
parse_type True ('V' :: rest) =
  Right (VoidValue, rest)
parse_type False ('V' :: rest) =
  Left "DEX void is not valid as a method parameter"
parse_type allow_void all@('L' :: rest) =
  case take_reference_descriptor rest of
    Nothing => Left "Unclosed DEX reference descriptor"
    Just (descriptor, after) =>
      if descriptor == ['L', ';']
        then Left "Empty DEX reference descriptor"
        else Right (reference_type descriptor, after)
parse_type allow_void ('[' :: rest) =
  Left "DEX array descriptors are not in the first Binder foreign-call slice"
parse_type allow_void (character :: rest) =
  Left ("Unsupported DEX descriptor type " ++ show character)

private
parse_parameters :
  List Char -> List FrameworkValueType ->
  Either String (List FrameworkValueType, List Char)
parse_parameters [] reversed =
  Left "DEX method descriptor has no closing ')'"
parse_parameters (')' :: rest) reversed =
  Right (reverse reversed, rest)
parse_parameters chars reversed = do
  (value, rest) <- parse_type False chars
  parse_parameters rest (value :: reversed)

private
parse_method_descriptor :
  String -> Either String (List FrameworkValueType, FrameworkValueType)
parse_method_descriptor descriptor =
  case unpack descriptor of
    '(' :: rest => do
      (parameters, after_parameters) <- parse_parameters rest []
      (result, trailing) <- parse_type True after_parameters
      if null trailing
        then Right (parameters, result)
        else Left "Trailing characters after DEX method descriptor"
    _ => Left "DEX method descriptor must begin with '('"

private
parse_invoke_kind : String -> Either String InvokeKind
parse_invoke_kind "static" = Right InvokeStatic
parse_invoke_kind "virtual" = Right InvokeVirtual
parse_invoke_kind "interface" = Right InvokeInterface
parse_invoke_kind other =
  Left ("Unsupported dex foreign invocation kind " ++ show other)

private
parse_fields :
  List Char -> Either String (InvokeKind, TypeReference, String, String)
parse_fields chars = do
  (kind_chars, after_kind) <-
    maybe (Left "Missing dex foreign owner") Right (split_once ':' chars)
  (owner_chars, after_owner) <-
    maybe (Left "Missing dex foreign method name") Right
      (split_once ':' after_kind)
  (name_chars, descriptor_chars) <-
    maybe (Left "Missing dex foreign method descriptor") Right
      (split_once ':' after_owner)
  kind <- parse_invoke_kind (pack kind_chars)
  if null owner_chars
    then Left "Empty dex foreign owner descriptor"
    else Right ()
  if null name_chars
    then Left "Empty dex foreign method name"
    else Right ()
  Right
    ( kind
    , MkTypeReference (pack owner_chars)
    , pack name_chars
    , pack descriptor_chars
    )

private
reference_source_type : CFType -> Bool
reference_source_type (CFUser name arguments) = True
reference_source_type CFForeignObj = True
reference_source_type _ = False

private
source_matches_target : CFType -> FrameworkValueType -> Bool
source_matches_target CFInt32 (ExistingValue IntegerValue) = True
source_matches_target CFInt32 (ExistingValue BooleanValue) = True
source_matches_target CFInt64 LongValue = True
source_matches_target CFString (ExistingValue TextValue) = True
source_matches_target source (ReferenceValue reference) =
  reference_source_type source
source_matches_target source (ExistingValue ObjectValue) =
  reference_source_type source
source_matches_target CFUnit VoidValue = True
source_matches_target _ _ = False

private
drop_last_world :
  List CFType -> Either String (List CFType)
drop_last_world arguments =
  case reverse arguments of
    CFWorld :: rest => Right (reverse rest)
    _ =>
      Left "PrimIO dex foreign declaration is missing its trailing World argument"

private
normalise_signature :
  List CFType -> CFType ->
  Either String (ForeignEffect, List CFType, CFType)
normalise_signature arguments (CFIORes result) = do
  ordinary <- drop_last_world arguments
  Right (PrimitiveIOForeign, ordinary, result)
normalise_signature arguments result =
  Right (PureForeign, arguments, result)

private
target_argument_types :
  InvokeKind -> MethodReference -> List FrameworkValueType
target_argument_types InvokeStatic method = method.parameters
target_argument_types InvokeVirtual method =
  ReferenceValue method.owner :: method.parameters
target_argument_types InvokeInterface method =
  ReferenceValue method.owner :: method.parameters

private
signatures_match :
  List CFType -> List FrameworkValueType -> Bool
signatures_match [] [] = True
signatures_match (source :: sources) (target :: targets) =
  source_matches_target source target && signatures_match sources targets
signatures_match _ _ = False

private
validate_signature :
  InvokeKind -> MethodReference -> List CFType -> CFType ->
  Either String ForeignEffect
validate_signature kind method source_arguments source_result = do
  (effect, ordinary_arguments, ordinary_result) <-
    normalise_signature source_arguments source_result
  let expected_arguments = target_argument_types kind method
  if signatures_match ordinary_arguments expected_arguments
    then Right ()
    else
      Left
        ("dex foreign argument types do not match " ++ show method)
  if source_matches_target ordinary_result method.result
    then Right effect
    else
      Left
        ("dex foreign result type does not match " ++ show method)

||| Parse and type-check one backend-specific calling convention:
|||
||| dex:<static|virtual|interface>:<owner-descriptor>:<name>:<method-descriptor>
|||
||| Example:
||| dex:static:Landroid/os/Binder;:getCallingUid:()I
public export
parse_dex_foreign :
  String -> List CFType -> CFType -> Either String DEXForeign
parse_dex_foreign convention source_arguments source_result = do
  body <-
    case drop_prefix (unpack "dex:") (unpack convention) of
      Nothing => Left "Foreign convention is not for the dex backend"
      Just value => Right value
  (kind, owner, name, descriptor) <- parse_fields body
  (parameters, result) <- parse_method_descriptor descriptor
  let method = MkMethodReference owner name parameters result
  effect <- validate_signature kind method source_arguments source_result
  Right (MkDEXForeign effect kind method)

private
is_dex_convention : String -> Bool
is_dex_convention convention =
  starts_with (unpack "dex:") (unpack convention)

private
select_dex_convention :
  List String -> Either String (Maybe String)
select_dex_convention conventions =
  case filter is_dex_convention conventions of
    [] => Right Nothing
    [found] => Right (Just found)
    _ => Left "Foreign declaration has more than one dex convention"

public export
foreign_from_definition :
  Administrative_Normal_Form_Definition ->
  Either String (Maybe DEXForeign)
foreign_from_definition
  (Make_Administrative_Normal_Form_Foreign_Function conventions arguments result) = do
    selected <- select_dex_convention conventions
    case selected of
      Nothing => Right Nothing
      Just convention =>
        Just <$> parse_dex_foreign convention arguments result
foreign_from_definition definition = Right Nothing
