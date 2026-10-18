# Program attempt: direct WebView callback shells

Status: HOST_PASS at source `950fef409148e91fc3ed59b0fbf64368f1ad0438`.

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

## Observed result

[Host qualification run](https://github.com/isomorphisms/android-NDK/actions/runs/39094757573)
compiled the real module and generator with Idriç
`e8b9173ab2d840ef0cf212698ea2fee97bd9e807`. All three DEX units regenerated
byte-for-byte; independent header/hash checks and pinned baksmali disassembly
passed. Invalid descriptor, wide callback, duplicate callback and invalid
library controls rejected. The retained artifact ZIP has SHA-256
`580e2c1542b9b0b190fb7fa2a8d80523e33d943d5f6bab24bbc02b96bf039996`.

Earlier source `84bbfb9a1808e388ff6ccb4347415f50b3cfc429` failed because
`parameters` is reserved syntax. The field is now `parameter_types`; the
failed source and job log remain in history. The initial host API setup also
missed installed standard packages. The adapter now has a bounded standalone
package and does not depend on the compiler API. Local bootstrap stopped at
missing GMP headers; denied local package installation was not bypassed.
Verification ran on the declared hosted build instead. No fallback compiler
or Java-producing route was used.

This is host evidence only. The application separately consumes the exact
qualified `950fef4` source artifact for its Android WebView qualification.
It is not a generic checked-ANF object/lifecycle lowering or physical-device
acceptance. Existing shared compiler/build-policy qualification remains a
separate gate.
