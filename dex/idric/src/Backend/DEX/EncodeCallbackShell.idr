module Backend.DEX.EncodeCallbackShell

import Backend.DEX.Encode
import Backend.DEX.Hash
import Data.List
import Data.Maybe
import Data.String

%default covering

public export
record NativeCallback where
  constructor MkNativeCallback
  name : String
  result : String
  parameter_types : List String

private
u16 : Int -> List Int
u16 n = [n `mod` 256, (n `div` 256) `mod` 256]

private
u32 : Int -> List Int
u32 n = [n `mod` 256, (n `div` 256) `mod` 256,
         (n `div` 65536) `mod` 256, (n `div` 16777216) `mod` 256]

private
leb : Int -> List Int
leb n = if n < 128 then [n] else (n `mod` 128 + 128) :: leb (n `div` 128)

private
align4 : Int -> Int
align4 n = n + ((4 - n `mod` 4) `mod` 4)

private
pad4 : Int -> List Int
pad4 n = replicate (cast (align4 n - n)) 0

private
replace : Int -> List Int -> List Int -> List Int
replace offset value bytes = take (cast offset) bytes ++ value ++
                            drop (cast (offset + cast (length value))) bytes

private
index : Eq a => a -> List a -> Either String Int
index requested = go 0
  where
    go : Int -> List a -> Either String Int
    go n [] = Left "callback shell metadata index missing"
    go n (x :: xs) = if requested == x then Right n else go (n + 1) xs

private
ascii : String -> Bool
ascii s = all (\c => ord c >= 32 && ord c <= 126) (unpack s)

private
objectType : String -> Bool
objectType s = ascii s && length (unpack s) <= 512 &&
               isPrefixOf ['L'] (unpack s) &&
               isSuffixOf [';'] (unpack s) && length (unpack s) > 2 &&
               all (\c => isAlphaNum c || elem c ['L', '/', '_', '$', ';']) (unpack s) &&
               not (elem ';' (reverse (drop 1 (reverse (unpack s)))))

private
valueType : String -> Bool
valueType s = elem s ["Z", "I"] || objectType s

private
short : String -> String
short s = if objectType s then "L" else s

private
shorty : (String, List String) -> String
shorty (r, ps) = short r ++ concat (map short ps)

private
codeItem : Int -> Int -> Int -> List Int -> List Int
codeItem registers incoming outgoing instructions =
  u16 registers ++ u16 incoming ++ u16 outgoing ++ u16 0 ++ u32 0 ++
  u32 (cast (length instructions) `div` 2) ++ instructions

private
mapItem : Int -> Int -> Int -> List Int
mapItem kind count offset = u16 kind ++ u16 0 ++ u32 count ++ u32 offset

private
stringsFrom : Int -> List String -> (List Int, List Int, Int)
stringsFrom offset [] = ([], [], offset)
stringsFrom offset (s :: rest) =
  let chars = map ord (unpack s)
      item = leb (cast (length chars)) ++ chars ++ [0]
      (bytes, offsets, end) = stringsFrom (offset + cast (length item)) rest
  in (item ++ bytes, offset :: offsets, end)

private
typesFrom : Int -> List (List String) -> List String ->
            Either String (List Int, List Int, Int)
typesFrom offset [] types = Right ([], [], offset)
typesFrom offset (ps :: rest) types = do
  indices <- traverse (\p => index p types) ps
  let start = align4 offset
  let item = u32 (cast (length ps)) ++ concatMap u16 indices
  (bytes, offsets, end) <- typesFrom (start + cast (length item)) rest types
  Right (pad4 offset ++ item ++ bytes, start :: offsets, end)

private
prototypeBytes : List String -> List String -> List (List String) -> List Int ->
                 (String, List String) -> Either String (List Int)
prototypeBytes strings types parameterLists offsets prototype = do
  s <- index (shorty prototype) strings
  r <- index (fst prototype) types
  p <- case snd prototype of
    [] => Right 0
    ps => do i <- index ps parameterLists
             case getAt (cast i) offsets of
               Nothing => Left "callback parameter-list offset missing"
               Just offset => Right offset
  Right (u32 s ++ u32 r ++ u32 p)

private
methodBytes : List String -> List String -> List (String, List String) ->
              (String, String, (String, List String)) -> Either String (List Int)
methodBytes strings types prototypes (owner, name, signature) = do
  c <- index owner types
  p <- index signature prototypes
  n <- index name strings
  Right (u16 c ++ u16 p ++ u32 n)

private
nativeEntries : Int -> List Int -> List Int
nativeEntries previous [] = []
nativeEntries previous (i :: rest) =
  leb (i - previous) ++ leb 0x101 ++ leb 0 ++ nativeEntries i rest

||| One Android-facing class per DEX unit. Native overrides carry no bytecode;
||| the constructor and loadLibrary initializer are directly encoded. API 21+
||| ART loads the resulting classes.dex/classes2.dex/... without a Java build.
public export
encode_callback_shell : String -> String -> String -> List NativeCallback ->
                        Either String (List Int)
encode_callback_shell descriptor superclass library callbacks = do
  if objectType descriptor && objectType superclass && descriptor /= superclass
     && ascii library && not (null (unpack library)) && length (unpack library) <= 128
     && all (\c => isAlphaNum c || c == '_') (unpack library)
    then Right () else Left "invalid callback class or native library"
  if null callbacks || length callbacks > 16 then Left "invalid callback count"
    else Right ()
  let keys = map (\c => (c.name, (c.result, c.parameter_types))) callbacks
  if length (nub keys) /= length keys then Left "duplicate native callback"
    else Right ()
  if all (\c => ascii c.name && not (null (unpack c.name)) &&
               length (unpack c.name) <= 128 && length c.parameter_types <= 16 &&
               all (\x => isAlphaNum x || x == '_') (unpack c.name) &&
               (c.result == "V" || valueType c.result) &&
               all valueType c.parameter_types) callbacks
    then Right () else Left "unsupported callback signature"
  let voidProto = ("V", the (List String) [])
  let loadProto = ("V", ["Ljava/lang/String;"])
  let prototypes = sort (nub (voidProto :: loadProto :: map snd keys))
  let methods = sort ((superclass, "<init>", voidProto) ::
                     ("Ljava/lang/System;", "loadLibrary", loadProto) ::
                     (descriptor, "<init>", voidProto) ::
                     (descriptor, "<clinit>", voidProto) ::
                     map (\(n, p) => (descriptor, n, p)) keys)
  let types = sort (nub ([descriptor, superclass, "Ljava/lang/String;",
                         "Ljava/lang/System;"] ++
                         concatMap (\(r, ps) => r :: ps) prototypes))
  let strings = sort (nub (["<init>", "<clinit>", "loadLibrary", library] ++
                          types ++ map fst keys ++ map shorty prototypes))
  if length strings > 65535 || length types > 65535
    then Left "callback metadata exceeds DEX index limit" else Right ()
  let stringOff = 112
  let typeOff = stringOff + 4 * cast (length strings)
  let protoOff = typeOff + 4 * cast (length types)
  let methodOff = protoOff + 12 * cast (length prototypes)
  let classOff = methodOff + 8 * cast (length methods)
  let dataOff = classOff + 32
  let parameterLists = sort (nub (filter (not . null) (map snd prototypes)))
  (typeData, parameterOffsets, afterTypes) <- typesFrom dataOff parameterLists types
  superInit <- index (superclass, "<init>", voidProto) methods
  load <- index ("Ljava/lang/System;", "loadLibrary", loadProto) methods
  libraryIndex <- index library strings
  let constructor = codeItem 1 1 1
        (u16 0x1070 ++ u16 superInit ++ u16 0 ++ u16 0x000e)
  let loader = codeItem 1 0 1
        (u16 0x001a ++ u16 libraryIndex ++
         u16 0x1071 ++ u16 load ++ u16 0 ++ u16 0x000e)
  let initOff = align4 afterTypes
  let loaderOff = align4 (initOff + cast (length constructor))
  let codeData = pad4 afterTypes ++ constructor ++
                 pad4 (initOff + cast (length constructor)) ++ loader
  let afterCode = loaderOff + cast (length loader)
  let (stringData, stringOffsets, afterStrings) = stringsFrom afterCode strings
  initMethod <- index (descriptor, "<init>", voidProto) methods
  loaderMethod <- index (descriptor, "<clinit>", voidProto) methods
  nativeIds <- traverse (\(n, p) => index (descriptor, n, p) methods) keys
  let direct = sort [(loaderMethod, 0x10008, loaderOff),
                     (initMethod, 0x10001, initOff)]
  let directBytes = encodeDirect 0 direct
  let classData = leb 0 ++ leb 0 ++ leb 2 ++ leb (cast (length nativeIds)) ++
                  directBytes ++ nativeEntries 0 (sort nativeIds)
  let mapOff = align4 (afterStrings + cast (length classData))
  let entries = [(0x0000, 1, 0),
                 (0x0001, cast (length strings), stringOff),
                 (0x0002, cast (length types), typeOff),
                 (0x0003, cast (length prototypes), protoOff),
                 (0x0005, cast (length methods), methodOff),
                 (0x0006, 1, classOff),
                 (0x1001, cast (length parameterLists), align4 dataOff),
                 (0x2001, 2, initOff),
                 (0x2002, cast (length strings), afterCode),
                 (0x2000, 1, afterStrings), (0x1000, 1, mapOff)]
  let mapData = u32 (cast (length entries)) ++
                concatMap (\(k, n, o) => mapItem k n o) entries
  let fileSize = mapOff + cast (length mapData)
  typeIds <- traverse (\t => do i <- index t strings; Right (u32 i)) types
  protoIds <- traverse (prototypeBytes strings types parameterLists parameterOffsets) prototypes
  methodIds <- traverse (methodBytes strings types prototypes) methods
  classType <- index descriptor types
  superType <- index superclass types
  let classDef = u32 classType ++ u32 0x1 ++ u32 superType ++ u32 0 ++
                 [255,255,255,255] ++ u32 0 ++ u32 afterStrings ++ u32 0
  let header = [100,101,120,10,48,51,53,0] ++ replicate 24 0 ++
               concatMap u32 [fileSize,112,0x12345678,0,0,mapOff,
                              cast (length strings),stringOff,
                              cast (length types),typeOff,
                              cast (length prototypes),protoOff,0,0,
                              cast (length methods),methodOff,1,classOff,
                              fileSize - dataOff,dataOff]
  let bytes = header ++ concatMap u32 stringOffsets ++ concat typeIds ++
              concat protoIds ++ concat methodIds ++ classDef ++ typeData ++
              codeData ++ stringData ++ classData ++
              pad4 (afterStrings + cast (length classData)) ++ mapData
  if cast (length bytes) /= fileSize then Left "callback DEX layout mismatch"
    else Right ()
  let signed = replace 12 (sha1 (drop 32 bytes)) bytes
  Right (replace 8 (u32 (cast (adler32 (drop 12 signed)))) signed)
  where
    encodeDirect : Int -> List (Int, Int, Int) -> List Int
    encodeDirect previous [] = []
    encodeDirect previous ((i, flags, offset) :: rest) =
      leb (i - previous) ++ leb flags ++ leb offset ++ encodeDirect i rest
