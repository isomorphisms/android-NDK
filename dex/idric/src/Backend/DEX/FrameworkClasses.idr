module Backend.DEX.FrameworkClasses

import Backend.DEX.Encode
import Backend.DEX.IR
import Data.List
import Data.String

%default covering

||| Consumer-owned JNI declarations. Their bodies remain native code.
public export
record NativeCallback where
  constructor Callback
  name : String
  result : String
  arguments : List String

public export
record FrameworkClass where
  constructor Subclass
  descriptor : String
  superclass : String
  native_library : Maybe String
  callbacks : List NativeCallback

private
unique : Eq value => List value -> List value
unique [] = []
unique (x :: xs) = x :: unique (filter (/= x) xs)

private
plain_ascii : String -> Bool
plain_ascii s = not (null (unpack s)) && all (\c => ord c >= 33 && ord c <= 126) (unpack s)

private
object_type : String -> Bool
object_type s = isPrefixOf "L" s && isSuffixOf ";" s && length (unpack s) > 2 &&
  all (\c => isAlphaNum c || c == '/' || c == '_' || c == '$')
    (drop 1 (take (length (unpack s) `minus` 1) (unpack s))) &&
  not (isInfixOf "//" s) && not (isPrefixOf "L/" s) && not (isSuffixOf "/;" s)

private
value_type : String -> Bool
value_type s = plain_ascii s && (object_type s || elem s ["Z", "B", "C", "S", "I", "J", "F", "D"])

private
method_name : String -> Bool
method_name s = plain_ascii s && all (\c => isAlphaNum c || c == '_' || c == '$') (unpack s)

private
validate_class : FrameworkClass -> Either String ()
validate_class cls = do
  if object_type cls.descriptor && object_type cls.superclass &&
     cls.descriptor /= cls.superclass
    then Right () else Left "Invalid class/superclass descriptor"
  if all (\callback => method_name callback.name &&
      (callback.result == "V" || value_type callback.result) &&
      all value_type callback.arguments) cls.callbacks
    then Right () else Left "Invalid native callback signature"
  let keys = map (\c => (c.name, c.result, c.arguments)) cls.callbacks
  if length keys == length (unique keys)
    then Right () else Left "Duplicate native callback signature"
  case cls.native_library of
    Nothing => Right ()
    Just library => if plain_ascii library && all (\c => isAlphaNum c || c == '_') (unpack library)
                      then Right () else Left "Invalid native library name"


private
callback_type : String -> FrameworkValueType
callback_type "V" = VoidValue
callback_type "I" = ExistingValue IntegerValue
callback_type "Z" = ExistingValue BooleanValue
callback_type "B" = ExistingValue ByteValue
callback_type "C" = ExistingValue CharacterValue
callback_type "S" = ExistingValue ShortValue
callback_type "F" = ExistingValue FloatValue
callback_type "D" = ExistingValue DoubleValue
callback_type "J" = LongValue
callback_type "Ljava/lang/String;" = ExistingValue TextValue
callback_type "Ljava/lang/Object;" = ExistingValue ObjectValue
callback_type descriptor = ReferenceValue (MkTypeReference descriptor)

private
constructor_plan : FrameworkClass -> MethodPlan
constructor_plan cls =
  MkBoundMethodPlan "framework constructor" "<init>" 0 [] VoidValue 1
    [ InvokeMethod (Invoke InvokeDirect
        (MkMethodReference (MkTypeReference cls.superclass) "<init>" [] VoidValue)
        [MkRegister 0] Nothing)
    , ReturnVoid
    ] ConstructorMethod

private
initializer_plan : String -> MethodPlan
initializer_plan library =
  MkBoundMethodPlan "native library initialization" "<clinit>" 0 [] VoidValue 1
    [ TextConstant (MkRegister 0) library
    , InvokeMethod (Invoke InvokeStatic
        (MkMethodReference (MkTypeReference "Ljava/lang/System;") "loadLibrary"
          [ExistingValue TextValue] VoidValue) [MkRegister 0] Nothing)
    , ReturnVoid
    ] ClassInitializerMethod

private
native_plan : NativeCallback -> MethodPlan
native_plan callback =
  MkBoundMethodPlan "consumer JNI declaration" callback.name
    (cast (length callback.arguments)) (map callback_type callback.arguments)
    (callback_type callback.result) 0 [] NativeInstanceMethod

||| Translate the existing public adapter API into the same typed plans used
||| by checked ANF. Identifier tables, opcodes, class data, MUTF-8 and hashes
||| are all emitted by Backend.DEX.Encode.
public export
framework_class_plan : FrameworkClass -> List String -> Either String FilePlan
framework_class_plan cls interfaces = do
  validate_class cls
  if all object_type interfaces then Right ()
    else Left "Invalid implemented interface descriptor"
  if length (unique interfaces) == length interfaces then Right ()
    else Left "Duplicate implemented interface"
  let initialization = maybe [] (\library => [initializer_plan library]) cls.native_library
  Right ({ access_flags := 1 } (MkClassFilePlan cls.descriptor
    (constructor_plan cls :: initialization ++ map native_plan cls.callbacks)
    (map MkTypeReference interfaces) (MkTypeReference cls.superclass)))

public export
encode_framework_classes_implementing : List (FrameworkClass, List String) -> Either String (List Int)
encode_framework_classes_implementing implementing = do
  let classes = map fst implementing
  if null classes then Left "No framework classes" else Right ()
  let names = map descriptor classes
  if length (unique names) /= length names then Left "Duplicate framework class" else Right ()
  _ <- traverse validate_class classes
  if any (\cls => elem cls.superclass names) classes
    then Left "App-defined superclass dependencies are unsupported"
    else Right ()
  plans <- traverse (\(cls, interfaces) => framework_class_plan cls interfaces) implementing
  encode_dex_classes plans

public export
encode_framework_classes : List FrameworkClass -> Either String (List Int)
encode_framework_classes classes = encode_framework_classes_implementing (map (\cls => (cls, [])) classes)

public export
write_framework_classes_implementing : List (FrameworkClass, List String) -> String -> IO (Either String ())
write_framework_classes_implementing classes destination =
  case encode_framework_classes_implementing classes of
    Left error => pure (Left error)
    Right bytes => write_dex destination bytes

public export
write_framework_classes : List FrameworkClass -> String -> IO (Either String ())
write_framework_classes classes destination =
  write_framework_classes_implementing (map (\cls => (cls, [])) classes) destination
