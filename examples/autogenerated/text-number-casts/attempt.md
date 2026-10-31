# Checked Text numeric casts

IB's complete admitted HTML/Prepaint consumer reaches the checked primitive
`Cast String Integer` when reading independently supplied source byte counts.
Merged backend 6ab4818219efa7ea5eda137ca6b76976eb2a4d42 refuses that operation.
Do not replace IB's semantics or manufacture its observations to avoid it.

The source boundary remains `Text` to the chosen source integer width. The
managed representation is an implementation detail. Integer conversion must
retain invalid-input behavior and narrowing must retain signed/unsigned width;
a platform parser exception or arbitrary-precision storage must not silently
replace those semantics. Decimal, fractional and malformed dynamic inputs need
independent runtime expectations and a compiled mutation control.

The inherited frontend's Chez support is a semantic reference only, never the
candidate DEX producer. Candidate bytecode must come from checked source through
the maintained DEX backend. Host reference execution, independent DEX decoding,
ART execution and application acceptance remain separate observations.

The repaired slice accepts ASCII signed decimal integers, finite decimal or
exponent notation (including the frontend's exponent-letter aliases), and exact
decimal ratios. It retains zero for malformed text and division by zero in a
ratio, and applies the source width after parsing. Complex/polar values,
precision suffixes and explicit nonfinite notation remain unqualified and raise
an explicit `UnsupportedOperationException`; this is not full Scheme numeric
syntax support. Inexact decimal conversion retains the binary Double value
before truncation. The Android platform's
[BigDecimal constructor and integer conversion](https://developer.android.com/reference/java/math/BigDecimal)
provide that target operation; they do not define the source integer type.

Initial host observations: the old backend refuses checked source with
`Managed DEX unsupported numeric cast from String`. With the repair, the same
maintained 20-module IB document consumer typechecks, emits a 277580-byte DEX
and independently decodes. A separate cast fixture emits and decodes. These
are generation/decode observations; ART and compiled-mutant qualification are
still pending. The frontend is 740bbf2b1d9e811fd00c719c3473eede17ceea3b and its
local native support was built with qualified ICK c61e448251744a2f40ad743ebef1a027bdcd2f9d;
the hosted lane uses its declared independent compiler pin.
