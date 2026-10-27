# Checked native boundary contracts

## Runtime qualification extension: type/effect sketch

Keep `native_identity : Text → PrimIO Text` as the checked nonnull boundary.
Add one deliberately legacy `PrimIO Text` producer of a null String and pass
its result to that explicit identity boundary. The producer is a fixture-only
escape from the nonnull promise; the explicit adapter must refuse the input
before the C identity function runs. The same source and legacy map must still
execute Unicode identity and render the legacy null result as `null`.

The observer must retain stdout, stderr, process status and AndroidRuntime
logcat for each refused call. Android's app_process handler logs uncaught
exceptions before killing its process; `Killed` alone is insufficient evidence.
Only a completed nonzero exit with the exact expected exception diagnostic
counts as rejection. Candidate DEX and native-library bytes must be pulled back
and compared with the built input. This extension adds no parsing primitive,
retained ownership, asynchronous callback or alternate code-generation stage.

## Type/effect sketch, before implementation

This bounded attempt covers checked `PrimIO` actions with a trailing World token,
integer or Text inputs and integer/Text/Unit results. Source integers must fit the
declared JVM int/long at the crossing. Text is a Java String, not an implicit
UTF-8 byte buffer. JNI owns native argument local references until return.

The legacy three-column map remains accepted with its historical conversions
and null behavior. Its native ownership/lifetime policy is **unqualified**.
An explicit contract admits only synchronous execution on the calling thread,
borrowed local references, nonnull strings and managed-exception propagation.
No native body proof is inferred from this declaration.

Central operations:

- `parse_native_boundary_row : List String → Either String ParsedNativeBoundary`
- `native_contract : JNIService → NativeBoundaryContract`
- `heap_foreign_linked` checks source/target signatures and emits the adapter.

Invariants: explicit string inputs/results are checked nonnull; numeric narrowing
is exact; failed conversion happens before invoking native code; pending JNI
exceptions unwind through ART without a synthetic success result. Retained
references, asynchronous calls and callbacks are rejected by this bounded
contract instead of receiving invented ownership rules.

Verification will use Idriç host contract tests, checked source compilation and
independent DEX decoding. A small native C fixture supplies a null return,
managed exception and synchronous string identity. Host success does not prove
ART/JNI execution; native integration execution remains separate evidence.

## Local result

Frontend: pinned Idriç 740bbf2b1. `--source-dir src --check
src/Backend/DEX/Codegen.idr` completed successfully after correcting an import
and preserving actual record projections. The checked `NativeIdentity.idric`
source also checks. The host NativeContractChecks executable returned:

```text
PASS JNI explicit contracts, legacy behavior and refusal controls
```

Both Grease scripts parsed successfully with the maintained Grease executable
at `/workspace/scratch/58fb4da72caa/tools/grease/bin/grease`; its host ASan build
requires `ASAN_OPTIONS=detect_leaks=0` because LeakSanitizer cannot inspect this
container's process tree. This disables host leak inspection only; it is not JNI
leak evidence. Full backend native compilation is serialized by the parent
job to avoid concurrent Chez compilation memory exhaustion.

The preserved C fixture and observer provide null-result, pending-exception and
pre-call narrowing observations for the combined build's API29/API34 ART lane.
Native runtime execution and physical-device acceptance are NOT_RUN locally.

Smallest further work: qualify the combined emitted candidate and this native
library on ART. Retained/asynchronous references still need a real explicit
ownership/release design; this repair rejects them instead of admitting them.

The repeated scoped-reference fixture uses an Int countdown entered at 10,000.
Its first check correctly refused a totality claim for arbitrary signed input;
the fixture now explicitly uses covering, rather than asserting a nonexistent
termination proof for negative input.

## Combined emission dependency discovered

The first complete checked emission rejected the original fixture's CLI
`cast digits : Text → Int` with `Managed DEX unsupported numeric cast from
String`. General text-to-number conversion is a separate unsupported runtime
primitive; the repair does not claim to implement it.

The fixture now runtime-selects the exact strings `2147483647` and `2147483648`
and passes their checked integer values through the same generated JNI wrapper.
This keeps the admitted/refused boundary and observer's native-entry marker,
without making unrelated parsing support a prerequisite for native narrowing.
Null results, pending native exceptions and repeated references remain covered.

The bounded fixture then emitted successfully through the combined repaired
native compiler. Host contract controls passed; explicit and legacy maps emitted
and independently decoded; retained-global refusal exited unsuccessfully and
left no candidate DEX. Explicit DEX: 25,960 bytes, SHA-256
`f39e0ee9fd381587a097b2aadd21dc8c535477c042aa77adc0fbf9faf8ca5839`.
Legacy DEX: 25,708 bytes, SHA-256
`7f87e1d5a79d811ff2f17c50e53498b0f1afb431f4a4ee2a4c19cdf703ea7229`.

Independent baksmali output shows the native narrowing wrapper calls
`__idricIntExact` before `narrow(I)I`. Its guard checks BigInteger bitLength
against 31 and throws ArithmeticException before extracting an int on overflow.
Explicit string guards are present and absent from the legacy decoding.
These are host generation/decoder observations; C cross-build and ART execution
remain pending in the separate API29/API34 workflow.
