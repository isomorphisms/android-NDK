# Checked managed value layouts

## Type and effect sketch, before implementation

- Domain: constructor identities, ordered managed reference fields, checked function targets, captured values, total arity and remaining arity.
- `checked_constructor_layout : String → Nat → Either String ManagedValueLayout` validates one constructor's private storage contract.
- `checked_closure_layout : String → Int → Nat → Nat → Either String ManagedValueLayout` validates total arity = captured count + remaining arity, with at least one argument still missing.
- `checked_node_fields` checks an emission input list against its layout. `managed_field_slots` gives the ordered payload slots after the tag.
- Constructor creation and case projection must use the same tag/field plan. A matching tag with a different payload count must fail before projection.
- Closure creation must preserve captures. Application is owned by the coupled tail-call work; it must use the same slot/arity contract and copy existing captures before appending a new argument.
- Effects: the compiler returns explicit layout errors; generated code allocates ART-managed nodes and may throw on an invalid runtime shape.
- Backend: checked Idriç → direct DEX. No public object ABI or native heap is introduced.

## Representation boundary

The current ANF slice supplies erased managed payloads, not reliable typed field descriptors. The writer currently admits declared static fields, not arbitrary instance-field plans. Therefore this repair keeps the generic ArrayList representation and makes its layout explicit and checked. Replacing fields with guessed JVM primitive types would not be a correct specialization. No performance improvement is claimed.

The upstream Idris JVM constructor design is a reference for keeping construction, projection, dispatch and casts coherent; no upstream source is copied.

## Intended observations

Run host layout law/refusal controls, compile a checked program using two constructors and a reusable partial application, independently decode its DEX, and inspect the constructor shape guards. ART execution belongs to the integrated acceptance lane and is not inferred from these host observations.

## Observed results

Frontend: Idriç `740bbf2b1d9e811fd00c719c3473eede17ceea3b`. Baseline DEX source: `973c24bc0b4eab6f3c88699102f7cb0e7fd8951f`. Build host: the isolated Linux x86_64 workspace, not a phone.

- All backend modules passed checked compilation. The final native Chez compiler executable build was killed with exit 137 while other compiler builds were active. This is not counted as a successful native executable build.
- `ValueLayoutTest.idr` compiled and executed successfully: `PASS: checked managed value layout laws and refusal controls`. It includes empty/pair slot order, captures plus missing arguments, no independent 12-argument layout ceiling, empty identity, zero/negative target arity, saturated closure and truncated/extra payload refusal controls.
- The checked sample ran through the pinned Chez reference. No extra arguments produced `empty`, `x:right`, `xxa`, `xb`; the argument `Q` produced `empty`, `Q:right`, `QQa`, `Qb` on separate lines. The last output demonstrates reusing the previously captured closure after a nested application.
- The newly generated backend Chez source was executed with the same pinned Chez interpreter to emit direct DEX, avoiding another native compiler build. baksmali 3.0.10 independently decoded the result. Actual decoded constructor-case bodies compare ArrayList size with the expected slot count before field projection.
- DEX output: 23,268 bytes, SHA-256 `7f5561ec3d93e6660869c6e9cd2a1dc86db70630cecbb9718e2718ba115d4ed1`; 72 generated methods in `LIdric/Generated;`. The baseline backend emitted 22,296 bytes for the same checked source, SHA-256 `1c31428d4546a3c51b0024ea52b7ecafa38b1214ddf0313abfa1a95b591d4b4b`. The shape guards therefore cost 972 DEX bytes in this fixture. This is an emission-size observation, not a runtime speed or allocation benchmark.
- The frontend optimizes the sample's two-constructor shape to built-in NIL/CONS representations; the check remains about the frontend's actual checked constructor layout, not about forcing source constructors to have distinct generated classes.
- New ART execution and physical-device acceptance: **NOT_RUN** in this isolated task. These remain integrated acceptance responsibilities.

## Exact local invocation boundary

Commands ran in `/workspace/scratch/a6451c61927a/runtime-layouts/dex/idric` unless an absolute source path is shown. Compiler: `/workspace/scratch/58fb4da72caa/Idric/_/build/exec/idris2`; Chez: `/workspace/scratch/58fb4da72caa/Idric/_/.tools/bin/scheme`.

Environment: `IDRIS2_PREFIX=/workspace/scratch/58fb4da72caa/Idric/_/bootstrap-build`; `IDRIS2_PACKAGE_PATH` is its `idris2-0.8.0` child; `IDRIS2_DATA=/workspace/scratch/58fb4da72caa/Idric/_/support`; `IDRIS2_LIBS` is that support directory's `c` child; `IDRIS2_PATH=/workspace/scratch/a6451c61927a/runtime-layouts/dex/idric/build/ttc`; `CHEZ` is the exact Chez path above.

| Stage | Arguments after the identified executable |
|---|---|
| Backend checked compilation and attempted native executable | `--build backend.ipkg` |
| Host layout controls | `-p idris2 --source-dir tests/dex --build-dir /workspace/scratch/a6451c61927a/layout-evidence/host tests/dex/ValueLayoutTest.idr -o value-layout-test` |
| Checked host sample | `--cg chez --source-dir /workspace/scratch/a6451c61927a/runtime-layouts/examples/autogenerated/runtime-value-layouts --build-dir /workspace/scratch/a6451c61927a/layout-evidence/reference /workspace/scratch/a6451c61927a/runtime-layouts/examples/autogenerated/runtime-value-layouts/ValueLayouts.idric -o value-layouts` |
| Fresh DEX emission | Chez `--script /workspace/scratch/a6451c61927a/runtime-layouts/dex/idric/build/exec/idric-dex_app/idric-dex.ss --cg dex --source-dir /workspace/scratch/a6451c61927a/runtime-layouts/examples/autogenerated/runtime-value-layouts --build-dir /workspace/scratch/a6451c61927a/layout-evidence/dex --output-dir /workspace/scratch/a6451c61927a/layout-evidence/dex/exec /workspace/scratch/a6451c61927a/runtime-layouts/examples/autogenerated/runtime-value-layouts/ValueLayouts.idric -o value-layouts` |
| Independent decode | `java -jar /workspace/scratch/58fb4da72caa/oracles/baksmali.jar disassemble /workspace/scratch/a6451c61927a/layout-evidence/dex/exec/value-layouts.dex -o /workspace/scratch/a6451c61927a/layout-evidence/disassembled` |

The generated backend source needs `LD_LIBRARY_PATH=/workspace/scratch/58fb4da72caa/Idric/_/build/exec/idris2_app` and `IDRIS2_INC_SRC=/workspace/scratch/a6451c61927a/runtime-layouts/dex/idric/build/exec/idric-dex_app`. Reference/host executable directories received the existing pinned `libidris2_support.so`. One emitted host `.so` lacked its executable bit; setting that bit fixed the wrapper invocation. An initial host test edit omitted the IR import required for the exposed storage descriptor type; the compiler diagnostic was inspected, the import was added, and only the subsequent successful compilation/execution is credited.

## Resulting language/backend work

The first boundary for typed constructor specialization is preserving trustworthy checked field types into layout planning and supporting declared instance fields throughout the existing finalized DEX plan. A follow-up should prove construction/projection/casts on one actual typed record on ART before broad specialization. No such source type information or encoder support is fabricated here. Until then, explicit generic layouts with field-count guards remain the supported implementation.
