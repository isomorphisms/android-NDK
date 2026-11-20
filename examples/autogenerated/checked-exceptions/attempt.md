# Checked source JVM exception actions

## Purpose and type sketch before implementation

The ordinary Explorer Activity needs exception cleanup after a provisional
native surface or output stream exists. A JVM allocation, Bitmap call or PNG
operation can throw; reporting a successful typed result cannot stand in for
catching that actual Throwable.

The first program uses the same checked `IO ()` action shape as the retained
captured-Runnable implementation. The pinned frontend represents this as
`CFUser PrimIO.IO [CFUnit]`; no conversion from an arbitrary Object is admitted.
The catch handler has exactly one external Throwable argument and returns the
same checked action type. The enclosing foreign result is `PrimIO ()`.

`catch_unit : IO () → (Throwable → IO ()) → PrimIO ()` executes the action
once and invokes the actual handler only for its actual JVM Throwable.
`finally_unit : IO () → IO () → PrimIO ()` executes cleanup exactly once,
whether the action returns or throws. Its cleanup exception replaces an action
exception, matching ordinary Java finally. It is not a try-with-resources
suppression policy. `throw_failure : Throwable → PrimIO ()` rethrows the same
reference. Source applications may deliberately add suppressed exceptions
when their resource policy requires first-exception preservation.

The backend must add symbolic protected regions and `move-exception` through
the shared finalized writer, retaining exact labels after register placement
and branch relaxation. DEX try records, their encoded handler offsets and odd
instruction padding are validated before bytes. Methods without protected
regions retain the previous binary encoding.

## Attempt and result

The reduced actual source is `CheckedExceptions.idric`. The retained combined
driver is used first to preserve its unsupported-convention refusal. No Java,
handwritten candidate DEX/Smali, native exception relay or alternate compiler
is a fallback. Local generation, byte decoding, ART and application/physical
acceptance remain distinct evidence.

## Writer and observer contract

The encoding follows the Android Open Source Project's
[DEX code-item and catch-handler format](https://source.android.com/docs/core/runtime/dex-format#code-item):
try ranges use code-unit addresses, are sorted and disjoint, and reference
byte offsets into the handler list. Odd instruction counts add exactly two
padding bytes only when a try list exists. Each current handler list contains
one typed Throwable catch, encoded with a positive signed-LEB count of one.
No catch-all or overlapping typed-catch policy is inferred.

`MoveException` is legal only at a declared handler entry. Both ordinary
fallthrough and explicit branches into that entry refuse; register placement
keeps the actual move-exception first, including a destination above255.
The combined reference-null branch receives the same entry validation.

The independent observer executes seven actual source paths: normal catch,
exception catch, throwing-action cleanup, normal-action cleanup, cleanup
exception precedence, handler exception propagation and normal-action cleanup
failure. A caller-created Throwable is passed through the actual source rethrow
and compared by object identity. Three separately compiled source mutations
change cleanup output, handler output or rethrow identity. Their designated
observer assertions exit95; unexpected Throwable exits96. Process death,
timeout and verification/link failures never count as mutation rejection.

The source program frontend-checks and the separate observer assembles locally.
The two maintained Grease helpers parse with the retained pinned runtime.

The full qualifier then passed using the combined26-module driver's actual
SO, SHA256 `9b09ca2c61153b85d02214ea7cd310415c0742a67be5e3cd1ab0173a45348c11`,
and its current TTC. The host protected-region/refusal program executed; the
actual source generated twice with identical10100-byte output; independent
baksmali decoded both real exception handlers and rethrow instructions. The
compiler's readable Smali reassembled and its decoded result matched the
direct-writer candidate. All three actual source mutants generated distinct
bytes. All five source refusal programs frontend-checked and then refused
at the intended backend boundary with exit1 and no candidate DEX.

The positive candidate SHA256 is
`85a2e66dd73aeb40178bdf761cd5c44752ccdc496cbcd325163262a3e7138328`.
The separate observer SHA256 is
`8805b60dcedd215afa1479d25a7cdb9a2ebb899b166519d2c28d0d9e9c8b0755`.
These are local generation/host results. ART remains NOT_RUN. No installed
Activity, PNG resource policy, physical device, broad asynchronous exceptions
or OOM cleanup is established.
