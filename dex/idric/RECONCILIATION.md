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

## Managed ICU runtime continuation

`Backend.DEX.Heap` now lowers the command's checked ANF graph, including
constructors and fields, recursive helpers, copied partial-application captures,
closure application, fixed-width integer restoration, Unicode character-list
conversion, ordered bindings, standard output and process exit. Runtime argument
services call the existing `Backend.DEX.RuntimeArgs` adapter. All methods use
the canonical typed plan, placement, layout and serializer.

The command path currently requires one `IO ()` export and supports up to twelve
checked arguments per internal function. It does not promise stack-safe tail
calls, arbitrary primitives or a public ABI for ordinary heap data. Unsupported
foreign declarations and primitives remain compiler errors.

An explicit `--directive jni-map=PATH` binds checked foreign declarations to JNI
method descriptors. The TSV starts with `library_property PROPERTY`, followed
by convention, method name and descriptor rows. Integer narrowing checks the
source value before crossing JNI. A class initializer loads exactly the path
supplied by that property; no native or application fallback is selected.

The maintained ICU source at `b1c19dc281e5e7d3d326c9275093fb379bafd4bd`, with
Idric-Net `b21801b72acb8ab835c297bbe298af8599550134`, now emits a DEX without
changing its `Main.idric` or transport implementation. See
`examples/autogenerated/icu-runtime/attempt.md` and the source/ART verification
entrypoints there. Generation and independent decoding are distinct from ART
network behavior, packaging and each physical device. Current acceptance is
tracked by [android-NDK PR #30, “Canonicalize DEX/JNI and execute checked recursive calls”](https://github.com/isomorphisms/android-NDK/pull/30).

## Checked exports over the managed runtime

`--directive managed-exports` explicitly selects the existing checked managed
graph behind the admitted Text/Int32/Bool/opaque-reference export ABI. Ordinary
source lists, records and closures retain their private runtime representation;
they do not become external Java object descriptors. The boundary validates
checked arity, supplies the IO World token only for an IO body, and marshals
validated framework calls, constructors and casts through the same typed plan.
Other scalar/view exports and command entrypoints keep their existing routes.

The unchanged IB `SearchIntentRequest` and pure `NativeSourceProjection` now
emit and independently decode through that explicit mode. This does not turn
the command entrypoint into an Activity or claim an installed receiver. Source
mutations, exact Unicode/Int32 expectations and actual Android runtime tests
are in `examples/autogenerated/managed-exports/`; its attempt record separates
the local generation checkpoint from hosted ART, APK and physical acceptance.

## Historical argument-adapter checkpoint

ICU source tree `8f76a2a3ede74e85f766d17ff18a1a1f8d8c4eaa` is the actual
published ICU continuation (local receipt commit
`76c4801608c7da721d2d31c79ad530b5cb9af711`). Its source was not replaced.
The original Main.main IO ABI refusal passed. At that checkpoint the first failure was:

`No checked helper body for DEX call System.prim__getArgCount`

The compiler rejects that source with exit 1 and emits no classes.dex. A reusable
Backend.DEX.RuntimeArgs adapter now produces a direct-DEX main(String[]) that
stores the real ART argv, invokes a previously checked nullary void method,
and exposes __idricArgCount()J and __idricArg(J)Ljava/lang/String;. The count
uses 64-bit arithmetic so even a maximum-sized Java array cannot overflow
when adding the synthetic executable-name slot. The index conversion uses
Math.toIntExact, refusing out-of-range Int values instead of truncating.
This is an unconnected runtime adapter, not yet a checked System primitive
mapping or an ICU execution claim. The
argument-array boundary now has typed DEX array-length, aget-object and
int-to-long operations, with directly encoded proof methods and rejected
out-of-range register plans. A direct-DEX static reference field now stores the real ART String[] during
the probe's entrypoint, and separately generated zero-argument read methods
recover the count and values. The class-data/field-id writer and sget-object/
sput-object encodings share the canonical encoder; fieldless consumers retain
their original layouts. An independent smali-only ART observer executes
the direct DEX methods with zero and two incoming arguments; its wrong
+2 count candidate must exit unsuccessfully. CI and phone results remain
separate from committed source and host validation. These are target instructions, not an
implementation of System.prim__getArgCount: no generated ART main(String[])
entrypoint yet binds an argument array to checked Idriç code. Missing
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
DEX, Cat Food package or physical-device acceptance is claimed by that historical receipt.
