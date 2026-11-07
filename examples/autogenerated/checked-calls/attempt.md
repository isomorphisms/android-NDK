# Checked runtime calls through the canonical DEX compiler

Inputs and outputs are concrete Int32 and Text values. A checked helper maps
Int32 to Int32; recursive sums and mutually recursive parity functions map
Int32 to Int32; a cross-module Text function maps Text to Text. Effects are
limited to the host compiler and the external observation runner. The compiler
must retain actual invoke-static instructions to generated Idriç methods.

The call graph comes from Compiler.ANF, including both sides of a case. It must
terminate during discovery for recursive source. Runtime arguments/results use
their checked scalar descriptors. Unsupported polymorphic/heap signatures keep
the existing specialization/refusal behavior. ART stack depth is finite; this
milestone introduces ordinary calls, not a claim of stack-safe tail recursion.

Production bytes come from Backend.DEX.Encode. A separate smali observation
runner calls those bytes; it supplies none of the application methods. Tests
must cover nonconstant arguments, cross-module calls, direct and mutual
recursion, reordered arguments and Text results. Refusals and deterministic
regeneration remain mandatory. Host generation and ART execution are separate.

Initial boundary: the prior canonical branch specialized acyclic helpers and
refused recursive helpers. General heap data and real ICU IO remain subsequent
requirements. Executed results are recorded in the reconciliation receipt.

SharedClassTest additionally treats class descriptors, parameter/result
descriptors, method access modes and instruction lists as typed plans. Native
declarations have no code/register frame; constructors and initializers have
their required names and void results. Public callback classes retain their
nonfinal flag. It checks deterministic class ordering and seven malformed
plans and three malformed reference signatures, then emits a three-class file
for independent metadata inspection.

The legacy fixed Wegert serializer exceeded the host memory limit while being
checked. Its existing API now translates the same constructor, loader, native
probe and protected callback into the common plan. Preserved independently
assembled Wegert/Reddit/shell oracles decode identically to their candidates.
WebView and native View callbacks retain their positive and refusal fixtures.
Their native C behavior remains application-owned; host comparison does not
claim current Android native execution.
