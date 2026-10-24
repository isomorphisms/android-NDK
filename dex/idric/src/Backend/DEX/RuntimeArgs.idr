module Backend.DEX.RuntimeArgs

import Backend.DEX.IR

%default total

-- The Android ART entrypoint receives arguments after the class name.
-- Idris System.getArgs counts a synthetic executable-name element at index 0.
-- The caller supplies that stable name; no application-specific name is built
-- into the reusable compiler or into the DEX instruction encoder.

private
argument_array_type : FrameworkValueType
argument_array_type = ReferenceValue (MkTypeReference "[Ljava/lang/String;")

private
argument_field : String -> FieldReference
argument_field owner =
  MkFieldReference (MkTypeReference owner) "__idric_arguments" argument_array_type

private
argument_field_declaration : StaticFieldPlan
argument_field_declaration =
  MkStaticFieldPlan "__idric_arguments" argument_array_type 10

private
runtime_count : String -> MethodPlan
runtime_count owner =
  MkMethodPlan "Idriç ART command argument count" "__idricArgCount"
    0 [] LongValue 6
    [ StaticGetObject (MkRegister 5) (argument_field owner)
    , ArrayLength (MkRegister 0) (MkRegister 5)
    , IntToLong (MkRegister 1) (MkRegister 0)
    , LongConstant (MkRegister 3) 1
    , AddLong (MkRegister 1) (MkRegister 1) (MkRegister 3)
    , ReturnWide (MkRegister 1)
    ]

private
runtime_argument : String -> String -> MethodPlan
runtime_argument owner program_name =
  MkMethodPlan "Idriç ART command argument access" "__idricArg"
    1 [LongValue] (ExistingValue TextValue) 9
    [ InvokeMethod (Invoke InvokeStatic
        (MkMethodReference (MkTypeReference "Ljava/lang/Math;") "toIntExact"
          [LongValue] (ExistingValue IntegerValue))
        [MkRegister 7] (Just (MkRegister 0)))
    , IntegerConstant (MkRegister 1) 0
    , IntegerBranch EqualInteger (MkRegister 0) (MkRegister 1) (MkLabel 0)
    , IntegerConstant (MkRegister 1) 1
    , IntegerBinary SubtractInteger (MkRegister 2) (MkRegister 0) (MkRegister 1)
    , StaticGetObject (MkRegister 3) (argument_field owner)
    , ArrayGetObject (MkRegister 4) (MkRegister 3) (MkRegister 2)
    , ReturnObject (MkRegister 4)
    , Mark (MkLabel 0)
    , TextConstant (MkRegister 4) program_name
    , ReturnObject (MkRegister 4)
    ]

private
runtime_main : String -> String -> MethodPlan
runtime_main owner checked_entry =
  MkMethodPlan "Idriç checked ART entrypoint" "main"
    1 [argument_array_type] VoidValue 1
    [ StaticPutObject (MkRegister 0) (argument_field owner)
    , InvokeMethod (Invoke InvokeStatic
        (MkMethodReference (MkTypeReference owner) checked_entry [] VoidValue)
        [] Nothing)
    , ReturnVoid
    ]

private
reserved_methods : List String
reserved_methods = ["main", "__idricArgCount", "__idricArg"]

-- Attach the adapter only after checked source compilation has produced a
-- nullary, void-returning entry method. Source arguments and IO expressions
-- are not rewritten by this adapter. The sole synthetic field is private and
-- receives the real ART String[] before the checked entrypoint is invoked.
public export
with_runtime_arguments :
  (program_name : String) -> (checked_entry : String) ->
  FilePlan -> Either String FilePlan
with_runtime_arguments program_name checked_entry plan = do
  if null (unpack program_name)
    then Left "DEX runtime argument adapter requires a program name"
    else Right ()
  if elem "__idric_arguments" (map name plan.fields)
    then Left "DEX checked runtime argument field collides with an application field"
    else Right ()
  if any (\method => elem method.method_name reserved_methods) plan.methods
    then Left "DEX checked runtime argument methods collide with existing methods"
    else Right ()
  if any (\method =>
         method.method_name == checked_entry &&
         null method.parameter_types &&
         method.result_type == VoidValue &&
         method.mode == StaticMethod) plan.methods
    then Right ()
    else Left "DEX runtime argument adapter requires a checked nullary void entry method"
  Right
    ({ methods := plan.methods ++
        [ runtime_count plan.class_descriptor
        , runtime_argument plan.class_descriptor program_name
        , runtime_main plan.class_descriptor checked_entry
        ]
     , fields := plan.fields ++ [argument_field_declaration]
     } plan)
