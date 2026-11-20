module Backend.DEX.ManagedActivityField

import Backend.DEX.IR
import Backend.DEX.Lower
import Backend.DEX.ValueLayout
import Compiler.ANF
import Core.Name.Namespace
import Core.TT
import Algebra
import Data.List
import Data.List1
import Data.String

%default covering

public export
record ManagedActivityField where
  constructor CheckedActivityField
  field_name : String
  getter : Name
  setter : Name

private
named : Name -> String -> String -> Bool
named name namespace_name basic = name == NS (mkNamespace namespace_name) (UN (Basic basic))

private
qualified_name : String -> Either String Name
qualified_name spelling = case reverse (forget (split (== '.') spelling)) of
  basic :: rest@(_ :: _) => do
    if any (== "") (basic :: rest)
      then Left "Managed Activity field endpoint has an empty source-name segment"
      else Right (NS (mkNamespace (joinBy "." (reverse rest))) (UN (Basic basic)))
  _ => Left "Managed Activity field endpoints require complete qualified source names"

public export
parse_activity_field : String -> Either String (Maybe ManagedActivityField)
parse_activity_field directive = case words directive of
  ["managed-field", "LIdric/Generated;", field, getter, setter] => do
    _ <- validate_method_name field
    read <- qualified_name getter
    write <- qualified_name setter
    if read == write then Left "Managed Activity field getter and setter must be distinct"
      else Right (Just (CheckedActivityField field read write))
  "managed-field" :: _ => Left "Managed Activity field requires Generated owner, field, qualified getter and setter"
  _ => Right Nothing

||| After normalization, source getters must have exactly the checked PrimIO
||| shape. Shrinking proves the payload has no receiver/World dependency.
public export
activity_field_getter_type : ClosedTerm -> Either String (Name, ClosedTerm)
activity_field_getter_type
  (Bind _ receiver (Pi _ multiplicity Explicit (Ref _ (TyCon _) receiver_type))
    (Bind _ world (Pi _ world_multiplicity Explicit (PrimVal _ (PrT WorldType)))
      (App _ (Ref _ (TyCon _) result) (App _ (Ref _ (TyCon _) cell) payload)))) =
  if isErased multiplicity || world_multiplicity /= timesNeutral || not (named result "PrimIO" "IORes") ||
      not (named cell "Data.IORef" "IORef")
    then Left "Managed Activity field getter requires Activity -> PrimIO (IORef payload)"
    else case shrink payload (Drop (Drop Refl)) of
      Nothing => Left "Managed Activity field payload must be closed, independent of receiver and World"
      Just closed => Right (receiver_type, closed)
activity_field_getter_type _ =
  Left "Managed Activity field getter requires Activity -> PrimIO (IORef payload)"

public export
activity_field_setter_type : ClosedTerm -> Either String (Name, ClosedTerm)
activity_field_setter_type
  (Bind _ receiver (Pi _ multiplicity Explicit (Ref _ (TyCon _) receiver_type))
    (Bind _ value (Pi _ value_multiplicity Explicit (App _ (Ref _ (TyCon _) cell) payload))
      (Bind _ world (Pi _ world_multiplicity Explicit (PrimVal _ (PrT WorldType)))
        (App _ (Ref _ (TyCon _) result) (Ref _ (TyCon _) unit))))) =
  if isErased multiplicity || isErased value_multiplicity || world_multiplicity /= timesNeutral ||
      not (named cell "Data.IORef" "IORef") || not (named result "PrimIO" "IORes") ||
      not (named unit "Builtin" "Unit")
    then Left "Managed Activity field setter requires Activity -> IORef payload -> PrimIO Unit"
    else case shrink payload (Drop Refl) of
      Nothing => Left "Managed Activity field payload must be closed, independent of receiver"
      Just closed => Right (receiver_type, closed)
activity_field_setter_type _ =
  Left "Managed Activity field setter requires Activity -> IORef payload -> PrimIO Unit"

private
get_method : ManagedActivityField -> String
get_method field = "__idricGetField_" ++ field.field_name

private
set_method : ManagedActivityField -> String
set_method field = "__idricSetField_" ++ field.field_name

public export
activity_field_abis : List ManagedActivityField -> List (Name, (String, Int))
activity_field_abis = concatMap (\field =>
  [(field.getter, (get_method field, 2)), (field.setter, (set_method field, 3))])

private
object_value : FrameworkValueType
object_value = ExistingValue ObjectValue

private
owner : TypeReference
owner = MkTypeReference "LIdric/Generated;"

private
nonnull : Register -> Register -> String -> List Instruction
nonnull value message reason =
  [ TextConstant message reason
  , InvokeMethod (Invoke InvokeStatic
      (MkMethodReference (MkTypeReference "Ljava/util/Objects;") "requireNonNull"
        [object_value, ExistingValue TextValue] object_value) [value, message] (Just value))
  ]

public export
activity_field_declarations : List ManagedActivityField -> List FieldPlan
activity_field_declarations = map (\field =>
  MkFieldPlan field.field_name (ReferenceValue managed_node_type) 2)

public export
activity_field_methods : List ManagedActivityField -> List MethodPlan
activity_field_methods = concatMap methods
  where
    methods : ManagedActivityField -> List MethodPlan
    methods field =
      let reference = MkFieldReference owner field.field_name (ReferenceValue managed_node_type) in
      [ MkMethodPlan "checked source private Activity cell getter" (get_method field)
          2 [object_value, object_value] object_value 5
          ([CheckCast (MkRegister 3) owner, InstanceGetObject (MkRegister 0) (MkRegister 3) reference] ++
           nonnull (MkRegister 0) (MkRegister 1)
             ("Idriç Activity field '" ++ field.field_name ++ "' is uninitialized") ++
           [ReturnObject (MkRegister 0)])
      , MkMethodPlan "checked source private Activity cell setter" (set_method field)
          3 [object_value, object_value, object_value] object_value 6
          ([CheckCast (MkRegister 3) owner] ++
           nonnull (MkRegister 4) (MkRegister 0)
             ("Idriç Activity field '" ++ field.field_name ++ "' cannot store null") ++
           [ CheckCast (MkRegister 4) managed_node_type
           , InstancePutObject (MkRegister 4) (MkRegister 3) reference
           , NullReference (MkRegister 0), ReturnObject (MkRegister 0)])
      ]

mutual
  private
  rewrite_expression : List ManagedActivityField -> Administrative_Normal_Form -> Administrative_Normal_Form
  rewrite_expression fields (Administrative_Normal_Form_External_Primitive fc Nothing name arguments) =
    if any (\field => name == field.getter || name == field.setter) fields
      then Administrative_Normal_Form_Named_Function_Application fc Nothing name arguments
      else Administrative_Normal_Form_External_Primitive fc Nothing name arguments
  rewrite_expression fields (Administrative_Normal_Form_Binding fc variable value body) =
    Administrative_Normal_Form_Binding fc variable (rewrite_expression fields value) (rewrite_expression fields body)
  rewrite_expression fields (Administrative_Normal_Form_Constructor_Case fc source alternatives fallback) =
    Administrative_Normal_Form_Constructor_Case fc source (map (rewrite_constructor fields) alternatives)
      (map (rewrite_expression fields) fallback)
  rewrite_expression fields (Administrative_Normal_Form_Constant_Case fc source alternatives fallback) =
    Administrative_Normal_Form_Constant_Case fc source (map (rewrite_constant fields) alternatives)
      (map (rewrite_expression fields) fallback)
  rewrite_expression fields other = other

  private
  rewrite_constructor : List ManagedActivityField -> Administrative_Normal_Form_Constructor_Alternative ->
    Administrative_Normal_Form_Constructor_Alternative
  rewrite_constructor fields (Make_Administrative_Normal_Form_Constructor_Alternative name info tag arguments body) =
    Make_Administrative_Normal_Form_Constructor_Alternative name info tag arguments (rewrite_expression fields body)

  private
  rewrite_constant : List ManagedActivityField -> Administrative_Normal_Form_Constant_Alternative ->
    Administrative_Normal_Form_Constant_Alternative
  rewrite_constant fields (Make_Administrative_Normal_Form_Constant_Alternative value body) =
    Make_Administrative_Normal_Form_Constant_Alternative value (rewrite_expression fields body)

public export
rewrite_activity_fields : List ManagedActivityField -> (Name, Administrative_Normal_Form_Definition) ->
  (Name, Administrative_Normal_Form_Definition)
rewrite_activity_fields fields (name, Make_Administrative_Normal_Form_Function arguments body) =
  (name, Make_Administrative_Normal_Form_Function arguments (rewrite_expression fields body))
rewrite_activity_fields _ other = other
