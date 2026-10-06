# Agent entry point

For maintained Android application work:

1. read `ARCHITECTURE.md` and `apk/README.md`;
2. use `apk/build-nativeactivity-apk.sh` for framework NativeActivity packaging unless the application has an explicitly reviewed different Android-facing shape;
3. obey the shared AICI `build-toolchain-v0` and Android update/signing identity rules;
4. never generate or silently select a signing key for a maintained installable APK;
5. keep application package IDs, signer lanes, resources, SDK bounds, and acceptance evidence application-owned.

Historical fixtures under `dex/idric/tests/` are evidence and test harnesses, not default production packagers.
