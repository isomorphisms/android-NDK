# Reduced missing operation

The actual `CheckedExceptions.idric` program was submitted to the combined
retained direct DEX driver from local c1afd27 (published tree-equivalent
d98149a9fab5234bb08889e84e4c06808184e5eb). The checked frontend completed; the
backend refused the newly required convention with exit1:

```text
Error: dex rejected foreign declaration: Missing dex foreign owner
```

No candidate DEX was emitted. This is a genuine unsupported-operation refusal,
not an ART result. The action parameter uses the same checked `IO ()` source
type as existing captured Runnables; the caller uses `primIO` for the foreign
result. No `toPrim`, unsafe Object cast or user-defined Java exception relay
is required.
