# Program attempt: direct WebView callback shells

Status: NOT_RUN

## Purpose and intended behavior

CGW-C67-E1 needs ART classes extending Activity, WebViewClient and
WebMessagePort.WebMessageCallback. Emit their constructor, library loader and
native callback declarations directly as DEX. No Java, assembler or d8
produces candidate bytes. The application owns callback implementations in C.

## Type-system sketch

Values are ASCII class descriptors, a native library name, method names,
return descriptors and parameter descriptors. `NativeCallback` describes one
instance native method. `encode_callback_shell : String -> String -> String
-> List NativeCallback -> Either String (List Int)` is pure. The generator
writes those bytes through the existing checked `write_dex` IO primitive.

Strings, types, prototypes and methods must be deduplicated and sorted by DEX
ordering. Native methods have no code item; constructors invoke the exact
superclass constructor. Header signature and checksum cover the final bytes.
Reject invalid descriptors, duplicate names/signatures and unsupported wide
primitive callback types. The three classes are separate DEX 035 units for an
API-26+ application, not a generic checked-ANF object lowerer.

## Verification and evidence boundary

Compile the real Idriç module, generate twice, inspect with an independent DEX
parser/disassembler, then load and exercise callbacks in ART. Host structural
checks alone do not prove WebView behavior. No fallback selected. First new
capability: reusable direct Android callback metadata emission. Acceptance:
ART loads all three classes and dispatches native lifecycle and message calls.
