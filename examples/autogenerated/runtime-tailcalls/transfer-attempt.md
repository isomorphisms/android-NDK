# Independent tail-transfer execution model

## Type/effect sketch before implementation

Values are opaque reference identities, integer branch/select values, null and
uninitialised registers. A bounded register machine executes the actual plans
returned by `heap_tail_methods`, rather than repeating the transfer algorithm.

- `run_until_transfers : fuel → transition count → instructions → execution index → register values → Either diagnostic register values`.
- Checked ANF fixtures express a direct two-parameter swap and a varying-arity
  mutual cycle with a dead local alias.
- Parameter locations are derived from method frame/parameter counts. Labels
  and jumps are resolved from the emitted instruction list.
- Laws: simultaneous replacement swaps distinct values correctly; live result
  parameters survive; unused parameters and old temporary/local reference
  identities cease to be roots after redispatch.
- IO only reports pass/failure. This is host-plan execution, not ART evidence.

Production mutation controls will compile copied backend source with parameter
assignment bypassing staging and with reference release removed. Each compiled
mutant must fail the independent model after an otherwise successful compile.
No production source is modified by the mutation runner.

## Implemented boundary

`tests/dex/TailTransferTest.idr` executes the actual output of
`heap_tail_methods` with an independent bounded register interpreter. It
handles integer selection/branches, labels/jumps, nulls and object moves. A
checked helper selecting its second argument supplies a precisely specified
call boundary and forces invocation placement through noncontiguous arguments.

The test exercises both unplaced and `prepare_method_invocations` output.
Incoming slots follow the method frame/parameter counts; relocated logical
slots follow the actual typed prologue. The interpreter assumes no fixed
register numbers or label identifiers. Live parameters must contain the
independently expected reference identities. All other slots must cease to
hold the discarded identities after transfer.

## Verification

Pinned frontend: `740bbf2b1d9e811fd00c719c3473eede17ceea3b`.
Production Heap SHA-256:
`a572aafdbd132793ba3a5832be85e5c1c602f1ca84976057375800b73598e3db`.
Production Placement SHA-256:
`c2a65c74976784e9c34c85059c1f1a6d41ff64f4d790efbc2ecfadb9558b97c1`.

The initial test attempt exposed an indentation/parser error around an `if`
containing a case expression and a missing explicit `Core.TT.Term` import for
the compiler's `LazyReason`. Correcting those test-source errors allowed the
independent model to compile; no frontend fallback or compiler repair was used.

Run the existing Grease entrypoint with
`dex/idric/tests/dex/verify-tail-transfer.grease` and three absolute arguments:
repository, pinned Idriç repository and a fresh evidence directory. The runner
copies production source and compiles each case in an isolated build directory,
without the production backend TTC path. The completed local run used
`/workspace/scratch/a6451c61927a/tail-transfer-independent-final`.

Observed results:

| Actual compiled source | Exit | Independent observation |
| --- | ---: | --- |
| Original production lowerer | 0 | Swaps, varying arities, temporary/local liveness and placed aliases pass |
| Tail parameter assignment bypasses staging | 1 | Swap becomes reference 22 / reference 22 |
| Tail temporary-reference releases removed | 1 | Dead staging/member-local reference survives |
| Placement incoming-reference releases removed | 1 | Incoming/outgoing alias invariant fails |

Every mutant compiled successfully and failed during register-machine
execution for its expected reason. Source digests, compile logs, executable
digests and typed exit records are retained by the runner. A compiler error
does not count as mutation rejection.

This establishes production-plan behavior on the host. It does not establish
ART verifier behavior, actual GC collection timing or physical-device behavior.
The remaining acceptance boundary is execution of the same real checked
programs on ART, with the separate production mutations preserved.
