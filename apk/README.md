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

`build-nativeactivity-apk.sh` is the maintained generic path for a framework
`android.app.NativeActivity` package whose application code is already an
NDK-built shared library. It invokes Android build-tools directly: `aapt2`,
`zipalign`, and `apksigner`. It does not invoke Gradle, Java, Kotlin, or
`d8`, and by default rejects a finished APK containing DEX.

The consumer supplies its own manifest, package/version identity, SDK bounds,
ABI, signing key metadata, and expected certificate digest. The script never
creates a key and never chooses a fallback signer. It verifies the keystore
certificate before packaging and the finished APK signer, package ID,
`versionCode`, NativeActivity launcher, ABI payload, and APK digest afterward.

Run `apk/tests/run-packager.sh` with the Android SDK/NDK and an explicit test
keystore to exercise the positive path plus missing/wrong-signer hostile cases.

For byte-reproducible packages, supply `SOURCE_DATE_EPOCH` from the consumer's
source commit. The maintained packager normalizes payload times to UTC and
sorts asset entries. This opt-in mode requires a minimum SDK of 24 or newer
and uses APK signature v2 or newer, disabling timestamp-bearing v1 signing.
The consumer still supplies the signer; no new signing or build authority is
introduced. Ordinary calls retain their existing signing defaults.

`apk/tests/reproducible.grease MANIFEST NATIVE ABI OUTPUT` exercises identical
APK bytes across two time zones and rejects invalid epochs and incompatible
API floors. It requires the same explicit SDK and test-signer environment as
the maintained packager. This is a hosted packaging check, not device acceptance.
