# Program attempt: checked source effects for DEX

Status: `SOURCE_CHECKED`; candidate DEX and ART checks are recorded separately.

## Purpose

Expose the actual checked compiler representation of external references,
primitive IO, ordinary IO wrappers, void effects, and sequencing before
extending the DEX lowerer used by Quick Settings bindings.

## Intended behavior

This development fixture describes public Parcel calls as a small mutable
foreign boundary. It is an acceptance probe for the compiler and never a tile
purpose. Its source-checking and ANF inspection stages execute no Android IO.

## Type-system sketch

### Values and domains

`Parcel` is an opaque framework-owned reference, distinct from machine
integers and ordinary algebraic data. Java int uses explicit `Int32`.

### Types and signatures

The source compares `Parcel → PrimIO Int32` with `Parcel → IO Int32`.
The sequence writes one integer, restores the data position, and reads it.
Foreign setters return `PrimIO ()`; the sequence result is `IO Int32`.

### Actions and effects

Each Parcel operation remains a foreign effect, including reads. The World
token orders primitive effects and must not appear as a DEX argument. The
absence of a useful result must not erase or duplicate a foreign operation.

### Laws, invariants, and errors

External references retain their nominal source domain and target descriptor.
Void cannot become an allocated language unit object at the framework boundary.
The sequence must preserve all foreign calls in source order. Null/invalid
Parcel references retain framework exception semantics; this probe invents no
null proof or fallback runtime.

### Runtime and backend boundary

The existing compiler provides `Compiler.ANF` through `getCompileDataWith`.
Foreign definitions retain `CFWorld`, `CFIORes`, and `CFUser` metadata. The
baseline backend should dump actual checked ANF before source ABI rejection.
No source-pattern recognizer, RefC, Java, JNI, Gradle, or smali candidate is an
implementation route.

## Idriç attempt

Sources: `QuickSettingsSourceEffects.idric`, `QuickSettingsBoolean.idric`,
`OrdinaryReferenceRefusal.idric`, and `ConflictingReferenceRefusal.idric`.

Compiler: `/workspace/scratch/fd7b61cd742b/Idric/_/build/exec/idris2`, source
`ff4d852862a3942592f8ade9afde8d409d9803be`, actual version `0.8.0-ff4d85286`.
The DEX worktree starts at `42f04d7` and restores the relevant source modules
from `8e5458d5baad066bc365347717c56d6836eba362` before this extension.

The actual compiler checked the Parcel and both nominal-reference refusal
fixtures. The compiled baseline DEX driver checked and dumped both the Parcel
and Boolean graphs, then rejected their unsupported source ABIs. The baseline
driver is `android-NDK/dex/idric/build/exec/idric-dex` in the adjacent original
checkout, with compiler version `0.8.0-ff4d85286`.

The driver was called with `--cg dex --dumpanf`, the fixture source directory,
isolated build/output directories, and the exact compiler/prelude/base TTC
search roots. The Boolean source additionally imports the freshly checked
Quick Settings package TTC. No Android operation executes during this step.

The baseline driver prints a backend error but exits zero. Acceptance therefore
requires a fresh output artifact and independent validation; process exit zero
is not evidence of DEX generation. `baseline-checked.anf` and
`boolean-baseline-checked.anf` preserve the actual checked graphs.

## Result or failure

The baseline rejects `obtain_then_recycle` because its source export classifier
admits only Int32/Text. It likewise rejects the Boolean fixture at
`boolean_false`. Neither baseline invocation produced a candidate DEX.

The Parcel graph demonstrates one trailing World formal, ordered foreign lets,
and void setters/recycle calls. The public `is_locked` and `is_secure` wrappers
use checked partial applications and `Prelude.IO.map`, then Int32 equality.
The actual compiler represents Bool constants and cases as numeric enum tags.

The changed backend modules pass `--check` against the exact compiler API.
They validate each inferred nominal reference mapping against the checked
external-type flag and reject conflicting mappings; remove only the checked
trailing World argument; retain all residual foreign effects; and select
reference, scalar, or void returns. Static checked helpers/closures are
specialized, with continuations distributed over source cases so algebraic
values can be projected internally without inventing a foreign sum ABI.

Boolean results admit the observed zero/one enum representation and checked
Int32 comparisons. The Boolean fixture includes pure constants, dynamic
identity/negation, an Int32 predicate, and an IO predicate on a boxed Java
Integer. Its two actual TileService wrappers are emission probes and do not
create or register a service.

The two refusal sources deliberately pass ordinary algebraic data as a
framework receiver, or assign one opaque type two different Java descriptors.
They are valid frontend source; candidate backend rejection is the acceptance
condition. The separate runtime fixture also retains an unprojected
`IO (Maybe TileState)` export refusal.

## Fallback

None.

## Idriç language work exposed

The checked ANF provides enough information for this slice without a World or
Unit object ABI. Runtime source closures, recursive helper specialization,
escaping source constructors, unprojected algebraic exports, and wide source
values remain outside the supported boundary. No generated callback class or
general Java object boxing ABI is implied by accepting an existing callback
reference.

## Evidence boundary

Source checking, checked ANF, DEX emission, and ART behavior remain separate
results. `verification.txt` records this source-stage evidence. The root-owned
host and ART verifiers record any later candidate results; this source-stage
receipt itself makes no Android execution claim.
