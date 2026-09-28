# APK construction and distribution boundary

An Android application package combines application-owned metadata with native
artifacts.  This repository records the generic packaging shape; it does not
make every application share one manifest, signer, resource set, SDK policy, or
ABI matrix.

## Generic package contents

```text
AndroidManifest.xml                  application-owned component declaration
resources                            application-owned presentation resources
lib/<abi>/lib<application>.so        NDK-built native library for each chosen ABI
classes.dex                          optional direct-DEX Android class layer
assets                               application-owned static payload
```

`classes.dex` is optional.  A framework `NativeActivity` package can declare
`android:hasCode="false"` and load its native library directly.  A direct-DEX
package includes an Android-facing class only when the application needs one.

## Recovered tooling and evidence

- [`dex/idric/tests/dex/native-activity/build-apk-from-native-base.sh`](../dex/idric/tests/dex/native-activity/build-apk-from-native-base.sh)
  preserves the direct-DEX overlay harness: begin with a previously built
  native APK payload, replace its class layer with a direct candidate, align,
  sign, and inspect the result.  It is a historical integration harness, not a
  universal application packager.
- Pauli's native-only packaging path records single-ABI APKs and an
  application-owned fail-closed signer.
- Wegert's direct-DEX/JNI path records a three-ABI native library set, direct
  `classes.dex`, APK checks, and ART/JNI acceptance.
- ICK's Android release gate records ABI, linker, ELF, and load-alignment
  qualification, not a generic store-release claim.

The authoritative source locations and exact revisions are in the
[migration inventory](../provenance/migration-inventory.md).

## Distribution

An ABI-specific APK can suit direct download when the target ABI is known.  An
app-store lane may use an AAB or another store-required format, but the
consumer repository must keep its release identity, signing, store metadata,
and acceptance evidence explicit.  A passing host package check, emulator
launch, installed APK, and physical-device behavior are separate evidence
levels.
