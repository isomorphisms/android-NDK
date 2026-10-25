# Focused direct DEX runtime acceptance

## Type/effect sketch before implementation

- Target: checked Idriç → direct DEX → Android ART, API 29 and API 34 x86_64 emulators.
- `PlainOutput.main : IO ()` writes one exact line without requesting process arguments or closures.
- `ClosuresAndRecords.Message` carries Text and List Text. `decorate : Text → Text → Text` creates a reusable partial application. `display : (Text → Text) → List Text → IO ()` applies it in source order.
- `Arguments.main : IO ()` obtains List Text arguments and prints a separately specified byte sequence, including a non-BMP Unicode value.
- `Unsupported.main : IO ()` calls a deliberately unavailable checked native declaration. Compilation must fail without publishing DEX.
- The sibling tail-call fixture supplies runtime-derived million-step self/mutual recursion, swapping, nested invocation and effect-order observations.
- Expected stdout is maintained in the observer, never derived from compiler plans or candidate output.
- Repeated emission must produce identical DEX. A source mutation must produce different bytes and fail the unchanged independent expectation.
- Plain output must not retain unused argv fields/accessors or `__idricApply`; this is a capability regression, not a benchmark.
- Host compilation and independent disassembly do not establish ART execution. Emulator execution does not establish physical-device acceptance.

## Procedure

`build.grease` builds the pinned backend and installs its compiler API, then calls `prepare.grease`. `prepare.grease` accepts explicit repository, driver, baksmali and fresh evidence paths. `observe.grease` accepts explicit adb, serial, prepared input and fresh ART evidence paths.

`prepare-native.grease` additionally accepts a qualified C driver and exact NDK path. It cross-compiles only the sibling JNI function-table fixture for x86_64/API29 and independently inspects the ELF header. It compiles explicit and legacy JNI maps separately. The sibling observer executes actual null/exception/narrowing/string cases.

No ICU/OpenSSL preparation, application packaging, signing or phone compilation occurs in this lane. Build/decoder observations and actual ART observations have separate receipts. Physical A1/C67 evidence remains NOT_RUN.

## Results

All four fixture sources typecheck with pinned frontend `740bbf2b1d9e811fd00c719c3473eede17ceea3b`. All four Grease scripts parse with the pinned compiled Grease (LeakSanitizer disabled only because this container cannot inspect process tasks).

The pre-repair PR30 driver rejected PlainOutput with exit 1: `dex rejected checked program: No checked helper body for DEX call Prelude.IO.prim__putStr`. This is the intended regression. Combined repaired-driver emission and actual ART execution remain pending.

The same checked PlainOutput and ClosuresAndRecords sources were separately compiled and executed through the pinned Chez reference backend on the host. Both exited 0. PlainOutput produced `plain-output-ok`; ClosuresAndRecords produced, in order, `count=1:first`, `count=1:A😀é`, `count=1:again`. These validate the independently maintained expectations, not DEX execution. Build commands used `--cg chez`, explicit source/build/output directories and the pinned support library.

## Combined repaired compiler emission

The final combined native driver ran this directory's `prepare.grease` to a
fresh evidence directory successfully. Plain output now emits without getArgs;
repeated plain emission is byte-identical. All four positive candidates decode
independently with baksmali 3.0.10. The unsupported foreign declaration exits
unsuccessfully with its exact unsupported-service diagnostic and no DEX.

| Checked program | DEX bytes | Methods | Classes |
|---|---:|---:|---:|
| PlainOutput | 896 | 4 | 1 |
| ClosuresAndRecords | 24,376 | 73 | 1 |
| Arguments | 22,572 | 68 | 1 |
| TailCalls, including varying group arity and 13-argument call | 29,044 | 83 | 1 |

PlainOutput's decoded class has no argv field/accessors or closure dispatcher.
Its requirement receipt names standard-output and the two checked methods,
entry wrapper and ART main. Closure dispatch is retained in the values fixture;
argument accessors are retained in the arguments fixture. Changed plain-output
source produces different bytes, ready for independent ART mutant rejection.

These counts describe distinct programs and must not be interpreted as a
comparative performance result. Actual ART observations and physical-device
acceptance remain NOT_RUN locally.
