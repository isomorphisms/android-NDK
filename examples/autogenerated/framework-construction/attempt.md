# Checked framework construction

Continue the existing callback backend for IB's native Material reader.
This is compiler/platform work, not a browser model or handwritten UI bytecode.

## Type sketch before implementation

A declaration `dex:construct:OWNER:<init>:(ARGUMENTS)V` has source shape
`arguments → PrimIO OpaqueOwner`. Its JVM constructor result is void; its
source result is the initialized opaque object. The receiver is allocated by
the backend, not supplied among source arguments. Construction must be an
effect. Source argument descriptors, external source-domain identity, owner,
constructor name and void JVM result must agree before emission.

Lowering emits new-instance followed by invoke-direct on that same reference,
then returns the initialized object. No move-result-object may follow the
void constructor. Register placement must preserve allocation identity even
when the source destination lies above v255 or an invocation requires /range.
Type indices come from the actual file type pool, not the string pool.

## Required evidence

Check the actual Idriç constructor source and generate fresh DEX. Independently
decode its allocation, initialization, result and descriptors. Refuse ordinary
calls naming constructors, non-void constructor descriptors, pure allocation,
wrong source argument/result domains and invalid names. Exercise high-register
placement and source/production mutants. Runtime observation must establish
that Android constructs the view and that the existing IB reader adapter runs
on that actual object. Screen lifecycle/resources, APK and physical results
remain separate until exercised.

Fallback: none. The existing IR/encoder/backend owns candidate bytes.
