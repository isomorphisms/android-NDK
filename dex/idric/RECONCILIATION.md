# Canonical checked DEX and JNI reconciliation

The reusable compiler is maintained in `isomorphisms/android-NDK/dex/idric`.
Version 0.2.0 preserves the existing checked frontend/ANF handoff. DEX remains
separate from the ARM/Thumb branch and its machine-code/runtime work.

## Inputs and ownership

The fresh default comparison is retained in `reconciliation-defaults.tsv`.
Canonical default: `11edd1e0d9748d7c618413ec9f5afad52049046a`.
Original backend default: `6ecf378dd3e8dac59091ce8d7f3c3f315f43e4a5`.
Thirteen backend files have identical blobs, one backend README diverges, and
FrameworkClasses is absent from the canonical default. Package/fixture
differences are listed individually. Historical source and commit ancestry
remain in their original repositories; no historical branches are deleted.

Generic checked effects, invocation placement, finalized layout, callbacks,
Activity adapters and unpack views are recovered from android-NDK
`78522f32576b7c14f138a875c0c572f8243dc2eb`. Their implementation and original
tests are retained. FrameworkClasses, interfaces, the newer ICK-aware JNI mock
test and missing Reddit/Wegert integration fixtures come from the original
backend `c13a6a223a24c211d090d2c88a395c134ed8d469`. Unicode MUTF-8 and UTF-16
ordering already exist on the canonical checked-effects line; the two copies
were compared rather than replacing that newer encoder with the old one.

The WebView native shell at e5d82f5bfd95851da58edcd9d9b0f04b43b112fb is
retained through a compatible EncodeCallbackShell facade over FrameworkClasses.
Its four descriptor/wide/duplicate/library refusal cases and three generated
classes remain tests. The native View plan at
84a4b44d4c87295f4c7479634552b1f6e3baa6d8 is retained and independently decoded.
Both open-branch source locations remain attributable; neither adds another
generic writer. Existing branch histories and APK/native acceptance remain
separate from this reconciliation's host receipts.

Application-specific EncodeNativeActivity and EncodeRedditCli now express
their preserved constructor/JNI/entrypoint instructions as shared typed plans.
EncodeNativeActivityShell supplies its preserved manifest-loaded shell through
the same writer too. The retired application serializers remain in Git history.
Their native bodies and
application semantics are not promoted into generic compiler behavior. Their
historical phone receipts remain historical evidence, not current acceptance.

## Implemented compiler advancement

Checked scalar helpers are discovered through all branches of the ANF call
graph with cycle detection. Concrete Int32/Text/Bool helpers are emitted as
methods with checked descriptors; their callers use real invoke-static,
including recursion, mutual recursion and cross-module calls. Invocation
placement and six-word argument staging reuse the existing implementation.
Polymorphic helpers retain existing checked specialization. General runtime
closures and heap values do not acquire an invented ABI.

FrameworkClasses now translates its public declarations to the same typed
FilePlan/MethodPlan and Backend.DEX.Encode implementation used by checked code.
The common writer supports multiple classes, native static/virtual declarations,
constructors, library initialization, method references and shared identifier,
type-list, code, class-data, string and checksum layouts. Native methods have
code offset zero. Callback classes preserve public/nonfinal metadata; ordinary
checked utility classes retain public/final metadata. The compatibility
constructors remain available. App-defined inheritance, fields and general
algebraic object layouts remain explicit gaps.

The checked-effects line's expanded source plan ABI uses FrameworkValueType:
scalar plans use ExistingValue wrappers. This is package version 0.2.0;
consumers rebuild against the matching sources/API, rather than mixing 0.1
TTC caches with the new plan schema. Preserved C/JNI names, signatures and
protected callbacks are checked against the application oracles.

Effectful roots no longer enter the pure unpack-view lowerer just because a
transitive helper uses unpack. Checked definitions are retained before a
lowering rejection. The source compiler's published Driver error-status repair
is required; nonzero refusal is checked independently of diagnostic text.

## Real ICU boundary

ICU source tree `8f76a2a3ede74e85f766d17ff18a1a1f8d8c4eaa` is the actual
published ICU continuation (local receipt commit
`76c4801608c7da721d2d31c79ad530b5cb9af711`). Its source was not replaced.
The original Main.main IO ABI refusal is passed. Current first failure:

`No checked helper body for DEX call System.prim__getArgCount`

The compiler rejects that source with exit 1 and emits no classes.dex. Missing
runtime arguments include getArgCount/getArg, their source Int representation
and the runtime List Text result. Subsequent requirements include runtime lists,
records, constructors/cases, escaping closures as needed, ICU string/byte
primitives, output/exit/resource operations, checked native declarations and
the ART main(String[]) adapter. A missing getArgCount binding does not prove
the rest of those requirements implemented or tested.

ICU's native HTTP/TLS/framing/redirect/proxy implementation remains usable and
unchanged by this compiler work. No compiler stubs, C rewrite of ICU, Java,
Kotlin, Gradle, d8, smali candidate generation or new refC dependency was added.

## Reproduction and evidence

`verify-reconcile.grease` runs the preserved host suites and independently
decodes the shared class file. `verify-sources.grease` requires fresh candidate
files, independent DEX parsing, deterministic output and nonzero unsupported
source refusal. `examples/autogenerated/checked-calls/boot-emulator.grease`
runs a separately assembled ai-ci observer against the source-generated DEX,
checks the emulator identity, compares pulled bytes, and requires a compiled
wrong-helper mutation to fail with status 73. Smali supplies only the observer.

Detailed results, source/compiler pins and artifact hashes are recorded in
`reconciliation-receipt.tsv`. Host checks, independently parsed DEX, ART
execution and physical MIRO A1/C67 execution remain separate rows. No real ICU
DEX, Cat Food package or physical-device acceptance is claimed.
