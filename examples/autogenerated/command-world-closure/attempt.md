# Checked command closure and source reflow arithmetic

The real IB SourceReflowSmoke command at 37edf4886a9517bd0d39ece70126ae4c6c7a5916
(run 41314057152, job 124870263137) is refused by the command-only arity guard:
"Managed IO entry must retain exactly its checked World argument".
A command's checked IO Unit source contract and its optimized ANF arity are
different boundaries. The qualified managed-export bridge already handles a
checked body which returns a closure and applies any remaining imported
arguments, including World. Command planning now reuses that bridge rather
than requiring one particular optimized function shape. Checked IO Unit,
zero ordinary arguments, exactly one command export and the independent
framework-Activity contract remain required. Unsupported checked arities
remain explicit refusals; no unchecked heap ABI becomes a public export.

Type sketch: the external command remains () → IO Unit. Optimization may
represent it as a nullary checked method returning a World closure. The
bridge supplies the same private erased World argument through closed
compiled closure dispatch. It does not run a source interpreter.

The current qualification copies and compiles the actual maintained IB
SourceReflowSmoke command, checks deterministic DEX and independent decode,
and requires its literal True output and zero exit on ART. A separately
compiled false command must print its literal False result and exit one.
A crash or absent output cannot count as a successful rejection.

Independent performance failure retained: android-NDK 035452331c0f2b98391a551e0797418da5793eae
run 41313837280, API29 job 124869623760 / API34 job 124869624015, compiles the
maintained advance-based reader and its admission mutant. API34 observes
231 bytes in 55,186,282 ns, 8407 bytes in 4,406,992,614 ns, and 31507 bytes in
55,196,061,023 ns with exact source output. The unchanged 84007-byte target
still exceeds the complete 180-second deadline. Samples now principally
map to IB.Reflow.Arithmetic.nonnegative_difference's unary subtraction.
Those observations are failures at the large-consumer boundary.

The next IB source uses the maintained Number minus operation. Its pinned
frontend source Compiler/Opts/Constructor.idr explicitly lowers
Prelude.Types.minus to saturating integer subtraction; this is source
evidence, not a runtime pass. Small reference comparisons and large-number
boundary cases accompany that consumer change. No body limit, deadline,
literal expected source, admission guard or mutation requirement is reduced.
No physical result is claimed. All changed-head runtime results are NOT_RUN
at authoring.
