# Checked Float32 values for Android interaction

## Type sketch before implementation

The actual frontend at740bbf2 has Double as its only floating primitive:
`Core.CompileExpr.CFType` has CFDouble and `Core.TT.Primitive.PrimType` has
DoubleType, with no Float32 alternative. Binding an Android `F` method as
Double would silently change the type and allow subtraction after widening.
The first actual source attempt below must therefore retain a distinct domain.

Use the existing checked external-type mechanism for `Float32`. Inside the
managed graph it is exactly a boxed `java.lang.Float`; a foreign `F` argument
or result is its primitive one-register float value. The domain constraint
must check the external flag and reject a conflicting descriptor. Ordinary
ADTs and Double cannot claim an F signature. Public source exports use the
validated boxed reference; this slice does not add frontend floating literals
or a primitive Float32 source type.

Central operations are `from_bits : Int32 → Float32`,
`bits : Float32 → Int32`, `subtract : Float32 → Float32 → Float32`, and
`widen : Float32 → Double`. The arithmetic operation is an explicit generic
`dex:float32:subtract` intrinsic. Its checked signature has two values from
one external Float32 domain and a result in that same domain; it emits one
real sub-float operation between unboxing and boxing. There is no widening
inside this intrinsic. Add/multiply/divide use the same bounded contract.

This is needed for MotionEvent.getX/getY and ScaleGestureDetector.getScaleFactor.
The application can subtract two Float32 coordinates before explicitly widening
the result for its existing Double renderer. Interaction semantics remain in
the application. No native callback, raw app-specific plan or Java source is a
candidate-producing substitute.

`Float.sum` was considered and rejected for this slice: Android's primary
reference says it requires API24, while Explorer declares minSDK23.
Boxed Float primitive conversion and raw-bit operations are API1:
https://developer.android.com/reference/java/lang/Float . DEX float arithmetic
does not add that API24 library dependency.

Required observations: actual source generation and independent decode;
signed-zero and finite rounding witnesses that distinguish subtract-then-widen
from widen-then-subtract; nonfinite classification without a NaN-payload claim;
genuine producer mutation rejection; ordinary/conflicting domains and widened
source signature refusals; preserved binary64/array/legacy behavior. ART and
minSDK23 framework behavior remain separate until executed.

## Results

The preserved old-driver `PlatformFloatProbe.idric` attempt typechecked but
refused generation with `Unsupported DEX descriptor type 'F'`. The full
arithmetic source also reached the old parser's `Missing dex foreign method
name` refusal for the new explicit intrinsic. Neither failure was replaced
by a widened Double binding or a different candidate generator.

The bounded implementation now builds through retained frontend740bbf2 and
passes source generation, independent baksmali decoding, deterministic repeat,
and a distinct compiled subtract-to-add source mutation. The actual positive
DEX is7168bytes, SHA256
`8ceeb9949895dea52d209e16bdcd710a2e8e083cb2dca2f0620e7f149372e187`;
the compiled mutation is
`8439b6c9e6b685164186f73d7dfb7c11f8b697bed5adab5dc1ec2f471da5a76b`.
The independent observer assembles and decodes. Its signed-zero, subnormal,
finite-rounding, infinity and NaN-classification cases are generated but have
not yet executed on ART. ScaleDetector remains a source/decode binding here,
not a real scale-gesture observation.

Host execution passes the separate exact opcode/placement/alias checks and
the checked-domain/signature/World/arithmetic plan checks. All four actual
negative source programs typecheck, then refuse their intended backend
boundary: ordinary domain, conflicting descriptor, widened F result and
widened arithmetic. The prior binary64 `UnsupportedFloat` case remains a
refusal: it now reaches the precise result-type mismatch after F descriptor
parsing, so its required diagnostic was updated rather than removing it.

Foreign convention, encoder, copied-array contract and binary64-plan host
regressions pass. Existing explicit-scalar and legacy JNI candidate bytes
remain identical to the pre-change daa6d66 candidates. Both new Grease scripts
parse through the retained Grease implementation. Local diagnostic replay
uses the exact retained Chez program directly because archived launchers
contain the original CI absolute paths; the maintained hosted verifier still
uses the ordinary checked compiler entrypoints.

The API29/API34 workflow now runs the complete source/platform observation and
must reject the compiled mutation with status73. That execution is pending.
No API23 execution, normal Activity, JNI, APK or physical-device acceptance is
claimed. Native source Float32 primitives and literal syntax remain separate
frontend language work; this explicit external domain is the bounded
interoperability contract exercised here.
