# Direct DEX / ART

This directory is the canonical home for the recovered reusable direct-DEX
backend material.  It preserves the source distinction between a checked
compiler backend and application-boundary experiments.

## Checked direct DEX backend

[`idric/src/Backend/DEX/README.md`](idric/src/Backend/DEX/README.md) describes
the generic Idriç path:

```text
checked Idriç source -> Compiler.ANF -> typed DEX plan -> classes.dex
```

The backend writes DEX 035 directly for ART.  DEX is not ARM/Thumb code, and
the checked slice does not acquire an Android application object model, a
renderer, or framework-call semantics merely because ART can load its output.
The original hardening source and history remain visible through the
[migration inventory](../provenance/migration-inventory.md).

## Retained integration fixtures

`idric/wegert-dex.ipkg` and the `idric/tests/dex/native-activity/` material
preserve direct-DEX/NativeActivity/JNI integration evidence.  Their Wegert and
Analytic Continuation names deliberately remain visible: they document a
historical application boundary rather than an invented reusable UI layer.

Some retained tests reference app-specific sibling scripts that remain in the
Idriç source repository.  They are recorded as historical evidence, not
silently presented as portable green tests here.  The generic checked backend
test instructions remain in
[`idric/src/Backend/DEX/README.md`](idric/src/Backend/DEX/README.md).
