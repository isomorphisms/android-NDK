module Backend.DEX.Codegen

import Backend.DEX.Encode
import Backend.DEX.Foreign
import Backend.DEX.IR
import Backend.DEX.Lower
import Backend.DEX.Smali
import Compiler.ANF
import Compiler.Common
import Core.Context
import Core.Env
import Core.Name.Namespace
import Core.Normalise
import Core.TT
import Idris.Syntax
import Libraries.Utils.Path

%default covering

public export
backend_name : String
backend_name = "dex"

private
record ExportABI where
  constructor MkExportABI
  internal_name : Name
  method_name : String
  parameter_types : List FrameworkValueType
  result_type : FrameworkValueType
  effect : ForeignEffect

private
is_named_type : Name -> String -> String -> Bool
is_named_type name module_name basic =
  name == NS (mkNamespace module_name) (UN (Basic basic))

private
classify_value_type :
  List (Name, TypeReference) -> Term variables -> Either String FrameworkValueType
classify_value_type references (PrimVal _ (PrT Int32Type)) =
  Right (ExistingValue IntegerValue)
classify_value_type references (PrimVal _ (PrT StringType)) =
  Right (ExistingValue TextValue)
classify_value_type references (Ref _ (TyCon _) name) =
  if is_named_type name "Builtin" "Unit"
    then Right VoidValue
    else if is_named_type name "Prelude.Basics" "Bool"
      then Right (ExistingValue BooleanValue)
      else case lookup name references of
        Just descriptor => Right (ReferenceValue descriptor)
        Nothing =>
          Left ("source domain `" ++ show name ++
                "` has no validated external DEX descriptor")
classify_value_type references (PrimVal _ (PrT primitive_type)) =
  Left ("unsupported source primitive type `" ++ show primitive_type ++ "`")
classify_value_type references type =
  Left "unsupported applied or dependent source value type"

private
parse_source_signature :
  List (Name, TypeReference) -> Term variables ->
  Either String (List FrameworkValueType, FrameworkValueType, ForeignEffect)
parse_source_signature references
  (Bind _ world_name (Pi _ _ Explicit (PrimVal _ (PrT WorldType)))
    (App _ (Ref _ (TyCon _) result_name) result_type)) =
  if is_named_type result_name "PrimIO" "IORes"
    then do
      value_type <- classify_value_type references result_type
      Right ([], value_type, PrimitiveIOForeign)
    else Left "A DEX World parameter must be the trailing PrimIO World token"
parse_source_signature references
  (Bind _ argument_name (Pi _ multiplicity Explicit argument_type) scope) = do
    if isErased multiplicity
      then
        Left
          ("erased argument `" ++ show argument_name ++
           "` cannot be a DEX method parameter")
      else do
        argument_value_type <- classify_value_type references argument_type
        if argument_value_type == VoidValue
          then Left "Unit is not an ordinary DEX method parameter"
          else Right ()
        (remaining, result_type, effect) <- parse_source_signature references scope
        Right (argument_value_type :: remaining, result_type, effect)
parse_source_signature references (Bind _ argument_name (Pi _ _ _ argument_type) scope) =
  Left
    ("implicit argument `" ++ show argument_name ++
     "` is not supported at the DEX method boundary")
parse_source_signature references (App _ (Ref _ (TyCon _) name) result_type) =
  if is_named_type name "PrimIO" "IO"
    then do
      value_type <- classify_value_type references result_type
      Right ([], value_type, PrimitiveIOForeign)
    else Left ("unsupported applied source type `" ++ show name ++ "`")
parse_source_signature references result_type = do
  value_type <- classify_value_type references result_type
  Right ([], value_type, PureForeign)

private
resolve_export_abi :
  {auto c : Ref Ctxt Defs} ->
  List (Name, TypeReference) -> (Name, String) -> Core ExportABI
resolve_export_abi references (internal_name, method_name) = do
  definitions <- get Ctxt
  source_type <-
    case !(lookupTyExact internal_name (gamma definitions)) of
      Nothing =>
        throw
          (UserError
            ("Could not find source type of DEX export `" ++
             show internal_name ++ "`"))
      Just found => pure found
  normalised_type <- normalise definitions Env.empty source_type
  full_type <- toFullNames normalised_type
  case parse_source_signature references full_type of
    Left explanation =>
      throw
        (UserError
          ("dex rejected source ABI for `" ++ show internal_name ++
           "`: " ++ explanation ++
           ". DEX exports admit explicit Int32/Text/Bool or validated opaque " ++
           "references, with pure, IO, or PrimIO results; Unit is a void result."))
    Right (parameter_types, result_type, effect) =>
      case validate_method_name method_name of
        Left explanation => throw (UserError explanation)
        Right accepted =>
          pure (MkExportABI internal_name accepted parameter_types result_type effect)

private
lookup_anf_definition :
  Name ->
  List (Name, Administrative_Normal_Form_Definition) ->
  Maybe Administrative_Normal_Form_Definition
lookup_anf_definition requested [] = Nothing
lookup_anf_definition requested ((name, definition) :: rest) =
  if requested == name then Just definition else lookup_anf_definition requested rest

private
collect_dex_foreigns :
  List (Name, Administrative_Normal_Form_Definition) ->
  Either String (List (Name, DEXForeign))
collect_dex_foreigns [] = Right []
collect_dex_foreigns ((name, definition) :: rest) = do
  maybe_foreign <- foreign_from_definition definition
  more <- collect_dex_foreigns rest
  case maybe_foreign of
    Nothing => Right more
    Just foreign => Right ((name, foreign) :: more)

private
validate_external_domains :
  {auto c : Ref Ctxt Defs} ->
  List (Name, TypeReference) -> List (Name, TypeReference) ->
  Core (List (Name, TypeReference))
validate_external_domains [] accepted = pure accepted
validate_external_domains ((name, descriptor) :: rest) accepted = do
  definitions <- get Ctxt
  case !(lookupDefExact name (gamma definitions)) of
    Just (TCon Z _ _ flags _ _ _) =>
      if flags.external
        then pure ()
        else throw (UserError ("dex foreign domain `" ++ show name ++
                     "` is ordinary algebraic data, not an external reference"))
    _ => throw (UserError ("dex foreign domain `" ++ show name ++
                 "` is not a concrete checked external type"))
  case lookup name accepted of
    Just earlier =>
      if earlier == descriptor
        then validate_external_domains rest accepted
        else throw (UserError ("dex external domain `" ++ show name ++
                     "` has conflicting descriptors " ++ show earlier ++
                     " and " ++ show descriptor))
    Nothing => validate_external_domains rest ((name, descriptor) :: accepted)

private
resolve_external_domains :
  {auto c : Ref Ctxt Defs} ->
  List (Name, DEXForeign) -> Core (List (Name, TypeReference))
resolve_external_domains foreigns = do
  constraints <- case traverse (foreign_reference_constraints . snd) foreigns of
    Left explanation => throw (UserError explanation)
    Right groups => pure (concat groups)
  validate_external_domains constraints []

private
find_duplicate_name : List String -> Maybe String
find_duplicate_name [] = Nothing
find_duplicate_name (name :: rest) =
  if elem name rest then Just name else find_duplicate_name rest

private
validate_exports : List ExportABI -> Either String ()
validate_exports [] =
  Left
    ("No functions selected. Add %export \"dex:<method_name>\" to an " ++
     "explicit scalar or validated opaque-reference function.")
validate_exports exports =
  case find_duplicate_name (map method_name exports) of
    Nothing => Right ()
    Just duplicate => Left ("Duplicate generated DEX method name `" ++ duplicate ++ "`")

private
lower_exports :
  Name ->
  List (Name, DEXForeign) ->
  List ExportABI ->
  List (Name, Administrative_Normal_Form_Definition) ->
  Either String (List MethodPlan)
lower_exports integer_less_name foreigns [] definitions = Right []
lower_exports integer_less_name foreigns (selected :: rest) definitions = do
  definition <-
    case lookup_anf_definition selected.internal_name definitions of
      Nothing =>
        Left
          ("No checked ANF definition was produced for DEX export `" ++
           show selected.internal_name ++ "`")
      Just found => Right found
  method <-
    lower_method integer_less_name foreigns definitions selected.effect
      (show selected.internal_name) selected.method_name
      selected.parameter_types selected.result_type definition
  if method.parameter_count /= cast (length selected.parameter_types)
    then
      Left
        ("Internal DEX ABI mismatch for `" ++ show selected.internal_name ++
         "`: source type has " ++ show (length selected.parameter_types) ++
         " parameters, ANF has " ++ show method.parameter_count)
    else Right ()
  more <- lower_exports integer_less_name foreigns rest definitions
  Right (method :: more)

private
render_checked_exports :
  List ExportABI -> List (Name, Administrative_Normal_Form_Definition) -> String
render_checked_exports [] definitions = ""
render_checked_exports (selected :: rest) definitions =
  let rendered =
        case lookup_anf_definition selected.internal_name definitions of
          Nothing => "<missing checked ANF>"
          Just definition => show definition
  in "export " ++ show selected.internal_name ++ " as " ++ selected.method_name ++
     "\n" ++ rendered ++ "\n\n" ++ render_checked_exports rest definitions

private
fully_qualified_export :
  {auto c : Ref Ctxt Defs} -> (Name, String) -> Core (Name, String)
fully_qualified_export (internal_name, method_name) = do
  qualified_name <- toFullNames internal_name
  pure (qualified_name, method_name)

private
compile_dex :
  Ref Ctxt Defs -> Ref Syn SyntaxInfo ->
  (temporary_directory : String) -> (output_directory : String) ->
  ClosedTerm -> (requested_output_name : String) -> Core (Maybe String)
compile_dex definitions syntax temporary_directory output_directory
            term requested_output_name = do
  resolved_compile_data <-
    getCompileDataWith [backend_name] False Administrative_Normal_Form term
  qualified_exports <- traverse fully_qualified_export (exported resolved_compile_data)
  foreigns <-
    case collect_dex_foreigns (anf resolved_compile_data) of
      Left explanation =>
        throw (UserError ("dex rejected foreign declaration: " ++ explanation))
      Right accepted => pure accepted
  external_domains <- resolve_external_domains foreigns
  export_abis <- traverse (resolve_export_abi external_domains) qualified_exports
  integer_less_name <-
    toResolvedNames
      (NS (mkNamespace "Prelude.EqOrd") (UN (Basic "<")))
  case validate_exports export_abis of
    Left explanation => throw (UserError ("dex rejected exports: " ++ explanation))
    Right () => pure ()
  methods <-
    case lower_exports integer_less_name foreigns export_abis (anf resolved_compile_data) of
      Left explanation =>
        throw (UserError ("dex rejected checked program: " ++ explanation))
      Right accepted => pure accepted
  let plan = MkFilePlan "LIdric/Generated;" methods
  bytes <-
    case encode_dex plan of
      Left explanation => throw (UserError ("dex encoder rejected plan: " ++ explanation))
      Right encoded => pure encoded
  let dex_file = output_directory </> (requested_output_name ++ ".dex")
  let checked_file = output_directory </> (requested_output_name ++ ".checked.anf")
  let plan_file = output_directory </> (requested_output_name ++ ".dex.plan")
  let smali_file = output_directory </> (requested_output_name ++ ".smali")
  write_result <- coreLift (write_dex dex_file bytes)
  case write_result of
    Left explanation => throw (UserError ("Could not write DEX: " ++ explanation))
    Right () => pure ()
  Core.writeFile checked_file (render_checked_exports export_abis (anf resolved_compile_data))
  Core.writeFile plan_file (render_file_plan plan)
  Core.writeFile smali_file (render_smali plan)
  pure (Just dex_file)

private
execute_dex :
  Ref Ctxt Defs -> Ref Syn SyntaxInfo -> String -> ClosedTerm -> Core ()
execute_dex definitions syntax temporary_directory term =
  throw
    (UserError
      ("dex emits classes.dex application code. Execute it with ART/Dalvik " ++
       "or package it into an APK; host Chez execution is not a fallback."))

public export
dex_codegen : Codegen
dex_codegen = MkCG compile_dex execute_dex Nothing Nothing
