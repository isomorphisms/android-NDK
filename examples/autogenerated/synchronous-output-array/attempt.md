# Synchronous native Int32 output

## Type sketch before implementation

The application keeps its surface handle and renderer. The compiler owns only
the checked JNI call shape. This is a separate policy from copied input arrays:
native code may synchronously fill one final nonnull primitive Int32 array,
retains no local reference or array pointer, and publishes output only after a
complete successful operation. The caller keeps this array private until the
returned Int32 status indicates success. Descriptor syntax alone cannot prove
that an arbitrary native implementation follows those obligations.

The explicit policy is `current-thread synchronous borrowed-local
nonnull-output publish-output-on-success propagate-exceptions`. Arguments may
be exact Int32/I, Int64/J and binary64 Double/D scalars followed by exactly one
external Int32-array domain/[I. The result is exact Int32/I. Strings, input
arrays, another output kind, array results, retention and asynchronous variants
remain refused. Existing scalar and copy-input policies remain unchanged.

The application example is `(JIIIDDDD[I)I`: Int64 handle, two Int32 dimensions,
one explicit Int32 quality selector,
four Double camera/rotation/zoom values, private Int32 pixels, Int32 status.
The checked wrapper must unbox every source value at its declared width, use
two DEX words for both J and D, check the output array's actual type/non-null,
and let pending JVM exceptions propagate. It never formats numbers or pixels
as Text and does not synthesize Java code.

## Intended qualification

Use the maintained pinned frontend and direct backend. Include a real `.idric`
fixture, source/descriptor mismatch refusals, async/retention/ref-kind refusals,
compiled wrong-value mutation and independent descriptor/wide-register checks.
The actual AVE renderer and Bitmap observer belong in the application checkout.
No RefC, generic compiler or hand-authored candidate DEX is a fallback.

The sketch above preceded implementation. Heavy driver compilation was
serialized after the captured-Runnable owner's build.

## Source and generation result

The new policy is implemented in NativeContract; Heap unboxes exact Double
values and uses the existing register-width model for both J and D. Existing
scalar and copied-input declarations retain their previous lowering.

All compiler modules typechecked and the real Chez driver compiled after the
captured-Runnable owner released its build slot. Make's post-build runtime-copy
step first derived an invalid library path from the explicit compiler command;
the executable had already compiled. Installing the exact retained, checked
frontend runtime completed that packaging step without rebuilding or changing
the compiler. The frontend is the genuine740bbf2b checkout with the previously
qualified retained runtime/package tree; no alternate compiler is involved.

The maintained Grease qualifier executed fully: typed host plan checks, actual
source generation, independent decoding, byte-identical repeat, a distinct
compiled wrong-handle mutation and seven exact no-DEX refusal controls PASS.
The host plan checks14 native register words, including four Double pairs at
their exact positions. The generated bridge contains actual Double unboxing,
the output cast/non-null guard and `(JIIIDDDD[I)I` native call.

The existing copied-input/scalar host contract fixture also compiled/executed
unchanged. Actual old CopiedSurface source produces byte-identical DEX with the
fe74f72 baseline driver and this changed driver: SHA256
`8f9c582dc534926394e351ca20ad1a095e51fb9a2dcf0d38952c26979d33f206`.

The application-owned real Bitmap source separately emitted and decoded using
this policy. The test-only native output fixture/ART observer is retained here
for the exact native scalar/output contract, but its ICK Android compile and
actual ART execution remain PENDING. No physical-device result is claimed.
