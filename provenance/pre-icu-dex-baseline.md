# Pre-ICU DEX implementation inventory

This is the source inventory for ANDROID-NDK-MERGE-01. It distinguishes existing
implementations from the work to be compared in the next architecture study.
The starting main revision was `11edd1e0d9748d7c618413ec9f5afad52049046a`.
The ICU reconciliation branch is excluded. Source descriptions below are not
claims of a general Idriç runtime, physical-device acceptance or independent
build-producer promotion.

## Checked source to DEX

| Stage | Existing owner and reusable interface | Boundary |
| --- | --- | --- |
| Parsing, elaboration and type checking | Pinned `isomorphisms/Idric`; the custom driver registers `dex_codegen` in `dex/idric/src/Backend/DEX/Main.idr` | The backend consumes checked compiler output, not source-string patterns. |
| Intermediate source form | `Codegen.idr`: `getCompileDataWith ["dex"] False ANF`, export selection, `resolve_export_abi`, external-domain validation | Retain checked ANF and exact compiler/API/library identities. No new frontend or second ANF definition is introduced. |
| General checked lowering | `Lower.idr`: checked definition specialization, `lower_method`, explicit local register/type maps | Acyclic checked helpers, known constructors and known closures can be specialized. This is not a runtime object/closure representation. |
| Text-list lowering | `Unpack.idr`: reachable-graph selection, validated Prelude intrinsics, `lower_unpack_method` | Unpack-derived character views and checked self-tail scans have their own bounded lowering, inside the same compiler. |
| Target plan | `IR.idr`: `FilePlan`, `MethodPlan`, `Instruction`, `FrameworkValueType`, `MethodReference`, `InvocationPlan` | Integers, references and register pairs retain distinct operation families. |
| Calls and register placement | `Invoke.idr`, `Placement.idr`: word counts, compact/range invocation, `prepare_method_invocations` | Sequential virtual-register allocation and disjoint staging; parameters occupy the frame tail. This is not physical CPU register allocation or an optimizing liveness allocator. |
| Final layout | `Encode.idr`: `finalize_file_plan` returns opaque `FinalizedFilePlan` | Method ordering, placement and monotone jump widening happen once. |
| File and readable output | `encode_finalized_dex`, `render_finalized_smali`, `render_file_plan` | DEX, plan and readable smali share the finalized plan. Smali is an independent oracle/observer, never replacement candidate bytes. |

The compiler emits `.checked.anf`, `.dex.plan`, `.smali` and `.dex` evidence.
Encoding includes metadata pools, class/method data, code items, alignment,
modified UTF-8 with UTF-16 lengths/order, SHA-1 and Adler-32. Register bounds,
signed offsets, type indices and invocation word limits fail closed. Supported
instruction families include scalar/reference/wide moves, constants, selected
Int32 arithmetic/branches, widened gotos, invocation/returns, allocation and
checked casts. The opcode catalogue describes more than the implemented subset.

## Values and runtime requirements

| Source situation | Current representation or treatment | Limit |
| --- | --- | --- |
| `Int32`, `Bool`, Text, unit result | DEX scalar/Boolean register, String reference, or void | No arbitrary source-number or collection ABI is inferred. |
| Checked external domain | Validated concrete descriptor and object reference | External-domain flags and descriptor conflicts are checked. Nullness and object lifecycle are not proved. |
| Source constructor or record with known shape | Compile-time specialization and projection | Unknown runtime constructors, escaping sums/records and arbitrary heap state remain unsupported. |
| Known partial application or closure | Checked specialization | Unknown runtime closures and captured runtime environments remain unsupported. |
| Unpack-derived `List Char` | Original Text, runtime code-point array, position and length | Tails retain provenance; reconstruction must match observed head/tail. Arbitrary constructed or escaping lists are refused. |
| Self-tail character scan | Private loop values and staged simultaneous assignments | Qualified Text/Char/Boolean loop values do not establish general non-tail or mutual recursion. |
| Foreign effects | Ordered PrimIO/IO lowering; checked trailing World token removed at the boundary | Unsupported effects refuse; exceptions are not converted into success. |
| Wide target values | Invocation/encoding understands adjacent register words | General checked source allocation of wide foreign results remains unsupported. |

The unpack implementation uses Android `String.codePoints()` and
`IntStream.toArray()`, requiring API 24 for this route. Embedded NUL and
supplementary characters are exercised by its fixtures. Null Text inputs,
isolated malformed surrogates, general normalization and zero-allocation claims
are outside that qualification. Source-lowering limits remain explicit errors;
the job does not import ICU arguments, transport, heap, or recursive-call work.

## Android, JNI and packaging interfaces

| Interface | Owner | Existing behavior |
| --- | --- | --- |
| Foreign framework operations | `Foreign.idr`, `Lower.idr` | Validated static/virtual/interface calls, PrimIO constructors and explicit reference casts. Constructors allocate their own receiver and require a void JVM initializer. Casts and calls share the tagged `ForeignOperation` representation. |
| Checked inbound callbacks | `Callback.idr` | Stateless interface forwarding to actual checked exports; signatures must agree exactly. |
| Checked Activity lifecycle | `Callback.idr` | Both `activity` shorthand and explicit Activity `extends`/`override onCreate` declarations survive. Original Bundle reaches the superclass before the checked handler. Conflicting parent/lifecycle ownership is refused. |
| Native WebView shells | `EncodeCallbackShell.idr`, `callback-shell.ipkg` | Bounded native overrides for Activity, WebViewClient and WebMessageCallback, with loader and constructor code. Application behavior remains native-owned. |
| NativeActivity/View class plans | `FrameworkClasses.idr`, `examples/autogenerated/native-view-callback/` | Native methods, implemented interfaces and framework superclasses; the callback fixture owns declarations, not application state. |
| JNI | `jni/README.md` and retained adapter fixtures | Narrow native method boundary. It is not the general checked runtime or a frame loop. Historical app-specific JNI tests retain their stated external dependencies. |
| Direct checked Activity APK | `apk/build-direct-dex-activity.grease` | Existing app-owned identity, resources and signing input remain required. |
| NativeActivity APK | `apk/build-nativeactivity-apk.sh` | DEX-free by default; explicit DEX and declared NativeActivity subclasses are verified byte-for-byte and against a pinned independent disassembler. |
| Reproducibility and receipts | `apk/tests/reproducible.grease`, `apk/verify-nativeactivity-receipt.grease` | Epoch, modes, traversal, input/tool identities, signed output and hostile controls. DEX-free receipts stay v2; explicit DEX receipts use v3 including launcher, DEX and subclass-oracle identity. |

The native-class encoders are bounded adapter paths with different plan
interfaces. They do not replace or duplicate the checked compiler modules.
Whether their low-level serialization should be unified is a question for the
next study; no independent implementation is deleted here merely because the
formats overlap.

## Provenance preserved by this consolidation

| Work | Original PR and immutable source head |
| --- | --- |
| Framework calls and ordered IO | [isomorphisms/android-NDK PR #20, “Lower checked framework calls and IO directly to DEX”](https://github.com/isomorphisms/android-NDK/pull/20), `5c94120944aa50dc8dc8056ba34006aa8d38d13e` |
| Finalized layout and jump widening | [isomorphisms/android-NDK PR #23, “Widen checked DEX jumps and share finalized layout across binary and reports”](https://github.com/isomorphisms/android-NDK/pull/23), `940cf63f655ae9e2031e03a574b2ce22176af155` |
| Unpack views and tail scans | [isomorphisms/android-NDK PR #24, “Lower checked unpack-derived character views and tail scans to DEX”](https://github.com/isomorphisms/android-NDK/pull/24), `d0080ff0ad938680d319519bf484f98f540d3e89` |
| Checked interface callbacks | [isomorphisms/android-NDK PR #25, “Generate interface callbacks that forward to checked Idriç exports”](https://github.com/isomorphisms/android-NDK/pull/25), `b7a637fdbf3e3725c8113bf665333215d569ceb2` |
| Framework construction | [isomorphisms/android-NDK PR #26, “Construct native framework objects and generate checked Activity lifecycle”](https://github.com/isomorphisms/android-NDK/pull/26), `8040820ebd06e7441aab244ee7e62e727919c764` |
| Activity adapters, source loop values and Unicode encoding | [isomorphisms/android-NDK PR #27, “Generate checked Activity adapters and preserve source loop values in DEX”](https://github.com/isomorphisms/android-NDK/pull/27), `78522f32576b7c14f138a875c0c572f8243dc2eb` |
| Reproducible packaging | [isomorphisms/android-NDK PR #17, “Make NativeActivity packaging reproducible with a source epoch”](https://github.com/isomorphisms/android-NDK/pull/17), `75d2c6b88443c9cf865c30146a06b89868a182c5` |
| WebView native shells | [isomorphisms/android-NDK PR #28, “Emit direct DEX native callback shells for WebView”](https://github.com/isomorphisms/android-NDK/pull/28), `e5d82f5bfd95851da58edcd9d9b0f04b43b112fb` |
| NativeActivity callbacks and explicit DEX packages | [isomorphisms/android-NDK PR #29, “Allow declared direct DEX callbacks in NativeActivity APKs”](https://github.com/isomorphisms/android-NDK/pull/29), `84a4b44d4c87295f4c7479634552b1f6e3baa6d8` |

`FrameworkClasses.idr` was the native callback fixture's missing dependency.
It is recovered from [the original backend at c13a6a2](https://github.com/fuego-ironworks/idric-arm-thumb/blob/c13a6a223a24c211d090d2c88a395c134ed8d469/src/Backend/DEX/FrameworkClasses.idr),
original blob `1ce706303759a18123389c9db66e5b3108db16a3`; this import does not
use the ICU branch. Earlier core provenance remains in
[`migration-inventory.md`](migration-inventory.md), with its original licenses,
source branches and application-specific evidence preserved.

## Acceptance boundaries and remaining work

The checked-effects workflow pins Idriç
`ff4d852862a3942592f8ade9afde8d409d9803be`, matching compiler API and bootstrap
libraries, Grease `f19c94c6df18cddbdc1e81463e5bd689533e3c13`, and Cat Food
`609a9628d5a52860f956bf62e0914a0cd03292ae`. The WebView host workflow separately
pins Idriç `e8b9173ab2d840ef0cf212698ea2fee97bd9e807`; these two compiler pins
are explicit and are not described as one compiler build. Native audio uses
the existing pinned ai-ci ICK routes; SDK/NDK packaging retains its own tools.

Compiler exit zero alone is insufficient. Positive cases require new artifacts
and clean diagnostics; negative cases require the intended refusal and no DEX.
Finalized-layout comparisons, source/production mutants, Unicode/alias controls,
callback identity and actual IB source diagnostics remain independent checks.
ART emulator execution, package construction, installation and physical A1/C67
behavior remain distinct evidence. No phone or tablet is used as a build host.

No named source holes were found in the inspected backend modules. That does
not mean full runtime support: general heap/records/lists, runtime closures,
non-tail/mutual recursion, wide numerical operations, arbitrary subclasses,
exception handlers, field/array semantics and a complete runtime remain open.
The inherited Chez/compiler-bootstrap and shared build-producer qualification
debt is not erased by this merge. An accepted compiler fixture does not close
application storage, Shizuku, live navigation, update-signing or device work.

## Inputs for the next architecture comparison

Candidate sources include the original Idriç machine backends,
`mmhelloworld/idris-jvm` and its `dilapidated-shed` fork, Android ART/D8,
DexMaker and dexlib2/smali. The next assignment should inspect their actual
representations and runtime source against the interfaces above, record exact
revisions, and distinguish copying an existing capability from proposing a
different design. This inventory makes no comparative performance or design
verdict and starts no new compiler.
