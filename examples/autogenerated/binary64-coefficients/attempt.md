# Explicit binary64 coefficients through managed DEX

## Purpose and types

Explorer's numerical translation preserves the original jsurf binary64
coefficient behavior. This requires genuine `Double` literals and arithmetic
inside ordinary managed records/lists, rather than a lower precision default or
BigInteger arithmetic applied to floating values.

The compiler's bootstrap source remains `.idr`. The source probe uses `.idric`
and explicitly selects the inherited `Double` binary64 boundary.

- Target `Binary64Constant` carries an unsigned 64-bit IEEE representation.
- `Binary64Binary` names add/subtract/multiply/divide without integer coercion.
- `NegateBinary64` changes the IEEE sign using the target opcode.
- `CompareBinary64` explicitly chooses low/high NaN bias, so source comparisons
  preserve unordered NaN behavior and signed-zero equality.
- Managed values box as platform Double objects; arithmetic unboxes to paired
  virtual registers, executes the direct DEX operation and boxes the result.
- The compiler's literal conversion is pure, host-endian-independent binary
  decomposition. Finite values, infinities and signed zero retain their IEEE
  representation. NaNs use the canonical quiet NaN; source semantics do not
  expose a NaN payload preservation contract.

The separate platform-call extension admits descriptor `D` only when the source
foreign declaration explicitly uses `Double`. It boxes framework results and
unboxes managed arguments with paired register widths. The source adapter calls
`Double.parseDouble(String)` directly, matching the original jsurf contract;
malformed input keeps the platform `NumberFormatException`. Pure `Math.sqrt`
and `Math.pow` exercise one and two Double arguments. `doubleToLongBits` followed
by `Long.toHexString` supplies an independent textual observation without a
general floating-point formatting policy.

No public source Double export ABI, generic Text-to-Double cast policy,
Double-to-Text formatting policy, native callback lifetime or JNI
primitive-array ownership contract is introduced. Those boundaries still
refuse, as do Float32 descriptors and incompatible source/target types.

The real polynomial producer additionally needs `cast` from its runtime Int32
exponent to a Double coefficient for power evaluation and differentiation.
This narrow conversion validates the managed integer with `__idricIntExact`,
executes signed `int-to-double`, and boxes the Double result. Every signed
Int32 value is exactly representable in binary64. Other integral-to-Double
casts remain explicit refusals. Before this repair, `restore_width DoubleType`
refused the generic cast; it did not qualify a floating value by retaining its
BigInteger representation.

## Verification intended

An independent encoder fixture checks exact instruction bytes and register-pair
refusals. A focused layout fixture exercises placement without substituting an
assembler-produced candidate. The source probe distinguishes binary64 from
Float32/Float16, arithmetic order, NaN comparisons and signed-zero division.

The exact recovered frontend `0.8.0-740bbf2b1` typechecks all 21 backend modules
and builds the patched DEX driver. The separately compiled plan fixture executes
`PASS binary64 literal, encoder and placement checks`. The host source reference
executes both input branches and `PASS managed binary64 coefficients`.

The actual checked arithmetic source emits an 8.8 KiB DEX accepted by pinned baksmali
3.0.10. Independent disassembly contains the expected binary64 literal bits,
all four arithmetic opcodes, negation and both NaN comparison biases. This is
source generation and decoder evidence, not ART execution. The pure platform
source also emits and decodes; its `pow(DD)D` invocation occupies four argument
words. Repeated arithmetic and platform builds produce identical bytes. Both
source mutations emit different, independently decodable candidate bytes.
Independent smali observers assemble separately and never produce the candidate.

The inherited foreign-convention parser and encoder self-tests both execute
their PASS result with the rebuilt backend TTCs. Actual checked-source negative
controls reject a mismatched Double result, a mismatched argument, Float32,
arrays, a public Double export and the generic Text-to-Double cast without
writing a candidate DEX. The plan fixture additionally finalizes the actual
Double boxing/unboxing bridge and independently checks disjoint `pow` pairs.
The signed conversion fixture checks independent opcode bytes and paired
layout, including high-register staging and a truncated-output-pair refusal.
The source fixture exposes a runtime Int32 argument, observes its canonical
Double bits, and checks minimum/maximum signed values, negative one, zero and
16777217. Its compiled-source mutant increments the actual input before the
cast. The API matrix requires the original runner to accept the positive source
and reject that mutant. An Int64 source cast remains a negative control.
The local signed source/repeat emissions are identical, both positive and
mutated candidates decode independently, and the runner assembles. The decoded
positive contains checked integer unboxing, `int-to-double` and Double boxing,
with no Float32 conversion. The actual Int64-to-Double source exits with the
intended cast refusal and no candidate DEX. Re-emitting the existing arithmetic
and platform fixtures with the extended driver retains their exact prior bytes.

The compiler replay came from the root-verified artifact ZIP with SHA-256
`cdbbe9c12beba04c61090acfd86ba6845fcd80bfe8cfe45367a8238f57650cd3`.
The invocation runs the artifact's exact Chez 10.4.1 `scheme --program
idris2.so`, with explicit Scheme boot-library, runtime-library, installed-prefix
and package paths; `IDRIS2_PATH` names only this checkout's newly built backend
TTCs. No historical backend TTCs or alternate backend are used.

The existing `dex-runtime-repair.yml` qualifies the new source/encoder fixtures
with its pinned frontend and runs both positive candidates and compiled-source
mutants on its API 29/API 34 matrix. Existing runtime/source-refusal controls
remain present. The local replay does not contain the executable Grease runtime
(its recovered launcher points to the original runner), so maintained script
execution and ART execution remain pending hosted qualification. No APK,
native transfer or physical-device result follows from the host/decoder result.

The first recovered-compiler source check reported `Undefined name −` at the
ordinary expression operator. The pinned 740bb frontend accepts the token as an
operator name, but its inherited Prelude lacks the modern arithmetic aliases.
Declaring those fixities was also refused in both `.idric` and `.idr`
(`Expected end of input` at `infixl`). The probe therefore names the semantic
coefficient operations in words. `Binary64Operators.idr` is the explicit
bootstrap compatibility module binding those operations to inherited primitive
operators; the actual source probe remains `.idric` and imports it. No alternate
backend is used.

## First remaining boundary

The actual polynomial producer must use this arithmetic through checked source.
Prepared coefficient arrays still need a separately implemented typed transfer
and synchronous borrow/copy contract. A scalar arithmetic pass does not qualify
that JNI boundary or a finished Explorer APK.
