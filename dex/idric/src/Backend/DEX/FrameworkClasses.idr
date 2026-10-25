module Backend.DEX.FrameworkClasses

import Backend.DEX.Encode
import Backend.DEX.Hash
import Data.List
import Data.Maybe
import Data.String

%default covering

||| The supported class boundary: constructors and native virtual overrides.
||| Android/JNI callback bodies remain consumer-owned.
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
record Signature where
  constructor Sig
  owner : String
  name : String
  result : String
  arguments : List String

private
signature_key : Signature -> (String, String, String, List String)
signature_key s = (s.owner, s.name, s.result, s.arguments)

private
unique : Eq a => List a -> List a
unique [] = []
unique (x :: xs) = x :: unique (filter (/= x) xs)

private
u16 : Int -> List Int
u16 n = [n `mod` 256, (n `div` 256) `mod` 256]

private
u32 : Int -> List Int
u32 n = u16 n ++ u16 (n `div` 65536)

private
uleb : Int -> List Int
uleb n = if n < 128 then [n]
         else (128 + n `mod` 128) :: uleb (n `div` 128)

private
aligned : Int -> Int
aligned n = n + ((4 - n `mod` 4) `mod` 4)

private
pad : Int -> List Int
pad n = replicate (cast (aligned n - n)) 0

private
index_of : Eq a => a -> List a -> Int
index_of value values = go 0 values where
  go : Int -> List a -> Int
  go position [] = position
  go position (x :: xs) = if value == x then position else go (position + 1) xs

private
short_type : String -> String
short_type descriptor = if isPrefixOf "L" descriptor || isPrefixOf "[" descriptor
                         then "L" else descriptor

private
shorty : (String, List String) -> String
shorty (result, arguments) = short_type result ++ concatMap short_type arguments

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
own_signatures : FrameworkClass -> List Signature
own_signatures cls =
  Sig cls.descriptor "<init>" "V" [] ::
  (case cls.native_library of
    Nothing => []
    Just _ => [Sig cls.descriptor "<clinit>" "V" []]) ++
  map (\c => Sig cls.descriptor c.name c.result c.arguments) cls.callbacks

private
all_signatures : List FrameworkClass -> List Signature
all_signatures classes = concatMap (\cls =>
  Sig cls.superclass "<init>" "V" [] :: own_signatures cls) classes ++
  (if any (isJust . native_library) classes
     then [Sig "Ljava/lang/System;" "loadLibrary" "V" ["Ljava/lang/String;"]]
     else [])

private
map_item : Int -> Int -> Int -> List Int
map_item kind count offset = u16 kind ++ u16 0 ++ u32 count ++ u32 offset

private
code_item : Int -> Int -> Int -> List Int -> List Int
code_item registers incoming outgoing words =
  u16 registers ++ u16 incoming ++ u16 outgoing ++ u16 0 ++
  u32 0 ++ u32 (cast (length words)) ++ concatMap u16 words

private
record CodeLayout where
  constructor Codes
  bytes : List Int
  locations : List ((String, String, String, List String), Int)
  next : Int
  count : Int

private
layout_code : (String -> Int) -> (Signature -> Int) -> Int ->
              List FrameworkClass -> CodeLayout
layout_code string_index method_index start classes = go start classes [] [] 0 where
  go : Int -> List FrameworkClass -> List Int ->
       List ((String, String, String, List String), Int) -> Int -> CodeLayout
  go offset [] bytes locations count = Codes bytes locations offset count
  go offset (cls :: rest) bytes locations count =
    let init_offset = aligned offset
        -- invoke-direct {p0}, superclass.<init>(); return-void.
        init_code = code_item 1 1 1
          [0x1070, method_index (Sig cls.superclass "<init>" "V" []), 0, 0x000e]
        after_init = init_offset + cast (length init_code)
        init_location = (signature_key (Sig cls.descriptor "<init>" "V" []), init_offset)
        init_bytes = bytes ++ pad offset ++ init_code
    in case cls.native_library of
      Nothing => go after_init rest init_bytes (locations ++ [init_location]) (count + 1)
      Just library =>
        let static_offset = aligned after_init
            -- const-string v0, library; invoke-static {v0}, System.loadLibrary; return-void.
            static_code = code_item 1 0 1
              [0x001a, string_index library, 0x1071,
               method_index (Sig "Ljava/lang/System;" "loadLibrary" "V" ["Ljava/lang/String;"]),
               0, 0x000e]
            static_location = (signature_key (Sig cls.descriptor "<clinit>" "V" []), static_offset)
        in go (static_offset + cast (length static_code)) rest
          (init_bytes ++ pad after_init ++ static_code)
          (locations ++ [init_location, static_location]) (count + 2)

private
layout_strings : Int -> List String -> (List Int, List Int, Int)
layout_strings start values = go start values [] [] where
  go : Int -> List String -> List Int -> List Int -> (List Int, List Int, Int)
  go offset [] bytes offsets = (bytes, offsets, offset)
  go offset (value :: rest) bytes offsets =
    let item = uleb (cast (length (unpack value))) ++ map ord (unpack value) ++ [0]
    in go (offset + cast (length item)) rest (bytes ++ item) (offsets ++ [offset])

private
layout_type_lists : (String -> Int) -> Int -> List (List String) -> (List Int, List Int, Int)
layout_type_lists type_index start lists = go start lists [] [] where
  go : Int -> List (List String) -> List Int -> List Int -> (List Int, List Int, Int)
  go offset [] bytes offsets = (bytes, offsets, offset)
  go offset (arguments :: rest) bytes offsets =
    let item = u32 (cast (length arguments)) ++ concatMap (u16 . type_index) arguments
        location = aligned offset
    in go (location + cast (length item)) rest (bytes ++ pad offset ++ item) (offsets ++ [location])

private
encoded_methods : (Signature -> Int) -> CodeLayout -> Bool -> List Signature -> List Int
encoded_methods method_index codes direct methods = go 0 (sortBy (\a,b => compare (method_index a) (method_index b)) methods) where
  go : Int -> List Signature -> List Int
  go previous [] = []
  go previous (sig :: rest) =
    let method = method_index sig
        flags = if sig.name == "<init>" then 0x10001
                else if sig.name == "<clinit>" then 0x10008 else 0x101
        offset = fromMaybe 0 (lookup (signature_key sig) codes.locations)
    in uleb (method - previous) ++ uleb flags ++ uleb offset ++ go method rest

private
layout_class_data : (Signature -> Int) -> CodeLayout -> Int -> List FrameworkClass ->
                    (List Int, List Int, Int)
layout_class_data method_index codes start classes = go start classes [] [] where
  go : Int -> List FrameworkClass -> List Int -> List Int -> (List Int, List Int, Int)
  go offset [] bytes offsets = (bytes, offsets, offset)
  go offset (cls :: rest) bytes offsets =
    let methods = own_signatures cls
        direct = filter (\m => m.name == "<init>" || m.name == "<clinit>") methods
        virtual = filter (\m => m.name /= "<init>" && m.name /= "<clinit>") methods
        item = [0, 0] ++ uleb (cast (length direct)) ++ uleb (cast (length virtual)) ++
               encoded_methods method_index codes True direct ++
               encoded_methods method_index codes False virtual
    in go (offset + cast (length item)) rest (bytes ++ item) (offsets ++ [offset])

private
implemented_interfaces : FrameworkClass -> List (FrameworkClass, List String) -> List String
implemented_interfaces requested [] = []
implemented_interfaces requested ((plan, interfaces) :: rest) =
  if requested.descriptor == plan.descriptor then interfaces
  else implemented_interfaces requested rest

||| Deterministic direct DEX 035 encoding of checked framework class plans.
||| Bounded ASCII metadata; arbitrary method bodies and fields are not claimed.
public export
encode_framework_classes_implementing : List (FrameworkClass, List String) -> Either String (List Int)
encode_framework_classes_implementing implementing = do
  let declarations = map fst implementing
  if null declarations then Left "No framework classes" else Right ()
  traverse_ validate_class declarations
  if all (all object_type . snd) implementing
    then Right () else Left "Invalid implemented interface descriptor"
  if all (\(_, interfaces) => length interfaces == length (unique interfaces)) implementing
    then Right () else Left "Duplicate implemented interface"
  let classes = sortBy (\a,b => compare a.descriptor b.descriptor) declarations
  if length classes == length (unique (map descriptor classes))
    then Right () else Left "Duplicate framework class"
  -- A class list must be acyclic. This bounded adapter accepts framework
  -- superclasses only, so declaration order cannot hide a superclass cycle.
  if any (\cls => elem cls.superclass (map descriptor classes)) classes
    then Left "App-defined superclass dependencies are unsupported" else Right ()
  let signatures = all_signatures classes
  let prototypes = sort (unique (map (\s => (s.result, s.arguments)) signatures))
  let methods = sortBy (\a,b => compare
        (a.owner, a.name, index_of (a.result, a.arguments) prototypes)
        (b.owner, b.name, index_of (b.result, b.arguments) prototypes))
        (map (\key => fromMaybe (Sig "" "" "" []) (find (\s => signature_key s == key) signatures))
             (unique (map signature_key signatures)))
  let types = sort (unique (concatMap snd implementing ++
        concatMap (\s => s.owner :: s.result :: s.arguments) signatures))
  let libraries = mapMaybe native_library classes
  let strings = sort (unique (types ++ map name methods ++ map shorty prototypes ++ libraries))
  if all plain_ascii strings && length strings < 65536 && length types < 65536 &&
     length methods < 65536 && length prototypes < 65536
    then Right () else Left "DEX metadata must be bounded non-NUL ASCII"
  let si = \value => index_of value strings
  let ti = \value => index_of value types
  let mi = \value => index_of (signature_key value) (map signature_key methods)
  let interface_lists = map (\cls => sortBy (\a,b => compare (ti a) (ti b)) (implemented_interfaces cls implementing)) classes
  let parameter_lists = unique (filter (not . null) (map snd prototypes ++ interface_lists))
  let string_off = 112
  let type_off = string_off + 4 * cast (length strings)
  let proto_off = type_off + 4 * cast (length types)
  let method_off = proto_off + 12 * cast (length prototypes)
  let class_off = method_off + 8 * cast (length methods)
  let data_off = class_off + 32 * cast (length classes)
  let (type_bytes, type_locations, after_types) = layout_type_lists ti data_off parameter_lists
  let parameter_offset : List String -> Int = \arguments => if null arguments then 0 else
        fromMaybe 0 (lookup arguments (zip parameter_lists type_locations))
  let codes = layout_code si mi after_types classes
  let (string_bytes, string_locations, after_strings) = layout_strings codes.next strings
  let (class_bytes, class_locations, after_classes) = layout_class_data mi codes after_strings classes
  let map_off = aligned after_classes
  let sections =
        [map_item 0x0000 1 0,
         map_item 0x0001 (cast (length strings)) string_off,
         map_item 0x0002 (cast (length types)) type_off,
         map_item 0x0003 (cast (length prototypes)) proto_off,
         map_item 0x0005 (cast (length methods)) method_off,
         map_item 0x0006 (cast (length classes)) class_off] ++
        (if null parameter_lists then [] else
          [map_item 0x1001 (cast (length parameter_lists)) (aligned data_off)]) ++
        [map_item 0x2001 codes.count (aligned after_types),
         map_item 0x2002 (cast (length strings)) codes.next,
         map_item 0x2000 (cast (length classes)) after_strings,
         map_item 0x1000 1 map_off]
  let map_bytes = u32 (cast (length sections)) ++ concat sections
  let size = map_off + cast (length map_bytes)
  let header = [100,101,120,10,48,51,53,0] ++ replicate 24 0 ++
        concatMap u32 [size,112,0x12345678,0,0,map_off,
          cast (length strings),string_off,cast (length types),type_off,
          cast (length prototypes),proto_off,0,0,
          cast (length methods),method_off,cast (length classes),class_off,
          size - data_off,data_off]
  let method_bytes = concatMap (\s => u16 (ti s.owner) ++
        u16 (index_of (s.result,s.arguments) prototypes) ++ u32 (si s.name)) methods
  let proto_bytes = concatMap (\p => u32 (si (shorty p)) ++ u32 (ti (fst p)) ++
        u32 (parameter_offset (snd p))) prototypes
  let definitions = concatMap (\((cls,offset),interfaces) => concatMap u32
        [ti cls.descriptor,1,ti cls.superclass,parameter_offset interfaces,0xffffffff,0,offset,0])
        (zip (zip classes class_locations) interface_lists)
  let unsigned = header ++ concatMap u32 string_locations ++ concatMap (u32 . si) types ++
        proto_bytes ++ method_bytes ++ definitions ++ type_bytes ++ codes.bytes ++
        string_bytes ++ class_bytes ++ pad after_classes ++ map_bytes
  if cast (length unsigned) /= size then Left "Internal framework DEX size mismatch" else Right ()
  let signed = take 12 unsigned ++ sha1 (drop 32 unsigned) ++ drop 32 unsigned
  let checksum = adler32 (drop 12 signed)
  Right (take 8 signed ++ map cast (u32 (cast checksum)) ++ drop 12 signed)

||| Compatibility entry point for classes without implemented interfaces.
public export
encode_framework_classes : List FrameworkClass -> Either String (List Int)
encode_framework_classes declarations = encode_framework_classes_implementing (map (\cls => (cls, [])) declarations)

public export
write_framework_classes_implementing : List (FrameworkClass, List String) -> String -> IO (Either String ())
write_framework_classes_implementing classes destination = case encode_framework_classes_implementing classes of
  Left error => pure (Left error)
  Right bytes => write_dex destination bytes

public export
write_framework_classes : List FrameworkClass -> String -> IO (Either String ())
write_framework_classes classes destination = case encode_framework_classes classes of
  Left error => pure (Left error)
  Right bytes => write_dex destination bytes
