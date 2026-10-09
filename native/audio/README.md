# Android-native audio input

Status: canonical reusable Android input implementation, originally copied from
[`isomorphismes/Fourier-sound` `audio/native-input` at `0c05d1f5228cb4bba0f639b2c7f6f3e6281f7d59`](https://github.com/isomorphismes/Fourier-sound/tree/0c05d1f5228cb4bba0f639b2c7f6f3e6281f7d59/audio).

The source copy deliberately keeps its original names and include guards.  A
later compatibility or naming cleanup should be a separate, evidence-backed
change rather than part of this migration.

## Kept here

- `interface/` defines a C input-source contract with open/start/read/wait/
  stop/close operations, actual PCM properties, error states, and discontinuity
  accounting.
- `android/` implements that contract with Android NDK AAudio.  The callback
  writes only into a bounded single-producer/single-consumer PCM ring and wakes
  the owner through `eventfd`; it does not perform Fourier work, rendering,
  allocation, file I/O, or logging.
- `tests/` retains the original fake-AAudio host test.  It is a model test of
  the contract and backend control flow, not an Android build, APK, device, or
  microphone acceptance result.

## Kept with Fourier-sound

Fourier framing, PCM-to-mathematics conversion, microphone acceptance UI,
runtime permission handling, manifest, APK packaging, and the MIRO A1
procedure remain in Fourier-sound.  The detailed source account is
[`docs/audio-input.md`](https://github.com/isomorphismes/Fourier-sound/blob/0c05d1f5228cb4bba0f639b2c7f6f3e6281f7d59/docs/audio-input.md).

This snapshot implements an input source only.  No speaker/output sink moved
because none existed in the recovered source.  Android-NDK issue
[#10](https://github.com/isomorphisms/android-NDK/issues/10) records the
separate output-sink work without pretending it is complete.

The AAudio path is a generic Android route.  A Linux/PCM, SoC-specific, or
device-specific backend may coexist beneath the same input contract; this
directory does not flatten those choices into one fake universal backend.

## Division glyph and C producer

The two unsigned overflow-guard divisions in `interface/pcm_ring.c` now use
literal `÷`. ICK c61e448251744a2f40ad743ebef1a027bdcd2f9d gives them the same
integer semantics as `/`. This is a syntax/compiler-route change to the
copied source, with no interface or buffer-accounting change.

`make -f native/audio/Makefile host ICK=/absolute/ick` builds and executes the
retained fake-AAudio model. The Android target requires an explicit ABI,
NDK and installed ICK stage and compiles all three reusable audio sources
through ICK before NDK assembly/link. The hosted workflow qualifies all
three maintained ABI libraries at the AAudio API26 floor with NDK r29,
compiler builtin headers and the shared Fortify2 adapter. All producer
actions are pinned to ai-ci 903b2cb27ea572c9c6cb2ffa9f39e0fbf06ec9f8.

The shared C-stage contract is required. Fake host execution, an Android
library link and an application using a microphone remain distinct evidence.
This change supplies no application APK, signer, permissions or device result.
