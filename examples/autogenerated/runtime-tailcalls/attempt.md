# Checked managed tail calls

## Type/effect sketch before implementation

The runtime stores language values as ART-managed references. A direct tail call
changes the function being evaluated and replaces its parameters simultaneously.
An ordinary call retains its ordinary result and effect order.

- `self_count : Integer → Integer → Integer` counts one million transitions.
- `even_steps, odd_steps : Integer → Integer → Integer → Integer` exercise a
  mutually tail-recursive group and swapped argument positions.
- `swap_steps : Integer → Text → Text → Text` alternates captured text arguments.
- `main : IO ()` reports independently predictable results and ordered effects.
- `tail_groups : checked definitions → groups of mutually reachable tail calls`.
- `heap_tail_methods : checked ABI → checked definitions → Either diagnostic (covered names, method plans)`.

Invariant: stage every new argument before replacing any shared parameter slot.
Each invocation owns its dispatch state; no pooled frame is introduced. Only
statically resolved direct calls in a tail-call cycle receive the bounded-stack
guarantee. Indirect closure calls and non-tail recursive calls retain existing
behavior. The generated method preserves the original checked ABI through a
small wrapper and dispatches all members of a cycle in one DEX method.

Target: direct Idriç → DEX, pinned checked frontend 740bbf2b1, backend source
973c24bc0b4eab6f3c88699102f7cb0e7fd8951f. Host execution and independent decoding
are separate evidence from ART execution, which is supplied by the parent job.

Results and exact reproduction commands will be appended after verification.

## Implemented design

Retention follow-up type sketch: `TailRetentionChecks` symbolically executes a
generated higher-arity-to-lower-arity transfer. Every temporary reference begins
with a distinct discarded-value marker; the first incoming argument carries the
sole surviving marker. After redispatch only the new common parameter may retain
that marker, and no discarded marker may survive in staging, member locals or
reference scratch aliases. Removing the emitted null assignments is a negative
control and must fail that invariant. This is a plan-level rooting invariant,
not an ART heap/GC measurement.

Tail-position analysis follows checked bindings and constructor/constant case
branches. It recognizes a binding that immediately returns the bound variable.
Mutually reachable direct tail-call cycles share a dispatch method; original
method names remain wrappers with their original checked signatures. Non-tail
calls still use those wrappers and therefore receive separate invocation state.

All new arguments are staged before shared parameters are replaced. Parameters
unused by a smaller-arity member are cleared. No pooled frame or native heap is
introduced. Method arity is checked against DEX's invocation word count (255);
a group permits 254 object arguments plus one integer selector. Closure scratch
register count is calculated from the actual largest checked arity.

The transfer also clears all member-local/staging references and the known
reference scratch aliases after saving the new parameters. Invocation placement
releases its own extra aliases independently: copied real incoming references
are cleared after the prologue copies, and staged outgoing references after the
call and result move. Integer/wide words and original source registers are not
cleared by that placement cleanup. This preserves invoke/move-result adjacency
while preventing legalizer-created copies from retaining an obsolete value
through a long dispatch loop.

`TailRetentionChecks.idric` passed as a checked host invariant, including a
negative control removing emitted releases. It models source-plan reference
roots, not ART collection. The existing `DexInvocationChecks.idric` host suite
also passed after placement cleanup, including high-register, wide-pair,
object-result and aliased-result cases. Final ART and independent post-placement
retention observations remain the parent lane's responsibility.

## Verification

- All backend modules typechecked with the exact frontend above. Chez native
  executable optimization was killed with status 137 under concurrent memory
  pressure; this is not recorded as a successful native backend build.
- The generated Chez backend source was executed directly through the pinned
  Scheme runtime with the same frontend support library and package paths.
- It emitted `tail-calls.dex`, 26,572 bytes, SHA-256
  `493d90e1f617f7c22c3c38f6ef7bfebca78c7c809af2c812801d176208b81eb4`.
  This candidate precedes the final malformed-overapplication guard; combined
  acceptance must regenerate the final source rather than reuse these bytes.
- Independent baksmali 3.0.10 disassembly succeeded. It contains tail dispatch
  loops for self_count, swap_steps, reentrant_count, the odd/even group, and a
  checked Prelude list-tail loop. The swapped text values are saved in distinct
  staging registers before either incoming parameter is changed.
- Checked host reference execution passed with no arguments and with one extra
  argument. This is reference evidence, not DEX execution.

No-user-argument stdout:

```text
self=1000000
mutual=7
swap=right
wide=1000078
before
nested=75
after
```

One-extra-argument stdout:

```text
self=1000001
mutual=9
swap=left
wide=1000079
before
nested=75
after
```

The example's 13-argument function is marked noinline, and all iteration counts
depend on actual getArgs input. `reentrant_count` invokes its own group in a
non-tail argument expression before its outer tail transfer.

The backend build command is the pinned frontend's `--build backend.ipkg` in
`dex/idric`, with IDRIS2_PREFIX and IDRIS2_PACKAGE_PATH selecting the pinned
bootstrap packages, IDRIS2_DATA selecting `_/support`, IDRIS2_LIBS selecting
`_/support/c`, and CHEZ selecting
`/workspace/scratch/58fb4da72caa/Idric/_/.tools/bin/scheme`.
Reference compilation uses `--cg chez`
from this example directory with separate absolute build/output directories.
DEX compilation executes generated `idric-dex.ss` with `--cg dex`, this source
directory, and separate absolute build/output directories. LD_LIBRARY_PATH names
the pinned frontend's support-library directory.

Final integration adds a runtime-derived mutual group whose members have
different arities. Its checked host reference yields `varying=1000009` without
extra arguments and `varying=1000001` with one extra argument. The third payload
is consumed at the wider member's base case, so it remains meaningful source
data rather than an unused parameter.

The parent independent register-machine test compiled three mutations of the
actual production lowerer/legalizer: bypassing argument staging, removing tail
reference releases, and removing incoming-copy releases. All compiled and all
failed the intended invariant. ART execution remains a separate pending gate.
Indirect closure tail calls and the separate scalar-export lowering remain
outside the managed tail-group guarantee.
