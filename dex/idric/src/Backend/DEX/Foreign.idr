module Backend.DEX.Foreign

import Backend.DEX.IR
import Compiler.ANF
import Core.CompileExpr
import Core.Name
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
  source_argument_types : List CFType
  source_result_type : CFType
  construction : Maybe TypeReference

private
starts_with : List Char -> List Char -> Bool
starts_with [] value = True
starts_with (wanted :: more) [] = False
starts_with (wanted :: more) (actual :: rest) =
  wanted == actual && starts_with more rest

private
drop_prefix : List Char -> List Char -> Maybe (List Char)
drop_prefix beginning value =
  if starts_with beginning value
    then Just (drop (length beginning) value)
    else Nothing

private
split_once : Char -> List Char -> Maybe (List Char, List Char)
split_once delimiter = go []
  where
    go : List Char -> List Char -> Maybe (List Char, List Char)
    go beginning [] = Nothing
    go beginning (character :: rest) =
      if character == delimiter
        then Just (reverse beginning, rest)
        else go (character :: beginning) rest

private
take_reference_descriptor :
  List Char -> Maybe (List Char, List Char)
take_reference_descriptor = go ['L']
  where
    go : List Char -> List Char -> Maybe (List Char, List Char)
    go beginning [] = Nothing
    go beginning (';' :: rest) = Just (reverse (';' :: beginning), rest)
    go beginning (character :: rest) = go (character :: beginning) rest

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
supported_name_character : Char -> Bool
supported_name_character character =
  (character >= 'A' && character <= 'Z') ||
  (character >= 'a' && character <= 'z') ||
  (character >= '0' && character <= '9') ||
  character == '_' || character == '$'

private
valid_class_path : List Char -> Bool
valid_class_path = segment False
  where
    segment : Bool -> List Char -> Bool
    segment nonempty [] = nonempty
    segment False ('/' :: rest) = False
    segment True ('/' :: rest) = segment False rest
    segment nonempty (character :: rest) =
      supported_name_character character && segment True rest

||| The current encoder admits ASCII class names. Check every foreign object
||| descriptor, not just the declaring owner, before constructing target types.
public export
validate_reference_descriptor : String -> Either String ()
validate_reference_descriptor descriptor =
  case unpack descriptor of
    'L' :: rest =>
      case reverse rest of
        ';' :: reversed_path =>
          if valid_class_path (reverse reversed_path)
            then Right ()
            else Left ("Unsupported DEX reference descriptor `" ++ descriptor ++ "`")
        _ => Left ("Invalid DEX reference descriptor `" ++ descriptor ++ "`")
    _ => Left ("Invalid DEX reference descriptor `" ++ descriptor ++ "`")

private
validate_foreign_method_name : InvokeKind -> String -> Either String ()
validate_foreign_method_name InvokeDirect "<init>" = Right ()
validate_foreign_method_name InvokeDirect name =
  Left "DEX construction requires the <init> method"
validate_foreign_method_name kind name =
  if name == "<init>" || name == "<clinit>"
    then Left "DEX static/virtual/interface foreign calls cannot name a constructor or class initializer"
    else if not (null (unpack name)) && all supported_name_character (unpack name)
      then Right ()
      else Left ("Unsupported DEX foreign method name `" ++ name ++ "`")

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
    Just (descriptor, after) => do
      validate_reference_descriptor (pack descriptor)
      Right (reference_type descriptor, after)
parse_type allow_void ('[' :: rest) =
  Left "DEX array descriptors are outside the checked foreign-call slice"
parse_type allow_void (character :: rest) =
  Left ("Unsupported DEX descriptor type " ++ show character)

private
parse_parameters :
  Nat -> List Char -> List FrameworkValueType ->
  Either String (List FrameworkValueType, List Char)
parse_parameters fuel [] reversed =
  Left "DEX method descriptor has no closing ')'"
parse_parameters fuel (')' :: rest) reversed =
  Right (reverse reversed, rest)
parse_parameters Z chars reversed =
  Left "DEX descriptor parser exhausted its input-length bound"
parse_parameters (S fuel) chars reversed = do
  (value, rest) <- parse_type False chars
  parse_parameters fuel rest (value :: reversed)

public export
parse_method_descriptor :
  String -> Either String (List FrameworkValueType, FrameworkValueType)
parse_method_descriptor descriptor =
  case unpack descriptor of
    '(' :: rest => do
      (argument_types, after_parameters) <- parse_parameters (length rest) rest []
      (result, trailing) <- parse_type True after_parameters
      if null trailing
        then Right (argument_types, result)
        else Left "Trailing characters after DEX method descriptor"
    _ => Left "DEX method descriptor must begin with '('"

private
parse_invoke_kind : String -> Either String InvokeKind
parse_invoke_kind "static" = Right InvokeStatic
parse_invoke_kind "virtual" = Right InvokeVirtual
parse_invoke_kind "interface" = Right InvokeInterface
parse_invoke_kind "construct" = Right InvokeDirect
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
  validate_reference_descriptor (pack owner_chars)
  validate_foreign_method_name kind (pack name_chars)
  Right
    ( kind
    , MkTypeReference (pack owner_chars)
    , pack name_chars
    , pack descriptor_chars
    )

private
reference_source_type : CFType -> Bool
reference_source_type (CFUser name []) = True
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

public export
target_argument_types :
  InvokeKind -> MethodReference -> List FrameworkValueType
target_argument_types InvokeStatic method = method.argument_types
target_argument_types InvokeVirtual method =
  reference_type (unpack method.owner.descriptor) :: method.argument_types
target_argument_types InvokeInterface method =
  reference_type (unpack method.owner.descriptor) :: method.argument_types
target_argument_types InvokeDirect method =
  reference_type (unpack method.owner.descriptor) :: method.argument_types
target_argument_types InvokeSuper method =
  reference_type (unpack method.owner.descriptor) :: method.argument_types

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
  let expected_arguments = if kind == InvokeDirect then method.argument_types
                             else target_argument_types kind method
  if signatures_match ordinary_arguments expected_arguments
    then Right ()
    else
      Left
        ("dex foreign argument types do not match " ++ show method)
  if kind == InvokeDirect && (method.result /= VoidValue || effect /= PrimitiveIOForeign)
    then Left "DEX construction requires PrimIO and a void JVM constructor result"
    else Right ()
  let expected_result = if kind == InvokeDirect then ReferenceValue method.owner
                          else method.result
  if source_matches_target ordinary_result expected_result
    then Right effect
    else
      Left
        ("dex foreign result type does not match " ++ show method)

||| Parse and type-check one backend-specific calling convention:
|||
||| dex:<static|virtual|interface>:<owner-descriptor>:<name>:<method-descriptor>
|||
||| dex:construct:<owner-descriptor>:<init>:(<arguments>)V allocates its own
||| receiver. The source declaration must return an opaque owner through PrimIO.
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
  (argument_types, result) <- parse_method_descriptor descriptor
  let method = MkMethodReference owner name argument_types result
  effect <- validate_signature kind method source_arguments source_result
  (_, ordinary_arguments, ordinary_result) <-
    normalise_signature source_arguments source_result
  Right (MkDEXForeign effect kind method ordinary_arguments ordinary_result
           (if kind == InvokeDirect then Just owner else Nothing))

||| Constructor parameters exclude the receiver allocated by the backend.
public export
foreign_argument_types : DEXForeign -> List FrameworkValueType
foreign_argument_types foreign = case foreign.construction of
  Just owner => foreign.method.argument_types
  Nothing => target_argument_types foreign.invocation_kind foreign.method

public export
foreign_result_type : DEXForeign -> FrameworkValueType
foreign_result_type foreign = case foreign.construction of
  Just owner => ReferenceValue owner
  Nothing => foreign.method.result

private
reference_constraint :
  CFType -> FrameworkValueType -> Either String (List (Name, TypeReference))
reference_constraint (CFUser name []) (ReferenceValue descriptor) =
  Right [(name, descriptor)]
reference_constraint (CFUser name []) (ExistingValue ObjectValue) =
  Right [(name, MkTypeReference "Ljava/lang/Object;")]
reference_constraint source (ReferenceValue descriptor) =
  Left "DEX reference requires a concrete external source domain"
reference_constraint source (ExistingValue ObjectValue) =
  Left "DEX Object requires a concrete external source domain"
reference_constraint _ _ = Right []

private
argument_constraints :
  List CFType -> List FrameworkValueType ->
  Either String (List (Name, TypeReference))
argument_constraints [] [] = Right []
argument_constraints (source :: sources) (target :: targets) = do
  current <- reference_constraint source target
  more <- argument_constraints sources targets
  Right (current ++ more)
argument_constraints _ _ = Left "Internal DEX foreign argument metadata mismatch"

||| Constraints are not proof that a CFUser is opaque. Codegen must look up
||| every source name and verify its checked TCon external flag, then reject
||| any source domain associated with incompatible target descriptors.
public export
foreign_reference_constraints :
  DEXForeign -> Either String (List (Name, TypeReference))
foreign_reference_constraints foreign = do
  arguments <- argument_constraints foreign.source_argument_types
    (foreign_argument_types foreign)
  result <- reference_constraint foreign.source_result_type (foreign_result_type foreign)
  Right (arguments ++ result)

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
