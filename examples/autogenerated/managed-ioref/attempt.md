# Private managed IORef cells

## Source and question

Inspect the next normal-Activity state prerequisite after the checked callback
result/receiver slice. Do not select a platform Map, Intent property or View tag
as the application's state representation.

At pinned frontend740bbf2b1, the actual
[`Data.IORef`](https://github.com/isomorphisms/Idric/blob/740bbf2b1d9e811fd00c719c3473eede17ceea3b/_/libs/base/Data/IORef.idr)
declares an external polymorphic `Mut a` and the three `%extern` operations
`prim__newIORef`, `prim__readIORef` and `prim__writeIORef`, each with an explicit
World token and `IORes` result. `IORef a` is a source constructor wrapping that
cell. Its read/write/modify contract does not supply an atomic update or memory
barrier; mutex-based `atomically` is a separate facility.

## Type sketch

- The test-only `ProbeState` is an ordinary application-owned algebraic value
  with Text/list payloads; it is not a new compiler-owned canonical UI model.
- `ioref_roundtrip : Text -> IO Text` creates two independent `IORef ProbeState`
  cells, aliases one, writes through the original reference and reads through
  the alias. The second cell must remain independent. Only Text enters/leaves
  the public DEX export; managed state/cells do not acquire an external ABI.
- The narrow implementation recognizes the exact checked external
  primitives and preserve the managed payload by reference in one private cell.
  It retains aliases, mutation order and the source's sequential contract.
  No global platform store or application state serialization follows from that.
- A local cell implementation would still not retain a cell between independent
  framework callbacks. The current callback source export ABI rejects applied
  `IORef a`, and checked callbacks have no typed private fields or captured
  callback object. Those are separate receiver-lifetime/capture requirements.

## Preserved failed attempt and implementation

`initial-refusal.md` and `initial-probe.checked.anf` retain the initial actual
exit-1 compiler refusal and source form before implementation. The exact
checked operations have `[erased type, value, World]`,
`[erased type, cell, World]` and `[erased type, cell, value, World]` arguments.
The pinned compiler optimizes the `IORef`/`IORes` wrappers away in this path.

`ManagedIORef.idr` matches the three complete qualified `Name` values and
validates argument count and erased type position. Heap lowering allocates a
fresh private ArrayList cell with identity at slot zero and its one managed
reference at slot one. Read gets that slot. Write replaces it with `set`,
discards the previous value and returns the erased Unit result. Source IO
bindings retain their existing order. The implementation reuses the existing
managed layout, reference, invocation, placement and binary encoder owners.

There is no public mutable-cell descriptor, global store, application model,
serialization or new native method. Unknown/lookalike and delayed external
primitives remain refusals, as do malformed argument shapes. Ordinary cell
operations do not gain atomic updates, barriers or the separate mutex API.

## Local evidence

The changed source modules typecheck against pinned frontend740bbf2b1 and its
compiler API. Concurrent full Chez optimization was killed with exit137;
the same generated default optimization compiled the driver successfully once
serialized. No frontend or optimization default changed.

- The actual checked host source prints `PASS managed IORef host semantics`.
  Its application-owned ADT contains Text and a List of Text. The final probe
  observes the initial payload, an intermediate overwrite, final replacement,
  alias reads and an independent second cell.
- The actual host checked-ANF/layout test executes successfully. It finalizes
  and encodes each cell operation and refuses malformed count/type shapes,
  namespace lookalikes and unknown operations. This is a compiler boundary
  test, separate from the application source witness.
- The actual source emits **11,588-byte DEX**; repeat bytes are identical.
  Independent baksmali decoding observes the private tag/payload creation,
  get-one/set-one invocations, preserved reference results and erased Unit.
  Its runtime receipt names `managed-ioref` from the actual source graph.
- Four actual compiled source mutations change the payload, alias target or
  write target, or omit the observed intermediate write. Each changes candidate DEX bytes; each host reference executable
  exits1 with the designated semantic failure. ART mutation rejection is pending.
- Public `IORef Text`, an unknown extern and a same-spelling extern in another
  namespace each actually exit1 with the intended diagnostic and no DEX.
- The independent scalar Smali observer assembles. It calls the source export
  three times with Unicode, empty and distinct Text. It implements no cells,
  algebraic values or list logic. Positive execution must succeed; each source
  mutant must exit92 with the exact designated failure line.
- Both strict Grease helpers parse through the actual retained pinned runtime.
  The complete helper's checkout-identity check requires the frontend git
  checkout used by hosted CI; local source/build checks above used the retained
  exact compiler archive directly and do not claim a full helper replay.

Local final DEX observations are under `ui-ioref-final`; ART remains
**PENDING**, and APK/physical-device observations are **NOT_RUN**. The additive
API29/API34 runtime workflow runs the exact helper and independent ART observer.

| Artifact | SHA-256 |
| --- | --- |
| positive/repeated DEX | `0e8a30111b366e4b5b03c39d44c23cb4dc81b4de3067d654075ac2b883c3f644` |
| payload source mutant | `b511f4891616c663333d28f1aae7dd5b69a5e41ba198f6ba22ac93ce20259b22` |
| alias source mutant | `cbea3a3188b96fe4582cef2b2e163577e24a158376b3af2e4e66c241de8f66ca` |
| write-target source mutant | `a45a32df20914b5b5da50e688e215940850dd7fa90469d8cd3f6b21445074d75` |
| omitted intermediate write source mutant | `2dde4107262879234285a59fd981e5a82822593926132e15eb75959372effa8f` |
| independent observer DEX | `2db96635a1de03a928404265938c0e12607ab19a9e08f7f602fc2ac5273dc8a1` |

## Remaining state boundary

This is local managed-cell support. It does not retain a cell between separate
framework callbacks, admit applied IORef at the public ABI, implement typed
instance fields or establish the lifetime of captured callback objects. Those
remain separate source and runtime work. This is not final Activity acceptance.
