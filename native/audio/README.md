# Android-native audio input

Status: canonical reusable Android input implementation, copied without source
edits from
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
