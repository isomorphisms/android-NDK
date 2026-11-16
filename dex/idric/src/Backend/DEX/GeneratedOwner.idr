module Backend.DEX.GeneratedOwner

import Backend.DEX.IR
import Data.List
import Data.String

%default total

private
identifier_start : Char -> Bool
identifier_start value = (value >= 'a' && value <= 'z') ||
  (value >= 'A' && value <= 'Z') || value == '_' || value == '$'

private
identifier_rest : Char -> Bool
identifier_rest value = identifier_start value || (value >= '0' && value <= '9')

private
valid_components : List Char -> Bool
valid_components [] = False
valid_components (first :: rest) = identifier_start first && remainder rest
  where
    remainder : List Char -> Bool
    remainder [] = True
    remainder ('/' :: next :: rest) = identifier_start next && remainder rest
    remainder ('/' :: []) = False
    remainder (next :: rest) = identifier_rest next && remainder rest

private
validate_owner : String -> Either String String
validate_owner value = case unpack value of
  'L' :: first :: rest => case reverse rest of
    ';' :: reversed =>
      let path = first :: reverse reversed in
      if first < 'a' || first > 'z' || not (elem '/' path) ||
         not (valid_components path)
        then Left "generated-owner requires a qualified ASCII class descriptor starting with a lowercase letter"
        else if any (\namespace_prefix => isPrefixOf (unpack namespace_prefix) path)
          ["android/", "java/", "javax/", "dalvik/", "sun/", "com/android/"]
          then Left "generated-owner cannot declare a framework namespace"
          else Right value
    _ => Left "generated-owner requires an object descriptor ending in semicolon"
  _ => Left "generated-owner requires an object descriptor beginning with L"

||| Remove only this configuration directive. The remaining source directives
||| still pass through the normal callback, field and native-boundary checks.
public export
select_generated_owner : List String -> Either String (String, List String)
select_generated_owner directives =
  case filter selected directives of
    [] => Right ("LIdric/Generated;", directives)
    [entry] => do
      owner <- validate_owner (pack (drop 16 (unpack entry)))
      Right (owner, filter (not . selected) directives)
    _ => Left "generated-owner may be selected exactly once"
  where
    selected : String -> Bool
    selected value = isPrefixOf (unpack "generated-owner=") (unpack value)

private
captured_owner : String -> String
captured_owner owner = pack (reverse (drop 1 (reverse (unpack owner)))) ++
  "$CapturedRunnable;"

private
relocate_descriptor_chars : String -> List Char -> String
relocate_descriptor_chars owner ('[' :: rest) = "[" ++ relocate_descriptor_chars owner rest
relocate_descriptor_chars owner value =
  if value == unpack "LIdric/Generated;" then owner
  else if value == unpack "LIdric/Generated$CapturedRunnable;" then captured_owner owner
  else pack value

private
relocate_type : String -> TypeReference -> TypeReference
relocate_type owner reference =
  MkTypeReference (relocate_descriptor_chars owner (unpack reference.descriptor))

private
relocate_value : String -> FrameworkValueType -> FrameworkValueType
relocate_value owner (ReferenceValue reference) = ReferenceValue (relocate_type owner reference)
relocate_value owner value = value

private
relocate_field : String -> FieldReference -> FieldReference
relocate_field owner field =
  { owner := relocate_type owner field.owner,
    value_type := relocate_value owner field.value_type } field

private
relocate_method_reference : String -> MethodReference -> MethodReference
relocate_method_reference owner method =
  { owner := relocate_type owner method.owner,
    argument_types := map (relocate_value owner) method.argument_types,
    result := relocate_value owner method.result } method

private
relocate_instruction : String -> Instruction -> Instruction
relocate_instruction owner (StaticGetObject destination field) =
  StaticGetObject destination (relocate_field owner field)
relocate_instruction owner (StaticPutObject source field) =
  StaticPutObject source (relocate_field owner field)
relocate_instruction owner (InstanceGetObject destination receiver field) =
  InstanceGetObject destination receiver (relocate_field owner field)
relocate_instruction owner (InstancePutObject source receiver field) =
  InstancePutObject source receiver (relocate_field owner field)
relocate_instruction owner (NewObject destination reference) =
  NewObject destination (relocate_type owner reference)
relocate_instruction owner (CheckCast register reference) =
  CheckCast register (relocate_type owner reference)
relocate_instruction owner (CatchRegion reference beginning ending handler) =
  CatchRegion (relocate_type owner reference) beginning ending handler
relocate_instruction owner (InvokeMethod invocation) =
  InvokeMethod ({ method := relocate_method_reference owner invocation.method } invocation)
-- Ordinary string values, labels, register placement and numerical operations
-- are not class references and must retain their exact semantics.
relocate_instruction owner instruction = instruction

private
relocate_method : String -> MethodPlan -> MethodPlan
relocate_method owner method =
  { parameter_types := map (relocate_value owner) method.parameter_types,
    result_type := relocate_value owner method.result_type,
    instructions := map (relocate_instruction owner) method.instructions } method

private
relocate_file : String -> FilePlan -> FilePlan
relocate_file owner plan =
  { class_descriptor := relocate_descriptor_chars owner (unpack plan.class_descriptor),
    methods := map (relocate_method owner) plan.methods,
    fields := map (\field => { value_type := relocate_value owner field.value_type } field) plan.fields,
    interfaces := map (relocate_type owner) plan.interfaces,
    superclass := relocate_type owner plan.superclass } plan

||| Select a generated class in the typed IR before placement and encoding.
||| Legacy compilation returns the original plans without any transformation.
public export
relocate_generated_classes : String -> List FilePlan -> List FilePlan
relocate_generated_classes "LIdric/Generated;" plans = plans
relocate_generated_classes owner plans = map (relocate_file owner) plans
