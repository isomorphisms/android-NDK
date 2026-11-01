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
