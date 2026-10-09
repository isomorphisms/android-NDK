# Android NDK

This repository is the canonical home for the generic Android-native
architecture shared by the projects in this organization:

- direct DEX and ART bootstrap work;
- JNI and NativeActivity boundaries;
- NDK/native execution and reusable Android-facing interfaces;
- ordinary APK construction, signing, and distribution boundaries; and
- the generic path from native application code toward Android system services
  and hardware-facing layers.

It does **not** own application mathematics, rendering choices, domain state,
or device-specific reverse engineering.  Hardware remains deliberately jagged
where the actual hardware differs.

## Start here

- [Architecture overview](ARCHITECTURE.md)
- [DEX / ART backend and historical integration fixtures](dex/README.md)
- [Quick Settings source bindings for Idriç consumers](quick-settings/README.md)
- [JNI boundary](jni/)
- [APK and distribution path](apk/)
- [Reusable native Android interfaces](native/)
- [Hardware reference dossiers](hardware/)
- [Migration inventory and provenance](provenance/migration-inventory.md)
- [Migration verification record](provenance/verification.md)

The migration inventory distinguishes canonical generic material from copied
specialized references, application-owned consumers, historical experiments,
and unresolved items.  A copied source file remains visibly attributed to its
original repository and revision.
