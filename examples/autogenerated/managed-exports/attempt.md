# Checked managed exports at the Android framework boundary

## Purpose and type sketch

IB's unchanged source projection uses lists, records and recursive helpers.
Its SearchIntentRequest also reads a validated external Intent and calls the
same checked Google URL operation. Command lowering already represents those
internal values, but framework exports still select the scalar/view lowerer.
The observed failures are `_builtin.NIL` and `Prelude.Types.fastUnpack`.

Retain the existing source export signature: Text, Int32, Bool and validated
opaque platform references, with pure or IO results. Ordinary source lists and
records stay internal and acquire no external object descriptor. A managed
export bridge converts only those admitted source boundary values to/from the
existing internal managed representation. Its checked World token is supplied
only to an IO body. Framework foreign declarations keep the existing exact
signature and external-domain validation before their runtime bridge is built.

Central operations:

- `managed_export_bridge`: checked export ABI and internal method → typed method.
- `managed_foreign_bridge`: previously validated platform declaration → internal method.
- `managed_exports_plan`: checked reachable graph and exports → canonical FilePlan.

Select this new boundary explicitly with `--directive managed-exports` during
qualification. Preserve the existing command and scalar/view routes, encoder,
placement and callback owner. Do not turn the command's main(String[]) into an
Activity, replace IB source, generate application Java or handwrite its DEX.

Required controls: actual list/record/closure source, scalar and text results,
platform construction/calls/casts, wrong signatures and unsupported boundaries,
independent decoding, semantic source mutations and ART execution. Then replay
the actual unchanged IB source projection and search receiver. Report the first
remaining primitive rather than silently routing around it.

## Evidence and remaining work

The baseline compiler at f0315c3110f0daa636b4e2b8223cf0b3bc3c459a reproduced
the unchanged search receiver's `Prelude.Types.fastUnpack` refusal with exit 1
and no receiver DEX. The first new attempt exposed the callback parser's
unrecognized mode directive, then missing `StrReverse` and `StrCons` in the
existing trim implementation. The compiler now consumes its own explicit mode
directive, preserves strict callback parsing, and lowers reverse/tail/cons with
Unicode character boundaries. No source fallback was selected.

With frontend 740bbf2b1d9e811fd00c719c3473eede17ceea3b, actual compiled Grease
orchestration, IB search dcbd86c0f7a69c4e0b381c0ab53f7c41f9966900 and IB reader
59716dabd375f0d49b8fb67a18dfd604b33a923a:

- Generic list/record/IO export emission and byte-identical recovery PASS;
  DEX SHA-256 3f8fea8a9a6e5ab8f1c2ae57ec48b8be4e9115763c4220ca851ffd01c3c269e9.
- Actual unchanged SearchIntentRequest emission PASS;
  DEX SHA-256 479abee4229eefa1670dd41d6c0df89d1744616afc19c674aa08e22b9950cd6c.
- Actual unchanged NativeSourceProjection emission PASS;
  DEX SHA-256 7c20301a781f4726d3925b1ccbd43602e2940e39b91a3b82d8f897eac0be244d.
- Pinned baksmali 3.0.10 independently decodes all candidates. A type-correct
  wrong platform signature is rejected before DEX; a semantic source mutation
  emits different bytes for the runtime observer to reject.
- All 15 preserved host suites PASS, including source loop values, layouts,
  callbacks, constructors and new Intent plans. The three external smali
  observers assemble with the pinned 3.0.10 assembler.

The workflow now compiles these pinned unchanged consumers and requires actual
x86_64 ART results, exact independent expected strings/widths, and the wrong
source's status-73 rejection. Runtime execution is NOT_RUN in the local
checkpoint. Source emission, decoding, ART, APK construction and physical C67
behavior remain separate results. This capability alone does not implement
Binder ownership, Activity lifecycle delivery or URL navigation.

## Language work

First capability: export the checked managed graph through the existing typed
framework ABI. Acceptance must execute source-generated exported methods on ART
and reject independently wrong source behavior. Producer qualification and
physical-device acceptance remain separate obligations.
