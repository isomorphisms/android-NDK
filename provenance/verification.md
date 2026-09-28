# Migration verification

This record separates source preservation from runnable Android acceptance.
It reports only checks completed in this migration workspace.

## Completed checks

| Check | Result | Scope |
| --- | --- | --- |
| incoming migration history | **PASS** | The pre-existing `migration/dex-jni-nativeactivity` lane remains its original five commits under the merge on `ndk-dex-jni-migration`; no bulk reconstruction replaced it. |
| Idriç direct DEX source identity | **PASS** | All 14 files under `dex/idric/src/Backend/DEX/` match `fuego-ironworks/idric-arm-thumb` `53d2e822e41d7cc66e5e4d0b61f3f6e43cd17575` byte-for-byte. |
| reusable audio and sensor source identity | **PASS** | All 10 copied C/header/test files match their recorded Fourier-sound or utilities source blobs byte-for-byte. |
| AAudio contract host test | **PASS** | The preserved fake-AAudio test compiles with strict host C warnings and reports successful rate/format negotiation, readiness, copying, restart, overflow, disconnect, and cleanup behavior. |
| local documentation paths | **PASS** | Each new repository-level relative target named from the overview, DEX, JNI, APK, native, hardware, and provenance documents exists in this branch. |
| patch whitespace | **PASS** | `git diff --check` reports no whitespace errors. |

## Not run, and why

| Check | Status | Concrete boundary |
| --- | --- | --- |
| Idriç DEX compiler/backend build | **NOT RUN** | The declared Idriç executable is absent from this workspace.  No substitute compiler or fallback path was used. |
| Android NDK native build | **NOT RUN** | No Android NDK or SDK root is configured here. |
| APK creation/signing/verification | **NOT RUN** | `aapt2` and the application-owned package/signing inputs are absent. |
| emulator, ART, or physical-device acceptance | **NOT RUN** | `adb` is absent and no Android target is attached.  The host fake-AAudio result does not stand in for Android microphone or sensor behavior. |
| retained JNI control-flow test | **NOT RUN** | `dex/idric/tests/dex/jni-build-boundary-test.py` calls Reddit and Wegert scripts kept with their application fixtures in the Idriç source tree.  This branch preserves the test and records that non-portability instead of copying app code merely to make a local test pass. |

## Accounting result

[`migration-inventory.md`](migration-inventory.md) assigns every substantial
recovered item one of: canonical move, specialized reference copy, retained
in place, deliberately unresolved, or historical integration material.  The
inventory also records the source repository, path, revision, and the reason
for retaining work outside this repository.  No recovered component was
deleted or silently recast as a generic interface during this migration.
