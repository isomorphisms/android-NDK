module Backend.DEX.IR

import Data.String

%default total

||| A DEX virtual register. This is target placement, not an Idriç type.
public export
record Register where
  constructor MkRegister
  number : Int

public export
Eq Register where
  (MkRegister left) == (MkRegister right) = left == right

public export
Show Register where
  show register = "v" ++ show register.number

||| A symbolic code address resolved only after instruction-width selection.
public export
record Label where
  constructor MkLabel
  number : Int

public export
Eq Label where
  (MkLabel left) == (MkLabel right) = left == right

public export
Show Label where
  show label = ":label_" ++ show label.number

||| Value classes used by checked Idriç exports.
||| The checked source ABI remains deliberately smaller than the target-level
||| framework-call vocabulary below.
public export
data ValueType
  = IntegerValue
  | TextValue
  | BooleanValue
  | ObjectValue
  | ByteValue | ShortValue | CharacterValue | FloatValue | DoubleValue

public export
Eq ValueType where
  IntegerValue == IntegerValue = True
  TextValue == TextValue = True
  BooleanValue == BooleanValue = True
  ObjectValue == ObjectValue = True
  ByteValue == ByteValue = True
  ShortValue == ShortValue = True
  CharacterValue == CharacterValue = True
  FloatValue == FloatValue = True
  DoubleValue == DoubleValue = True
  _ == _ = False

public export
Show ValueType where
  show IntegerValue = "Int32"
  show TextValue = "Text"
  show BooleanValue = "Boolean"
  show ObjectValue = "Object"
  show ByteValue = "Byte"
  show ShortValue = "Short"
  show CharacterValue = "Char"
  show FloatValue = "Float"
  show DoubleValue = "Double"

public export
value_descriptor : ValueType -> String
value_descriptor IntegerValue = "I"
value_descriptor TextValue = "Ljava/lang/String;"
value_descriptor BooleanValue = "Z"
value_descriptor ObjectValue = "Ljava/lang/Object;"
value_descriptor ByteValue = "B"
value_descriptor ShortValue = "S"
value_descriptor CharacterValue = "C"
value_descriptor FloatValue = "F"
value_descriptor DoubleValue = "D"

public export
shorty_character : ValueType -> Char
shorty_character IntegerValue = 'I'
shorty_character TextValue = 'L'
shorty_character BooleanValue = 'Z'
shorty_character ObjectValue = 'L'
shorty_character ByteValue = 'B'
shorty_character ShortValue = 'S'
shorty_character CharacterValue = 'C'
shorty_character FloatValue = 'F'
shorty_character DoubleValue = 'D'

||| A validated DEX reference descriptor such as Landroid/os/IBinder;.
||| Validation still belongs to the encoder boundary.
public export
record TypeReference where
  constructor MkTypeReference
  descriptor : String

public export
Eq TypeReference where
  (MkTypeReference left) == (MkTypeReference right) = left == right

public export
Show TypeReference where
  show reference = reference.descriptor

||| Target-level register width. A Java/Dalvik long occupies two consecutive
||| virtual registers; this is not a source-language numeric-default decision.
public export
data RegisterWidth
  = SingleRegister
  | RegisterPair

public export
Eq RegisterWidth where
  SingleRegister == SingleRegister = True
  RegisterPair == RegisterPair = True
  _ == _ = False

||| Value types at a DEX external-method boundary.
public export
data FrameworkValueType
  = ExistingValue ValueType
  | ReferenceValue TypeReference
  | LongValue
  | VoidValue

public export
Eq FrameworkValueType where
  (ExistingValue left) == (ExistingValue right) = left == right
  (ReferenceValue left) == (ReferenceValue right) = left == right
  LongValue == LongValue = True
  VoidValue == VoidValue = True
  _ == _ = False

public export
Show FrameworkValueType where
  show (ExistingValue value) = show value
  show (ReferenceValue reference) = show reference
  show LongValue = "Long"
  show VoidValue = "Void"

public export
register_width : FrameworkValueType -> Maybe RegisterWidth
register_width VoidValue = Nothing
register_width LongValue = Just RegisterPair
register_width (ExistingValue DoubleValue) = Just RegisterPair
register_width _ = Just SingleRegister

public export
framework_descriptor : FrameworkValueType -> String
framework_descriptor (ExistingValue value) = value_descriptor value
framework_descriptor (ReferenceValue reference) = reference.descriptor
framework_descriptor LongValue = "J"
framework_descriptor VoidValue = "V"

public export
framework_shorty_character : FrameworkValueType -> Char
framework_shorty_character (ExistingValue value) = shorty_character value
framework_shorty_character (ReferenceValue reference) = 'L'
framework_shorty_character LongValue = 'J'
framework_shorty_character VoidValue = 'V'

||| Width of declared parameters in the incoming DEX register area. The
||| MethodPlan parameter_count counts values, whereas a long consumes two words.
public export
parameter_register_words : List FrameworkValueType -> Either String Int
parameter_register_words [] = Right 0
parameter_register_words (VoidValue :: rest) =
  Left "DEX method parameter cannot have void type"
parameter_register_words (LongValue :: rest) = do
  count <- parameter_register_words rest
  Right (2 + count)
parameter_register_words (ExistingValue DoubleValue :: rest) = do
  count <- parameter_register_words rest
  Right (2 + count)
parameter_register_words (_ :: rest) = do
  count <- parameter_register_words rest
  Right (1 + count)

private
parameter_descriptors : List FrameworkValueType -> String
parameter_descriptors [] = ""
parameter_descriptors (value :: rest) =
  framework_descriptor value ++ parameter_descriptors rest

||| A concrete external DEX method reference.
public export
record MethodReference where
  constructor MkMethodReference
  owner : TypeReference
  name : String
  argument_types : List FrameworkValueType
  result : FrameworkValueType

public export
Eq MethodReference where
  left == right =
    left.owner == right.owner &&
    left.name == right.name &&
    map framework_descriptor left.argument_types ==
      map framework_descriptor right.argument_types &&
    framework_descriptor left.result == framework_descriptor right.result

public export
Show MethodReference where
  show method =
    show method.owner ++ "->" ++ method.name ++
    "(" ++ parameter_descriptors method.argument_types ++ ")" ++
    framework_descriptor method.result

public export
method_descriptor : MethodReference -> String
method_descriptor method =
  "(" ++ parameter_descriptors method.argument_types ++ ")" ++
  framework_descriptor method.result

public export
data InvokeKind
  = InvokeStatic
  | InvokeVirtual
  | InvokeInterface
  | InvokeDirect
  | InvokeSuper

public export
Eq InvokeKind where
  InvokeStatic == InvokeStatic = True
  InvokeVirtual == InvokeVirtual = True
  InvokeInterface == InvokeInterface = True
  InvokeDirect == InvokeDirect = True
  InvokeSuper == InvokeSuper = True
  _ == _ = False

public export
Show InvokeKind where
  show InvokeStatic = "invoke-static"
  show InvokeVirtual = "invoke-virtual"
  show InvokeInterface = "invoke-interface"
  show InvokeDirect = "invoke-direct"
  show InvokeSuper = "invoke-super"

||| A DEX invocation before format selection. For virtual/interface calls,
||| the first register is the receiver; method.argument_types describes only
||| declared parameters. The encoder chooses 35c or 3rc after safe placement.
public export
record InvocationPlan where
  constructor Invoke
  kind : InvokeKind
  method : MethodReference
  arguments : List Register
  result_register : Maybe Register

public export
Eq InvocationPlan where
  left == right =
    left.kind == right.kind &&
    left.method == right.method &&
    left.arguments == right.arguments &&
    left.result_register == right.result_register

public export
data IntegerBinaryOperation
  = AddInteger
  | SubtractInteger
  | MultiplyInteger

public export
Show IntegerBinaryOperation where
  show AddInteger = "add-int"
  show SubtractInteger = "sub-int"
  show MultiplyInteger = "mul-int"

public export
data IntegerCondition
  = EqualInteger
  | NotEqualInteger
  | LessThanInteger
  | GreaterEqualInteger
  | GreaterThanInteger
  | LessEqualInteger

public export
Show IntegerCondition where
  show EqualInteger = "if-eq"
  show NotEqualInteger = "if-ne"
  show LessThanInteger = "if-lt"
  show GreaterEqualInteger = "if-ge"
  show GreaterThanInteger = "if-gt"
  show LessEqualInteger = "if-le"

||| Typed DEX planning instructions. Object/reference/wide operations remain
||| separate from ordinary integer operations so the encoder cannot silently
||| use the wrong opcode family.
public export
data Instruction
  = Move Register Register
  | MoveWide Register Register
  | MoveObject Register Register
  | IntegerConstant Register Int
  | NullReference Register
  | TextConstant Register String
  | CheckCast Register TypeReference
  | IntegerBinary IntegerBinaryOperation Register Register Register
  | TextEqual Register Register Register
  | InvokeMethod InvocationPlan
  | IntegerBranch IntegerCondition Register Register Label
  | Goto Label
  | Goto16 Label
  | Goto32 Label
  | Mark Label
  | ReturnInteger Register
  | ReturnObject Register
  | ReturnWide Register
  | ReturnVoid

private
show_registers : List Register -> String
show_registers [] = ""
show_registers [register] = show register
show_registers (register :: rest) = show register ++ ", " ++ show_registers rest

public export
Show Instruction where
  show (Move destination source) =
    "move " ++ show destination ++ ", " ++ show source
  show (MoveWide destination source) =
    "move-wide " ++ show destination ++ ", " ++ show source
  show (MoveObject destination source) =
    "move-object " ++ show destination ++ ", " ++ show source
  show (IntegerConstant destination value) =
    "const " ++ show destination ++ ", " ++ show value
  show (NullReference destination) = "const-null " ++ show destination
  show (TextConstant destination value) =
    "const-string " ++ show destination ++ ", " ++ show value
  show (CheckCast register target) =
    "check-cast " ++ show register ++ ", " ++ show target
  show (IntegerBinary operation destination left right) =
    show operation ++ " " ++ show destination ++ ", " ++
    show left ++ ", " ++ show right
  show (TextEqual destination left right) =
    "text-equal " ++ show destination ++ ", " ++ show left ++ ", " ++ show right
  show (InvokeMethod invocation) =
    let suffix =
          case invocation.result_register of
            Nothing => ""
            Just register => " => " ++ show register
    in show invocation.kind ++ " {" ++ show_registers invocation.arguments ++ "}, " ++
       show invocation.method ++ suffix
  show (IntegerBranch condition left right target) =
    show condition ++ " " ++ show left ++ ", " ++
    show right ++ ", " ++ show target
  show (Goto target) = "goto " ++ show target
  show (Goto16 target) = "goto/16 " ++ show target
  show (Goto32 target) = "goto/32 " ++ show target
  show (Mark label) = show label
  show (ReturnInteger register) = "return " ++ show register
  show (ReturnObject register) = "return-object " ++ show register
  show (ReturnWide register) = "return-wide " ++ show register
  show ReturnVoid = "return-void"

||| Instance receivers belong to the platform ABI, never to the checked
||| static export's declared parameter list.
public export
data MethodMode = StaticMethod | InstanceMethod | ConstructorMethod
                | ClassInitializerMethod | NativeStaticMethod | NativeInstanceMethod
                | ProtectedInstanceMethod

public export
Eq MethodMode where
  StaticMethod == StaticMethod = True
  InstanceMethod == InstanceMethod = True
  ConstructorMethod == ConstructorMethod = True
  ClassInitializerMethod == ClassInitializerMethod = True
  NativeStaticMethod == NativeStaticMethod = True
  NativeInstanceMethod == NativeInstanceMethod = True
  ProtectedInstanceMethod == ProtectedInstanceMethod = True
  _ == _ = False

public export
method_access_flags : MethodMode -> Integer
method_access_flags StaticMethod = 9
method_access_flags InstanceMethod = 1
method_access_flags ConstructorMethod = 0x10001
method_access_flags ClassInitializerMethod = 0x10008
method_access_flags NativeStaticMethod = 0x109
method_access_flags NativeInstanceMethod = 0x101
method_access_flags ProtectedInstanceMethod = 4

public export
native_method : MethodMode -> Bool
native_method NativeStaticMethod = True
native_method NativeInstanceMethod = True
native_method _ = False

public export
virtual_method : MethodMode -> Bool
virtual_method InstanceMethod = True
virtual_method NativeInstanceMethod = True
virtual_method ProtectedInstanceMethod = True
virtual_method _ = False

||| One checked Idriç export or mechanical platform bridge after placement.
public export
record MethodPlan where
  constructor MkBoundMethodPlan
  source_name : String
  method_name : String
  parameter_count : Int
  parameter_types : List FrameworkValueType
  result_type : FrameworkValueType
  register_count : Int
  instructions : List Instruction
  mode : MethodMode

||| Preserve the ordinary static-plan entry point used by existing consumers.
public export
MkMethodPlan : String -> String -> Int -> List FrameworkValueType ->
  FrameworkValueType -> Int -> List Instruction -> MethodPlan
MkMethodPlan source name count argument_types result registers instructions =
  MkBoundMethodPlan source name count argument_types result registers instructions StaticMethod

public export
incoming_parameter_types : MethodPlan -> List FrameworkValueType
incoming_parameter_types method = case method.mode of
  StaticMethod => method.parameter_types
  ClassInitializerMethod => method.parameter_types
  NativeStaticMethod => method.parameter_types
  _ => ExistingValue ObjectValue :: method.parameter_types

public export
render_method_plan : MethodPlan -> String
render_method_plan method =
  unlines
    ([ "method " ++ method.method_name
     , "source: " ++ method.source_name
     , "parameters: " ++ show method.parameter_types
     , "result: " ++ show method.result_type
     , "registers: " ++ show method.register_count
     , "access-flags: " ++ show (method_access_flags method.mode)
     ] ++ map (\instruction => "  " ++ show instruction) method.instructions)

||| A single generated utility class. The generic backend still owns no
||| Android UI, resource, manifest, or packaging semantics.
public export
record FilePlan where
  constructor MkFlaggedClassFilePlan
  class_descriptor : String
  methods : List MethodPlan
  interfaces : List TypeReference
  superclass : TypeReference
  access_flags : Integer

public export
MkClassFilePlan : String -> List MethodPlan -> List TypeReference -> TypeReference -> FilePlan
MkClassFilePlan name methods interfaces superclass =
  MkFlaggedClassFilePlan name methods interfaces superclass 0x11

public export
MkFilePlan : String -> List MethodPlan -> FilePlan
MkFilePlan descriptor methods =
  MkClassFilePlan descriptor methods [] (MkTypeReference "Ljava/lang/Object;")

public export
render_file_plan : FilePlan -> String
render_file_plan plan =
  "class " ++ plan.class_descriptor ++ "\n" ++
  "super " ++ plan.superclass.descriptor ++ "\n" ++
  concat (map (\implemented => "implements " ++ show implemented ++ "\n") plan.interfaces) ++ "\n" ++
  concat (intersperse "\n" (map render_method_plan plan.methods))
