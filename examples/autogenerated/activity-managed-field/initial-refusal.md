# Retained source field probes

The probes were compiled with the actual direct-DEX driver at parent1432dad,
before a field binding was implemented. Both exited **1** and produced no DEX.

`ForeignFieldProbe.idric` attempts an ordinary platform method convention for
the applied managed cell. It was refused with:

```text
Error: dex rejected foreign declaration: dex foreign argument types do not match LIdric/Generated;->setState(Ljava/lang/Object;)V
```

`ExternFieldProbe.idric` keeps the exact source signatures through `%extern`.
It reached checked ANF and was refused with:

```text
Error: dex rejected managed exports: In ExternFieldProbe.initialize_state: Managed DEX unsupported checked external primitive ExternFieldProbe.set_state
```

Its original checked-ANF snapshot is retained as `initial-extern.checked.anf`.
These are retained diagnostic excerpts, not runtime observations. The field
implementation subsequently checks full normalized getter/setter source types
and only then binds the exact extern operations; it does not widen the foreign
or public ABI to accept arbitrary managed Object values.
