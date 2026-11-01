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
