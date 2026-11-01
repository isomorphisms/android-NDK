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


Independent replay of compiler 150ae18dcac6e97e6bb5150e868929245f133594:
ai-ci f07e4f0901ebca358d497cce75ce495a98977924 run 41311555347,
API 29 job 124862837322 and API 34 job 124862836989, passes the
12000-deep non-tail/list/mutual controls, sibling live values and all four
compiled mutants. The unchanged A734 real IB consumer passes 231 bytes but
exceeds the unchanged 180-second deadline at 8407 bytes. Bounded samples
identify repeated SourceBreaks indexing and source reflow scanning/filtering;
this is a remaining consumer performance failure, not a recursion pass for
large documents. The original failure and the frozen source-bound replay
remain retained.

The current consumer qualification now consumes IB
a0130375d15a46d72f8e4262385315a12a005b03, which explicitly repairs those
source traversals using a linear boundary validator and a declared additive
advance provider. That source change preserves the general exhaustive
measurement API and source-backed selection/admission boundaries; it is
recorded in IB examples/autogenerated/source-reflow-advances/attempt.md.
No compiler implementation changes accompany this fixture-pin update.
The independent ai-ci observer at f07e4f0 retains exact expected original
text, all 231/8407/31507/84007-byte sizes, the 180-second deadline, and the
compiled admission corruption control. The source pins, source/DEX hashes,
four recursion mutants and all preexisting runtime/JNI/closure tests remain
required. New head results are NOT_RUN at authoring; no old failure is
renamed PASS.
