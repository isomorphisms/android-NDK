# Retained pre-implementation probe

At callback compiler commit `e2cf58f2bfc4f564d15f5009fe4b18a64cec2e44`,
the original `ManagedIORefSource.idric` probe created two cells, aliased the
first, replaced its ADT/list/Text payload and read both. The pinned frontend
host executable printed `PASS managed IORef host semantics`.

The actual direct-DEX invocation exited **1**, with this diagnostic:

```text
Error: dex rejected managed exports:
 In Data.IORef.{newIORef:0}:
 Managed DEX unsupported checked expression
 %extprim Data.IORef.prim__newIORef([__], v0, v1)
```

Its emitted checked-ANF snapshot is retained in `initial-probe.checked.anf`.
That snapshot also contains the exact read and write forms:

```text
%extprim Data.IORef.prim__writeIORef([__], v2, v16, v1)
%extprim Data.IORef.prim__readIORef([__], v2, v1)
```

This is a retained diagnostic excerpt, not a new runtime observation. The final
fixture adds initial and intermediate reads around two writes to observe
creation and sequential replacement as well. The original unsupported public
`IORef Text` export remains a required refusal in `IORefPublicBoundary.idric`.
