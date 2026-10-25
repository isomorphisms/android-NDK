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
