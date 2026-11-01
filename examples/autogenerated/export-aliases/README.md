# Saturating checked aliases at managed export boundaries

The maintained IB native Activity exports its checked link-navigation function
as an IO alias. At b0f135d the checked ANF arity of this source alias differs
from its public scalar/opaque ABI. Emission refuses with `Managed export checked
arity differs from its source ABI: NativeReader.reader_follow_link`. The source
is not rewritten to hide this reusable compiler deficiency.

An alias or partial definition returns a checked closure after consuming its
ANF parameters. The managed export boundary now calls that definition with its
checked prefix, then applies each remaining imported argument through the
existing closed managed closure dispatcher. IO includes its checked World
argument. The public ABI remains scalar/opaque, ordinary data stays private,
and over-arity/oversized/unsupported foreign signatures still refuse. Managed
command and framework Activity entry contracts remain separate.

`ExportAliases` exercises a pure alias, a partially applied pure function, and
an IO alias that changes a real SDK AtomicInteger through the checked foreign
boundary. Independent acceptance must inspect the returned text and SDK counter
against literal expectations and reject a compiled changed-increment mutant.
Fresh host compilation, independent DEX decoding and deterministic emission
passed for the fixture and compiled effect mutant. An ordinary-data alias still
refused with exit 1 and no DEX. The actual expanded IB Activity emitted and
independently decoded through this repair without changing its exported aliases.
The checked native TextView declarations separately emitted and independently
decoded through the maintained writer, including both typed SDK constructors.
New API 29/34 execution is required; host emission provides no runtime acceptance.

The first runtime attempt, run 41273908319 at 09289bf, failed its positive
independent observer on both APIs with exit 137 and no assertion/success marker.
It remains failed. Static decode found an observer branch that replaced the SDK
counter register with a String before joining its second typed counter call.
ai-ci f3764fe8afbdc02956382cc618caab297a3b9f47 preserves that register type and
captures AndroidRuntime errors on unexpected exits or missing markers. Compiler
semantics and literal expectations are unchanged by that observer correction.

Five additional source attempts are retained under `initial/`, including their
digest-verified original bytes. They still lower with a direct World parameter,
so they are not proof of the real Activity's undersaturated World path. The
active counter fixture covers ordinary alias/partial/export effect regressions;
the actual maintained reader remains the concrete consumer requiring the new
suffix application. Its runtime link-event qualification is still required.
