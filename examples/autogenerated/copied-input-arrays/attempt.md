# Typed copied input arrays through checked DEX and JNI

## Type sketch before implementation

The source constructs ordinary records and lists of binary64 coefficients and
signed Int32 xyz powers. Distinct concrete `[external]` domains represent
`java.nio.DoubleBuffer`, `java.nio.IntBuffer`, `double[]` (`[D`) and `int[]`
(`[I`). Checked framework declarations bind each source domain to exactly one
descriptor. Only `[D` and `[I` are admitted by this prerequisite; Float32,
reference arrays, nested arrays and arbitrary array casts remain refused.
Method/constructor owners still require class descriptors; an admitted array
value descriptor cannot become a declaring owner or `new-instance` target.

The platform buffer is a construction tool inside the source, not the native
ABI. The actual native handoff is `(IIIIIII[D[I)J`: version, family degree,
five Int32 offsets, binary64 coefficients and interleaved xyz Int32 powers.
The selected native implementation validates and copies the inputs during the
calling-thread invocation, publishes an immutable native-owned snapshot and
returns an opaque signed 64-bit handle. It retains neither local references
nor borrowed/pinned array memory beyond return.

The next source boundary is the native-owned numeric handle itself. After
creation it remains `Int64`, while synchronous scalar JNI methods admit exact
`Int64`↔`J` and `Int32`↔`I` arguments/results, including release `(J)V` and
diagnostic/release-result `(J)I`. This belongs to the existing synchronous
scalar/String contract and adds no managed-reference retention policy. Legacy
unbounded `Int` conversions stay compatible; fixed-width declarations with
incompatible descriptors must refuse. A real source fixture will create the
array snapshot, observe it through typed scalar APIs and release it before
return, with independent bit and post-release ownership observations.

The application then returns this handle through an explicit signed
`Int64`↔`J` source export, including `Text → IO Int64`. Any export with an
Int64 argument/result uses the existing managed boundary, which counts two
incoming/result words and boxes/unboxes signed LongValue. The older narrow
scalar lowerer does not own wide parameter layout and must never receive these
exports. Pure/IO runtime identities and actual snapshot creation will qualify
that bridge, including signed extremes and a long parameter before an Int32
parameter. Default `Int` and `Double` exports remain refused.

A new opt-in JNI policy is:
`current-thread synchronous borrowed-local nonnull-inputs copy-input-arrays propagate-exceptions`.
The compiler checks exact Int32/Int64 primitive signatures, concrete external
array source domains, descriptor consistency, runtime array type checks and
nonnull input references before entering the native method. The policy is a
checked declaration and fixture evidence, not proof that arbitrary C code
copies its inputs. Legacy and scalar-only policies stay separate; retained,
asynchronous, nullable, output-array and broader array contracts remain refused.

Qualification must follow actual `.idric` source through direct DEX emission,
independent decode and generated native methods into the C fixture. Independent
ART observations cover exact bits/lengths, null/type/shape refusal and Java
array changes after native return. Native fixtures own their C allocation,
validation, copy and release behavior; no AST, coefficient string encoding or
alternate candidate assembler implements the source semantics.

## Implemented boundary and observed qualification

`Foreign.idr` admits `[D` and `[I` as reference descriptors only. Existing
external-domain validation checks the source type flag and rejects inconsistent
descriptor constraints. `NativeContract.idr` adds the separate opt-in policy;
its typed source constraints join the framework constraints before exports are
resolved. `Heap.idr` checks the runtime array type and nonnull reference before
the native invocation. New Int32/Int64 primitive matching belongs only to this
contract; legacy/scalar adapters keep their original behavior and refuse arrays.
The legacy map parser rejects array rows even when unused by the source graph,
so an unqualified native array declaration cannot bypass the new contract.

The actual `CopiedSurface.idric` producer uses records, recursive lists,
platform indexed writes and real primitive backing arrays. It emits direct DEX
with native `copySurface(IIIIIII[D[I)J`, seven scalar words and two array
reference words. The native handle stays Int64 inside the source; the public
observer exports use the existing Int32/reference ABI. Source buffer mutations
after return are observed independently through the native snapshot.

This real combined source also exposed a directive-routing defect: after the
JNI map was parsed, the explicit managed-export path sent it to the callback
parser. That path now removes the consumed map directive before callback
processing. Other entry lanes retain their existing directive refusals.

The exact recovered frontend builds all 21 backend modules and the driver.
`CopiedArrayContractCheck.idr` executes its PASS result for source descriptor
constraints, exact primitive widths, two array type/nonnull guards, nine native
argument words and finalized encoding. Inherited scalar/legacy JNI contract,
encoder and binary64 plan checks also execute their PASS results. Actual source
generation succeeds and pinned baksmali independently decodes the NIO array
construction, guards and generated native declaration/invocation. The separate
observer assembles and decodes. The maintained Grease scripts parse with the
recovered exact pinned Grease implementation.

Repeated positive source builds retain identical bytes. A compiled source
mutation changes the runtime coefficient input before array construction and
emits distinct, independently decodable bytes. Sixteen actual source/map
negative cases reject without a candidate, covering ordinary/conflicting array
domains through framework and native calls, broader arrays, array owners and
constructors, unused/unqualified legacy rows and unsupported copy policies.
Legacy and scalar/String explicit JNI sources emit exactly the same candidate
bytes with this driver as with the prior scalar-only driver.

The typed scalar extension adds exact I/J source matching before lowering and
uses the existing checked narrowing and signed result boxing. Its source entry
calls the shared `prepared_surface_handle` constructor directly, keeps that
Int64 value through typed count/bit/release APIs, and returns only a test bit
observation after release. The historical producer still calls its original
legacy count adapter, so both contracts remain exercised separately. A new
independent runner requires two input-specific bit strings, two actual creates
and an empty last-handle slot after each source release. Positive/repeated source
bytes match; the input mutation emits distinct, independently decoded bytes.
Four actual I/J source argument/result mismatch cases refuse without DEX.
The enlarged host contract fixture finalizes typed release/getter adapters and
rejects all four wrong widths plus unsupported legacy fixed-width declarations.
Both inherited scalar/String and legacy candidate bytes remain exactly
unchanged. The existing ART gate also requires the typed source/release result
and compiled-source mutant; execution is pending its hosted native fixture.

The Int64 export slice now generates exact public `(J)J`, `(IJ)J`, `(JI)J`,
`(JIJ)J`, `(I)J` and `(Text)J` descriptors. Full source (pure/IO identities plus
real snapshot handles) and a separate pure-only source produce identical bytes
with automatic and explicit managed selection. Repeated full source bytes match;
the compiled IO identity mutation differs and independently decodes. Default
Int and Double export probes reject with no DEX. Independent observers assemble
and require signed minimum/maximum, −1/0/1, a value above 32 bits, exact wrong-I
method lookup refusal, mixed layouts, actual native handles and explicit release.
The public-boundary host fixture independently checks incoming pairs before
and after narrow arguments and finalizes the generated bridges. Existing legacy
and scalar/String native candidates retain their exact previous bytes. No new
Int64 primitive operation is implemented or a complete arithmetic contract
claimed; ART execution remains the hosted gate's next evidence boundary.

The C fixture owns a checked handle registry, validates version/offsets/lengths
and xyz powers, and copies with `GetDoubleArrayRegion`/`GetIntArrayRegion` before
publishing a snapshot. It frees failed allocations and implements explicit
release; no Java reference or pinned array pointer survives native return. Its
qualification calls are on one thread. This fixture does not claim a reusable
thread-safe handle registry or implement application polynomial semantics.

The existing runtime-repair workflow now requires the new source/native fixture
and independent positive/mutant observations on its API 29/API 34 matrix, using
its existing pinned frontend, qualified native ICK driver, NDK headers, bionic
link and ART setup. Local native C/link/ART qualification remains pending: the
recovered artifacts contain no qualified ICK native compiler or Android NDK.
No host C compiler or substituted JNI header is used. No physical-device or
application APK result is claimed.
