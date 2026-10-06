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


## Maintained direct NativeActivity packager

`build-nativeactivity-apk.ysh` is the maintained Grease route for framework
NativeActivity. It invokes aapt2, zipalign and apksigner directly. SDK signing
tools use an explicit JRE; no application Java/Kotlin, Gradle or d8 is generated.

The candidate pins NDK r27c inspection, SDK build-tools 35.0.0, platform 34 and
minimum API 21. The central AICI registry determines the signer. Caller
fingerprints, tool overrides and disabling no-DEX fail. Keys are never created
or selected as a fallback. Application-owned metadata, resources and assets
remain explicit inputs.

Inspection checks the signed APK's package/version, single framework activity,
hasCode=false, exported=true, library metadata, exact native payload, actual
ELF class/machine/byte order/DYN/export, alignment and registered signer.
Private staging precedes publication; existing attempt outputs are never replaced.
The .sh entrypoint is only a compatibility exec to Grease.

Tests compile actual NDK libraries and create real APKs, covering resources,
wrong ELF/metadata/key, DEX injection, caller overrides, interruption and rerun.
Set pinned SDK/NDK roots, signing-tools JRE, AICI_ROOT and the registered test
keystore; run the maintained Grease tests.

The v2 receipt is **package-inspection** evidence with
producer_execution=NOT_VERIFIED. A qualified independent AICI supervisor must
own execution and authenticate its decision. Packaging cannot establish
delivery, replacement, pinch-zoom, wireframe or physical acceptance.
See [FP3 qualification](qualification/fp3.tsv).
