# Checked private Activity field investigation

The application must own its state and retain one `IORef AppState` on each
normal Activity instance. The first source sketch pairs a getter and setter
whose receiver type is the validated Activity external domain and whose value
types are the same closed `IORef AppState`. `AppState` is an ordinary source
ADT with Text/list data; it is not a compiler-owned UI model.

The intended source contract is:

```text
get_state : ActivityReference → PrimIO (IORef AppState)
set_state : ActivityReference → IORef AppState → PrimIO ()
```

A private managed field must retain exactly that cell reference per receiver.
Before initialization, a getter must raise a designated exception rather than
return null as a valid source cell. Two Activities must never share the field
implicitly. Incorrect getter/setter source types, owners and static accesses
must fail before candidate emission. The public `IORef a` export ABI remains
unsupported. No platform collection/property store or native semantic state is
selected by this sketch.

First inspect actual frontend CF metadata and full checked source types before
choosing a mechanism. A `%foreign` probe records whether the applied source
type survives foreign compilation. A separate `%extern` probe records its
checked ANF shape without pretending an unknown primitive already works.
Neither probe is a field implementation or cross-callback acceptance result.

Existing source facts at parent1432dad: `FieldPlan` can declare private reference
instance fields, but IR/lowering currently exposes only static field accesses.
Checked export classification rejects applied `IORef` types. Codegen can read
and normalize full source types from the compiler context before lowering; this
must be demonstrated for a field pair if CF metadata alone erases distinctions.

## Source evidence and selected binding

The actual source probes and their exit-1 diagnostics are retained in
`initial-refusal.md` and `initial-extern.checked.anf`. Ordinary `%foreign`
Object method declarations refuse the applied IORef type. `%extern` preserves
the actual typed source operation through checked ANF. The implementation uses
the full checked source types available in the compiler context before lowering.
No public or foreign descriptor is added for an ordinary managed value.

```text
%cg dex managed-field LIdric/Generated; state ActivityFieldSource.get_state ActivityFieldSource.set_state
```

`ManagedActivityField.idr` parses this bounded binding and checks the normalized
getter/setter shapes. Codegen requires actual `%extern` definitions with exact
arity two and three, respectively, including World. Both receivers must be the
same source domain already validated as `android.app.Activity`. Each payload is
shrunk out of its receiver/World scopes; a dependency refuses. The compiler's
conversion check then requires the two closed payload types to agree. This
admits closed application-owned payload types, including type applications,
without choosing one canonical application state type.

Only those exact source externs bind to the generated internal accessors. The
accessors use shared typed `InstanceGetObject`/`InstancePutObject` instructions
from the captured-Runnable owner's writer commit b95d60e (local dependency
475d10d). Storage is one private instance reference field on Generated, with
an explicit Generated receiver cast. Getter null raises `NullPointerException`
with the exact message `Idriç Activity field 'state' is uninitialized`; setter
null also refuses at runtime. These helpers retain the actual IORef reference;
source ADT/list/Text operations remain in the application program.

The field directive requires managed exports and the explicit existing Activity
parent. Fields and endpoint pairs must be unique, and endpoint source names must
be fully qualified. Public exports still reject `IORef a`. This does not add
general public managed-object arguments, native state or a singleton.

## Local checks

- The exact pinned frontend740bbf2b1 compiled the 23-module package and its
  default Chez driver successfully, with heavy builds serialized. A final
  source-name parser cleanup was included in the final driver rebuild.
- The actual host source-type/layout fixture executes and prints
  `PASS checked Activity field plans and source-type refusals`. It observes
  closed payload extraction, rejects receiver-dependent payloads/nonlinear
  World/malformed declarations, finalizes/encodes field helpers and rejects
  static access to a declared instance field through the shared writer.
- Actual `ActivityFieldSource.idric` emits **10,836-byte DEX**, with identical
  repeated bytes. Independent baksmali decoding observes private state storage,
  instance get/put, both null diagnostics and the shared `requireNonNull` calls,
  checked source exports, actual long-click bridge and lifecycle overrides.
- Its emitted `candidate.field-types.tsv` records the actual source receiver
  `ActivityFieldSource.ActivityReference`, closed payload
  `ActivityFieldSource.AppState` and the exact getter/setter names. This is
  observed source metadata, rather than an assumption from erased CF types.
- Nine actual source refusals each exit1 with the intended diagnostic and no
  DEX: wrong field owner, wrong receiver domain, ordinary-function getter,
  missing setter, shared accessor pair, receiver-dependent payload, different
  getter/setter payloads, the original ordinary foreign probe and the preserved
  public IORef export. The first five also remove deliberately stale candidate
  DEX and field-type receipts before refusing.
- The shared-accessor control uses two distinct field names with one endpoint
  pair. Identical repeated directives are deduplicated by the frontend and
  therefore are not a backend duplicate-input observation.
- Four real source mutations change the click result, resume handler,
  destruction state or retained list history. Each compiles into changed DEX
  bytes. Runtime rejection remains pending; no host Activity execution is
  substituted for ART.
- The independent Smali observer assembles. Both strict Grease helpers parse
  using the retained pinned runtime. The complete helper requires the frontend
  git checkout used by hosted CI; local checks here invoked the retained exact
  compiler archive directly and do not claim a full helper replay.

The final `.checked.anf` retains the original checked source externs. The
finalized `.dex.plan` and independent decoded DEX show their bound internal
helper calls. The field-type receipt records the full source-type check.

| Artifact | SHA-256 |
| --- | --- |
| positive/repeated DEX | `01426ab3a9f07e74d70df99f2197f508cfa17c46d2ccff6fbab69fd6dc1c7822` |
| click source mutant | `11f88420cbf7f9531b99ff778a686aafa1799d6b82a556b9367711ab64f85cca` |
| resume source mutant | `bffe770d6de3e0d0ed00c7a42c9153ad3fcefe7a192fc167461cb9bf0c2fc9d9` |
| destroy source mutant | `f8eb2d0b2213b85cdbb75b2d78b500fde23072a96a961e5d74fe9a4841ae8eb3` |
| history source mutant | `350c10f1a478ef535ce8183bc4e6541723b8e370a81d808e384e71c19ccb2d8a` |
| independent observer DEX | `d661fef30ac0373af5de655bc9b5474b43823b247110cf39d47fe27a3e0c15de` |
| final local driver executable | `44ddfc2213eeabb9672157ded946d5e17512f405c4d6e705a8fa0c7b6170ccc4` |

Final local observations are under `ui-activity-field-final`. No remote refs
were written by this task.

## Runtime and lifecycle boundary

**ART is PENDING. Framework lifecycle, APK and physical-device execution are
NOT_RUN.** The API29/API34 workflow is wired to execute the independent observer.

The app_process observer constructs two distinct real Generated Activity objects
and a platform View. It requires the exact uninitialized getter exception,
independent initialized state, actual long-click dispatch and state retention
across calls to the checked resume/destroy source exports. It checks that closing
one receiver leaves the second usable, and that a foreign Activity receiver
fails the explicit cast. Four source mutants must produce the designated
assertion and exit93. Unexpected Throwables print their stack and exit94;
abnormal process death never counts as mutation rejection. Each process retains
stage checkpoints, separate stdout/stderr and before/after all-buffer logcat.

It does not invoke platform lifecycle super methods on unattached Activities.
The source's real onCreate/onResume/onDestroy wrappers remain emitted, with
their original parent calls. Actual framework lifecycle delivery needs the
existing installed lifecycle-observer path and is not qualified here. The
current unrelated callback observer's `Killed` exit137 has no established cause;
this fixture does not treat a View choice or context setup as its correction.

Captured Runnable lifetime, worker delivery/cancellation and a final consumer
Activity remain separate work. The application continues to own state meaning,
initialization, closure policy and asynchronous delivery checks.
