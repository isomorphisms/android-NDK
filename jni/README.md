# JNI boundary

JNI belongs at a narrow Android/framework-to-native boundary.  It does not own
application semantics, render every frame, or stand in for a generic Android
application model.

The recovered direct-DEX fixtures live under [`../dex/idric/`](../dex/idric/):

- a DEX class can declare an application-specific native method;
- the NDK library exports the matching JNI symbol and any required
  `ANativeActivity_onCreate` entry point; and
- the packaging/ART tests verify the class, native library, and matching
  application identity together.

[`../dex/idric/tests/dex/jni-build-boundary-test.py`](../dex/idric/tests/dex/jni-build-boundary-test.py)
is retained as source-JNI build-script evidence.  In the original Idriç tree it
calls the application-specific Reddit and Wegert `build-jni.sh` scripts; those
scripts stay upstream with their application fixtures, so this copy is not a
self-contained generic test.  Its mock-NDK checks still explain the intended
failure behavior for a missing symbol, compiler failure, and `readelf` failure.
It is not an Android compilation, package, emulator, phone, or hardware result.

Wegert-specific JNI names and rendering remain Wegert's application boundary.
The DEX repository retains those fixtures as attributable historical evidence,
not as a generic UI or renderer API.
