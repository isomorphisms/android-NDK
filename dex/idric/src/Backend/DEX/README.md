# Idriç → DEX backend

DEX is an Android Runtime target, not a processor ABI. This backend emits one
small DEX 035 application-code class directly and leaves ARMv7, AArch64, x86,
or x86-64 machine-code generation to ART.

DEX is also ART's class-and-method executable format. Using its class model or
calling Android framework classes is not an indirect Java build. The direct
boundary means that Idriç owns the DEX instructions and metadata without
generating Java source or passing program semantics through `javac`, Kotlin,
Gradle, or `d8`.

The executable path is now:

```text
.idric source
  -> current declared Idriç parser, elaborator, and type checker
  -> Compiler.ANF
  -> Backend.DEX.IR method plan
  -> Backend.DEX.Encode
  -> classes.dex
```

`Backend.DEX.Smali` renders the same plan for review. The smali assembler is an
oracle and builds the external test runner only; it is not in the candidate
compiler path.

## Checked compiler handoff

The custom code generator uses `getCompileDataWith ["dex"] False ANF` from the
Idriç revision resolved from the declared `Idriç` branch. The first green
historical revision was `081b9cde0591154839fb5d80d76e5570e0436300`. It accepts only
functions selected by `%export "dex:<method_name>"` after elaboration.

The first source ABI is deliberately explicit:

- zero or more ordinary `Int32` parameters;
- an `Int32` result;
- no erased or implicit method parameters.

The lowerer consumes `Compiler.ANF`, not source text. It currently recognizes
checked Int32 constants, locals/lets, `Add Int32Type`, `Sub Int32Type`, and
`Mul Int32Type`. The currently tested compiler retains overloaded Int32 `<` as the
resolved checked name `Prelude.EqOrd.<`; the bridge lowers that exact checked
call and its Boolean 0/1 case form. Other named calls are rejected.

Compilation retains four adjacent evidence files for `-o classes`:

- `classes.checked.anf` — selected checked one-step definitions;
- `classes.dex.plan` — typed target plan;
- `classes.smali` — readable oracle rendering;
- `classes.dex` — direct production artifact.

The literal-only `add_constants` fixture is legitimately folded to `19` by the
current compiler. The parameterized checked `add` definition retains
`%op +Int32`; the ART harness calls it with 12 and 7 and checks 19.

## Implemented DEX subset

The typed target plan has integer constants, moves, add/subtract/multiply,
six two-register integer conditions, conditional branches, labels, `goto`, and
integer return. The direct encoder implements these concrete formats:

| Operation | DEX opcode / format |
| --- | --- |
| constant | `const/4` 11n, `const/16` 21s, `const` 31i |
| move | `move` 12x, `move/from16` 22x, `move/16` 32x |
| arithmetic | `add-int`, `sub-int`, `mul-int` 23x |
| comparison branch | `if-eq` through `if-le` 22t |
| jump | `goto` 10t |
| result | `return` 11x |

Format selection checks register and signed-literal ranges. Branch labels are
resolved in code units; zero and out-of-range 10t/22t offsets are rejected.
Parameters occupy the last virtual registers as required by DEX. There is no
physical CPU register allocator.

The file writer owns DEX magic/version, header, sorted string/type/prototype and
method identifiers, one class definition, type lists, code items, string data,
class data, map list, alignment, SHA-1 signature, and Adler-32 checksum. Output
is deterministic for a deterministic plan.

## Verification

Run:

```sh
make dex-test IDRIC=/path/to/Idric/build/exec/idris2
```

This checks the compiler revision, typechecks the backend, compiles the real
Idriç fixture, retains checked ANF and the plan, tests encoder boundaries and
malformed plans, rejects a 64-bit `Int` export, regenerates deterministically,
checks the DEX header and hashes independently, disassembles with pinned
baksmali, and compares that disassembly with the smali-oracle artifact.

`make dex-device` additionally uses a connected Android device or emulator. It
loads the directly encoded candidate beside a separately assembled test runner
and invokes it with Android's `app_process`. Absence of a device is reported as
`SKIP` with exit status 2. CI provides a bounded API-29 x86-64 emulator
job; it does not require a permanently attached phone.

See [`AUDIT.md`](./AUDIT.md) for the starting boundary and
[`OPCODES.md`](./OPCODES.md) for the complete opcode inventory.

## Current generic compiler boundary

The checked-ANF compiler slice does not yet claim general calls, recursion,
constructors, objects, arrays, fields, strings, exceptions, monitors,
annotations, debug data, wide 64-bit values, floats, Float16, Android framework
calls, lifecycle classes, resources, APK packaging, signing, or source-level
IO. These are limitations of the present slice, not a rule forbidding DEX from
representing them. Unsupported ANF and DEX plans fail; there is no RefC,
Java-source, `javac`, Kotlin, Gradle, ARM Thumb, smali-candidate, or `d8`
fallback.

The separate `wegert-dex.ipkg` package directly emits the current
`NativeActivity` subclass and JNI declaration as an Android application
adapter. It proves that direct DEX can express the Java-shaped class boundary
ART expects without a Java compiler. It is not yet produced by the generic
checked-ANF lowering above.

APK/UI machinery remains outside the generic semantic lowering. A framework
call or other Android-facing extension to that lowering should be added with a
concrete checked Idriç fixture that requires it.

## Locating and changing direct-DEX choices

The cross-repository [ComputerScience lowering decision atlas](https://github.com/walnut-burgundy/computer-science/pull/82) tracks **where** a decision is made, its alternatives, its available change point, and what later stages did with it. This note supplies concrete landmarks for the direct-DEX baseline. Follow the active [DEX pull requests](https://github.com/isomorphisms/android-NDK/pulls) separately: work on PR heads is not automatically on `main`.

| Question | Code to inspect and change | Evidence boundary |
| --- | --- | --- |
| Which checked source functions and types are admitted? | [`Codegen.idr`](Codegen.idr): `classify_value_type`, `parse_source_signature`, `resolve_export_abi`, `lower_exports` | Rejected signatures, checked source and retained checked one-step definitions |
| How are one-step operations turned into a typed target plan? | [`Lower.idr`](Lower.idr), [`IR.idr`](IR.idr), especially `lower_method` and `MethodPlan` | `classes.dex.plan`; unsupported cases must fail explicitly |
| How are virtual registers, constants and instruction widths encoded? | [`Encode.idr`](Encode.idr): `move_width`, `instruction_width` and encoding routines | `classes.dex`, independent decoding/disassembly and boundary tests |
| Which source-level meanings are preserved? | [Idriç `Compiler/ANF.idr`](https://github.com/isomorphisms/Idric/blob/Idri%C3%A7/Compiler/ANF.idr), [its control-flow distinction](https://github.com/isomorphisms/Idric/blob/Idri%C3%A7/notes/control-flow-predication.md) | Source/checked-form comparison; the DEX encoder cannot redefine semantics |
| What happens after DEX emission? | [Android ART](https://android.googlesource.com/platform/art/) (outside this repo), selected runtime version, compilation/profile settings | Target-specific ART output and runtime observations; no machine instruction claim from the DEX plan alone |

For immutable lookup machinery such as URL/mention/hashtag recognizers, separate the **recognition algorithm** (scanner, trie, DFA), **data layout** (DEX constants, initialized objects, native read-only data, APK asset), **runtime behavior**, and **physical execution**. DEX constants do not prove a shared zero-allocation table. A compiler-produced `classes.dex` is not ARM/Thumb output, and a native `.so` is not DEX.

Record the actual code symbol, revision, selected/rejected alternatives, edit point, generated output and downstream observation before asking the planner to automate the choice. The [English Major C machine model](https://github.com/isomorphisms/English-major-C/blob/main/architecture/armv7-a/t32/Given%20a%20machine%20-%20objects%20and%20execution.english) is a separate bottom-up reference; it is not evidence of an ART-generated instruction stream.
