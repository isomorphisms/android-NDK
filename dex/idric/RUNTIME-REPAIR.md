# Managed runtime repair

This repair continues the checked Idriç direct-DEX compiler. It reconciles
the pre-ICU main baseline with the existing managed-runtime work on a new
branch; the original branches and ICU application/transport remain unchanged.

## Implemented boundaries

- A checked nullary IO Unit command selects the managed command path from its
  checked entry contract, while framework/reference graphs retain their own
  checked path. No function name or dummy getArgs call selects the runtime.
- Source capability reasons are reported in `<output>.runtime.tsv`. Generated
  helper dependencies are validated and transitively retained from roots.
  Commands without argument access have ART main(String[]) but no retained
  argv field/accessors. Only reachable mapped native services retain a loader.
- Constructor and closure layouts have checked plans. Matched constructors
  validate payload shape before projection. Partial application copies captures;
  dispatch targets come from reachable checked partial applications. Oversized
  closure application is refused. Register areas grow with actual arity, up to
  the DEX invocation limits, instead of an arbitrary twelve-argument limit.
- Supported direct self/mutual tail cycles in the managed path share a generated
  dispatcher with simultaneous parameter replacement and per-invocation state.
  Dead temporary/local references and placement-created aliases are cleared.
  Indirect closure tail calls and scalar-export lowering do not gain this
  stack-safety guarantee. Non-tail calls keep ordinary semantics. No frame pool
  or shared mutable invocation state is introduced.
- Legacy three-column JNI maps retain prior null conversions and unqualified
  ownership. Optional explicit contract columns admit calling-thread synchronous
  borrowed local references, nonnull Strings and normal ART exception propagation.
  Unsupported retention/async/callback/object ownership is refused, not inferred.
  Native implementation obedience remains a declared obligation, not a proof
  established by a descriptor. See the JNI contract example for syntax/limits.
- Existing finalized plans remain shared by binary and readable emission.
  A failed backend invocation invalidates its previous candidate outputs.

## Representation and reuse

The generic ART-managed ArrayList value representation is retained deliberately.
The checked ANF slice erases payload field types, and the writer currently
declares static fields. Typed instance-field specialization requires a real
source-type/layout and encoder extension; it is not presented as completed.
This repair makes layout explicit and guards it rather than inventing type
information. The standalone layout fixture grew from 22,296 to 23,268 bytes
with shape guards; this is not a speed or heap benchmark.

Idris JVM revision 736bd4f7346269b8c1be15031d319a758bda3a57 supplied design
references for staged tail arguments, mutually recursive dispatch, closure
representation and reference release. This code adapts mechanisms rather than
imports its Java runtime. DexMaker revision31df94e311657f168f06fb8bf205d60b37d56342
and dexlib2 revision1a36aa30d18d92e63994f4b1e67a055931f5a707 inform the emission
boundary and independent decoding. No upstream implementation text was copied;
no new runtime dependency or collector is bundled.

## Evidence at implementation

The final combined backend builds with pinned checked frontend
740bbf2b1d9e811fd00c719c3473eede17ceea3b. Concurrent full Chez optimizations
exceeded the local memory limit; the normal build passed once serialized.
No frontend source or optimization default was changed.

All fourteen preserved host suites and independent shared-class/argv decoding
pass on the combined source. New capability/layout/JNI controls pass. Independent
execution of actual unplaced and placed tail plans passes, while three compiled
mutations of production source fail for the intended reasons.

The focused checked-source emission lane passes repeated-byte determinism,
independent baksmali decoding, pruning and unsupported-foreign refusal:

| Program | DEX bytes | Methods | Classes |
| --- | ---: | ---: | ---: |
| Plain output, no argv | 896 | 4 | 1 |
| Reused closures/records/lists | 24,376 | 73 | 1 |
| Runtime argument traversal | 22,572 | 68 | 1 |
| Tail calls, swaps, varying arity and reentry | 29,044 | 83 | 1 |

The checked Chez reference separately confirms a million self/mutual transitions,
argument swaps, thirteen arguments, varying-arity members and effect/reentry order.
Host execution/decoding does not establish ART execution. The API29/34 workflow
records actual managed/JNI outcomes separately. Physical A1/C67 acceptance remains
NOT_RUN unless independently performed. Existing unrelated ICU failures are not
credited as resolved by this repair.

## Remaining language work

General Text-to-Integer parsing, broader primitives, typed instance-field
specialization and asynchronous/retained native callback contracts remain
separate capabilities. Numeric mathematical policy stays in Idriç; no new
division/coercion semantics or integer-width changes are introduced here.

## Hosted failure diagnosis and qualification repair

The October 25 runs at `fe615c487c60300e2e47964fa4a74c13e36ddd19`
failed at three distinct boundaries:

- Canonical DEX and API29 restored compiled frontend state without the generated
  `IdrisPaths` source (`_/src` is a symlink to the source root). API installation
  therefore failed with `Module IdrisPaths not found`. The shared installation
  step now regenerates metadata with the pinned frontend Makefile on both fresh
  and cached builds, then installs and checks the compiler API.
- Framework effects used frontend `ff4d8528`, whose driver printed a rejected
  constructor diagnostic but exited zero. It now uses the same checked
  `740bbf2b` frontend as canonical/runtime qualification; that revision already
  fixes code-generator error exit status. The negative tests still require
  unsuccessful compilation, the exact diagnostic and no candidate DEX.
- API34 completed plain IO, values, Unicode arguments, million-transition tail
  groups and real JNI identity/repetition/narrowing before stopping at the
  null-result diagnostic check. `app_process` routes uncaught exceptions to
  AndroidRuntime logcat before killing the process. The observer now retains
  that log alongside stdout/stderr/status and requires the expected diagnostic;
  a timeout or unexplained failure is not acceptance. The earlier transient ADB
  offline event recovered during emulator startup and was not this failure.

The old compiled Grease artifact also became unavailable (404). Canonical and
runtime lanes now use the existing pinned Grease/Cat Food source bootstrap from
framework-effects qualification rather than an expiring artifact. Canonical
qualification no longer checks out or builds ICU, Idriç-Net or OpenSSL. The
preserved checked argument fixture is standalone and requires none of them.

The JNI fixture additionally exercises a real null argument rejected before
native entry, legacy Unicode/null execution, and CheckJNI. It compares both
candidate DEX files and the native library after pulling the executed bytes
back from the emulator. Its bounded GCC/NDK/bionic profile is unchanged.

Canonical emulator preparation also uses the explicit KVM access step already
used by the runtime lane. The framework harnesses pin the repaired frontend
exactly, including the unpack and callback consumers, and share its bootstrap
cache paths. No refusal assertion is relaxed.

The first canonical ART run confirmed that missing KVM access selected software
emulation. It still booted and passed checked calls, argv and runtime-argument
observers, then exposed a stale combined index/narrowing observer: its
argument-only candidate correctly prunes unused `__idricIntExact`. Index
refusals remain with that candidate. The unchanged int/long limits and overflow
assertions now execute through a separate observer against the checked JNI
candidate, where both narrowing helpers are reachable. Independent decoding
requires the unused int helper to stay absent from the argument fixture and
present in the JNI fixture. This preserves pruning and every boundary assertion
rather than keeping unreachable runtime code alive for the observer.

## Hosted ART checkpoint, October 27

At `74637745bd85ee7782f609b643b18a60e55d67c2`,
[runtime qualification run 40522558907](https://github.com/isomorphisms/android-NDK/actions/runs/40522558907)
executed the exact generated managed candidates successfully on both API29 and
API34 x86_64 ART. Plain IO, lists/records/reused partial applications, Unicode
argv, both million-transition tail runs, swaps, thirteen arguments, differing
member arities and nested effect order matched the separate observer's
expectations. Pulled-back candidates matched their generated inputs byte for
byte, and all four also matched the starting head's API34 ART-tested bytes.
The original production lowerer passed the independent register-machine
observer; compiled staging, retention and placement mutants each exited 1 for
the intended invariant. These are host mutant observations, not ART heap
profiling.

Both APIs also executed the qualified GCC/NDK/bionic library: Unicode identity,
10,000 scoped acquire/release calls and exact narrowing passed. Explicit null
result/input, pending native exception and overflow each failed with its exact
expected AndroidRuntime diagnostic. The complete workflow at this checkpoint
was **FAIL**, because the newly added legacy-null observer incorrectly expected
printable `null`. The baseline legacy DEX already dereferences the result with
`Object.toString()`. The corrected observer requires that existing downstream
NullPointerException, checks the call site, and refuses any explicit adapter
null diagnostic in the legacy case. It captures each rejection's logcat/status
before checking the result. Legacy Unicode identity already passed.

Managed output with no extra argument:

```text
self=1000000
mutual=7
swap=right
wide=1000078
varying=1000009
before
nested=75
after
```

With one extra argument, the first five lines are `self=1000001`, `mutual=9`,
`swap=left`, `wide=1000079`, `varying=1000001`; the final three are unchanged.

The checkpoint's generated identities are:

| Candidate | Bytes | SHA-256 |
| --- | ---: | --- |
| Plain IO | 896 | `fee9b05b6a227468fe41477fb2c6074c6d80376266600974163a5e1a19adf76f` |
| Values | 24,376 | `1c41f1203a309ddcf8bb0a2f2c0d234bf7be85d6a21645d8a51319671a7e8de0` |
| Arguments | 22,572 | `06b7efa8699acd7c3bc259f6e9c28ee45a5799bfb03ee058d9edea42650cdbdb` |
| Tail calls | 29,044 | `694afada096a71c7bd80edaf3005130a82a704a0c0979084e51d19eac2c2c770` |
| Explicit JNI | 26,208 | `c4b66640c766007dac397645adb48ae32dd293b4dd54f36db915b90062a7f531` |
| Legacy JNI | 25,956 | `76f5ff4bc3c5855394495d4953ea946ea3723c9efa761002c6d99b5ddc4b83d7` |
| Native library | 4,472 | `1977fe4e47e191270890de8ef58ffb49e545b21924486597b5826b473523a55c` |

Review qualification requires the complete canonical, runtime-repair and
framework-effects workflows on the **current published head**. The checkpoint
above is bounded historical evidence and does not turn that failed workflow
green. Each new run retains source revisions, expected/actual outputs,
independent decoding, compiled mutation outcomes, DEX identities, pulled-back
bytes and native toolchain receipts. Physical A1/C67 acceptance is NOT_RUN;
general Android ICK qualification, heap benchmarks and ICU/OpenSSL integration
are not inferred from these results.
