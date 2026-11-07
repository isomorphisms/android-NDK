# Source values carried through checked loops

Purpose: reduce the actual retained-source compiler failure before selecting
a general heap representation. The unpack lowerer already carries Char and
Text registers, but its initial loop-value copier does not materialize literal
Char or literal Text as those same domains.

Types: `scan_for : Char → List Char → Int32` examines runtime source text;
`scan_marker : Text → List Char → Text` carries a source-defined fallback.
Exports accept Text and return Int32 or Text. Unpack-derived character suffixes
keep their immutable text/code-point array/position representation. Literal
characters become CharacterRegister values; literal text becomes TextRegister.
Neither is reinterpreted as a source integer, erased value or framework object.

Invariants: Unicode characters retain their full code points; loop arguments
are copied before simultaneous assignment; text identity/value is preserved;
aliasing and register placement remain checked. Unbounded Number/Integer
values must not silently become Int32. Source constructors, changing lists
and unknown closures retain their refusal until separately qualified.

The new small program and the original IB NativeSourceProjection consumer
must be checked and compiled through the actual Idriç API/direct DEX path.
Host execution, independent DEX parsing, external ART calls and physical-device
acceptance remain separate. No browser parser rewrite or Java fallback.
Actual baseline compilation rejects LoopValues with the original generic
loop-value diagnostic. Literal Char/Text materialization advances that exact
source to the binary encoder, where its Greek text exposes a separate ASCII-only
string-data restriction. This is a real lowering transition, not DEX success.

The unchanged IB consumer identifies a different initial value: Bits8 literal
0 in IB.Information.tokenize_chars, whose source parameter is Bool. Admit only
the proven 0/1 byte-flag range and preserve BooleanRegister's loop-assignment
invariant. Wider bytes and unbounded Number values retain refusal. The actual
WideLoopValue control reports unbounded Integer literal 0 in advance_count.

String data follows the [AOSP DEX format](https://source.android.com/docs/core/runtime/dex-format):
UTF-16 length, modified UTF-8, encoded NUL, surrogate pairs and UTF-16 ordering.
StringEncodingChecks holds independently selected expected byte sequences;
LoopValueChecks holds source behavior. Its encoding entry point deliberately
uses `covering`: the inherited ULEB128 encoder is not proven total. This is a
host test contract, not a weakening of the maintained source programs.

Actual local verification used Idriç
2734ac5a86610eddfab73b1644d72b4ac85a65ee, the checked backend patch on
5d9c5eaaa6bb303994819214c996399bb1840f20, and Grease f19c94c6df18cddbdc1e81463e5bd689533e3c13
with source 6d29702a10ea9eb72a43950554dbcd4174d07a89. The existing Chez bootstrap
and development Grease launcher remain unqualified producer dependencies.
No alternate application compiler or backend was selected.

All 10 source behavior checks and 8 DEX string-data/order checks execute on
the host. The actual driver emits LoopValues and both source mutations;
AOSP Android 14 `dexdump` independently verifies and disassembles all three.
WideLoopValue and WideByteLoop both typecheck, then refuse direct DEX with
the unbounded-Integer and binary-flag diagnostics respectively; neither emits
a DEX file. The byte fixture deliberately uses a raw byte only to demonstrate
the unsupported representation boundary.

`verify.grease GREASE BACKEND CORE SCHEME DRIVER BACKEND_TTC DEXDUMP NEW_OUTPUT`
runs those exact host, emission, parsing and refusal controls. All path inputs
are explicit and absolute; reused evidence is refused. `build-driver.grease`
builds the inherited host driver, while `probe.grease` preserves the actual
checked source and diagnostics. Flexible Pipes' existing Python controller
recorded this command-stage execution; registered model dispatch and independent
AICI producer promotion remain separate and were not performed.

The first probes raced the unfinished driver build and failed setup. Those
failures remain in their receipts. A host encoding test also exposed its
unproved totality dependency before the explicit covering annotation; it was
not counted as execution. Grease rejected a quoted-prefix glob in the combined
verifier; explicit input files corrected that error. Fresh evidence directories
then passed the combined verification.

The external smali oracle calls the actual emitted methods for empty/ordinary
source, linefeeds, supplementary characters, carried Unicode text and Boolean
flags. It also requires an executed false-flag source mutation to fail with
`FAIL true flag`, and an executed changed-text mutation to fail with
`FAIL Unicode fallback`, both with exit 73. Its assembly passes locally.
ART is a separately required workflow stage; local host execution is not ART.

The unchanged IB NativeSourceProjection consumer now passes source checking
and gets beyond the byte flag, then refuses with:
`DEX unpack cannot reinterpret a source object as an integer: source constructor _builtin.NIL in checked helper IB.Information.tokenize_chars`.
It emits no DEX. Its changing character/token accumulators need a checked
first-order collection representation, followed by the existing recovered
records. This remains the first concrete language blocker; it is not a reason
to restore a Java parser or introduce another document owner. Acceptance must
execute that original retained-source consumer on actual DEX/ART.
