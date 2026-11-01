# Keep real checked recursive consumers off the finite ART call stack

Independent ai-ci source 6ff5c5b8cb18cf3d05263e91dadd1c5d4022ad3d,
run 41303755228, reproduces an actual StackOverflowError on API 29 and
API 34 with the unchanged IB ReaderProjection DEX from source
a7349efc8041b4c41ff158afca7f13079c8df1c2. A 231-byte legacy-source
control and incomplete-source refusal pass. The 84007-byte controlled
HTML source fails in repeated Idric.Generated.__idricManaged45 calls,
with checked closure/numeric helpers above it. This is a positive failure,
not valid mutation rejection. The current real Google Activity path
also fails rendering roughly 92 KB responses, but its original JNI adapter
discarded the exception class. Its exact cause is not promoted to proven
until the rebuilt Activity reproduces or resolves that path.

Purpose/type sketch:
checked ANF direct-recursion component -> statically emitted DEX member and
resume labels + private invocation-local continuation frames -> ordinary
checked result, retaining the existing public entry ABI.
No source AST or ANF is encoded/interpreted at runtime. No alternate reader,
Java/Kotlin application implementation, candidate Smali or bytecode
patching is used.

The retained tail-transfer lowering only joins direct calls in tail position.
A non-tail recursive list/traversal helper therefore consumes one ART frame
per element. The repair discovers strongly connected components through all
direct named calls. Components containing non-tail recursive calls use a
private ArrayList stack holding a return selector and the caller's managed
references. On return, the generated control flow clears dead callee aliases,
restores the exact caller frame, assigns the result, and jumps to its compiled
continuation. Pure tail components retain the allocation-free transfer and
existing root-release contract. Named ABI wrappers still isolate ordinary,
closure and nested invocations. Checked constructors/foreign restrictions,
managed-command/pure-export/framework-Activity contracts remain in force.

The implementation is in the maintained DEX Heap module. It is a compiler
control-flow lowering, not a duplicate interpreter or IB semantic rewrite.
Indirect recursion mediated only through an unknown closure is not claimed
to be made stack-independent by the direct-call component analysis.
Heap capacity and existing method/arity/DEX bounds remain real limits.

Qualification retains the canonical host/refusal/native/JNI/closure/collection/
tail-retention/entry-contract suites. Additional real ART expectations are
12000-deep non-tail arithmetic (12007), 12000 returned list constructors
(sum 72006000), sibling recursion with live results (6765), and mutual
varying-arity suspended calls (48018). Four independently compiled source
mutants must execute normally and produce their designated wrong value;
an exception/crash is not an accepted mutant result.

The real unchanged maintained ReaderProjection is copied from the exact IB
commit, compiled twice for determinism, independently decoded, then invoked
on ART by ai-ci's existing large-source observer. The original-byte digest
and exact decoded selection output are independently constructed. Its
incomplete-source mutation and compiled admission mutant remain required.

This source attempt has not yet compiled or passed ART at authoring.
The workspace execution environment is unavailable; exact-head GitHub
Actions perform the actual compilation and runtime checks. No host pass
or physical observation is manufactured. All emitted DEX, plans, logs,
statuses and source pins are retained under the existing runtime evidence.
Physical SVITOO TAB_P10 acceptance remains BLOCKED / NOT_RUN; A1/C67 are
historical damaged targets. No merge, signing change or permanent release.

First compiled attempt 296da94ae7af35b7e62ad670864de148f06989df failed
backend elaboration before fixtures or ART: the conditional offset in
first_fresh_label defaulted to Integer while labels require Int. The
canonical and framework-effect jobs independently print that exact type
diagnostic at Heap:762. The correction gives this label allocation binding
an explicit Int type. This is not a successful runtime qualification.
The generic backend-build coordinator now prints its preserved diagnostics
before propagating a nonzero compile status. The one-off archive-reading
job is removed once the original diagnostic is available in the canonical
job logs. Existing actual compile/refusal requirements remain unchanged.

At e58d03e2ac42a6ceef35ea22fbeef2e113a21fc4 the repaired backend builds,
and existing checked host/runtime-fixture/refusal/decode, native-field,
Text-order and export-alias preparation completes on both API lanes.
The unchanged real IB ReaderProjection then exposes a second reusable
writer deficiency: DEX format 22t branch displacement 38060 at code unit 437.
No ART pass is claimed for this head; the consumer cannot emit its DEX.

The writer's existing monotone goto relaxation now also expands a far
conditional into its exact inverse over a goto/32. Fresh skip labels are
drawn from the placed method's actual label set, and the layout is recomputed
to a fixed point. Original zero-offset/undefined-label/register-range
refusals remain. Binary and readable artifacts still consume the same
opaque finalized plan. Literal host byte expectations cover +32767,
+32768, a far negative displacement and a conditional pushed out of range
by another goto promotion. The real IB source and admission mutant still
must compile/decode and execute on ART; no old pass is inherited.

At 3908e7d778186779fab21436783b44eab974e605 the unchanged real IB
ReaderProjection and its admission mutant emit and independently decode;
the repeated positive DEX is byte-identical. Canonical host encoder tests
pass the new conditional-range cases and progress to ART. The runtime
job then catches a parse error in this newly authored small test fixture:
total is a language keyword, so it cannot name the sum accumulator. The
fixture now uses accumulated. This is a test-source correction, not a
compiler/IB semantic change or a passing ART result. Both the real large
consumer and all four recursive mutation controls remain mandatory; the
real consumer is observed before the small recursion fixture on ART.


Current source qualification consumes IB 966a613a79b2a5800c209298800678bd984d4966, which preserves the same
real reader consumer path while replacing unary source-offset differences
with the maintained saturating Number minus operation and adding bounded
reference/large-integer regression cases. The compiler source change is
recorded in examples/autogenerated/command-world-closure/attempt.md.
The actual maintained SourceReflowSmoke command is compiled twice and
independently decoded, alongside a false command mutant with literal output
and exit-one expectations. The separate command/effect and large-consumer
ART coordinators both run even if one fails; the suite requires both zero.
This prevents one subsystem failure from hiding the other. The original
84007-byte target and full 180-second deadline remain unchanged.

Historical failures remain: 150ae18's unchanged old A734 consumer times out
at 8407 bytes; 0354523's advance-based a013 consumer completes 31507 bytes
on API34 but the 84007-byte target still times out, predominantly in unary
nonnegative_difference. No historical source/head is retroactively green.
The exact new head's results remain NOT_RUN at authoring.
