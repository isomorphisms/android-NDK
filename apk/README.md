# APK construction and distribution boundary

An Android application package combines application-owned metadata with native
artifacts.  This repository records the generic packaging shape; it does not
make every application share one manifest, signer, resource set, SDK policy, or
ABI matrix.

## Checked direct-DEX Activity candidate

IB's native reader needs an `android.app.Activity` subclass and native framework
Views rather than the NativeActivity/JNI shape. Its manifest declares the actual
`Idric.Generated` class emitted from checked Idriç. The reviewed source shape is
bounded to the backend's Activity superclass, original-Bundle superclass
onCreate call, checked handler and existing interface callbacks.

`build-direct-dex-activity.grease` accepts absolute SDK, manifest, resource,
checked DEX and explicit public-test keystore paths, an application-owned package
ID, the expected certificate digest and fresh output. It links SDK34 resources,
adds exactly those candidate DEX bytes, aligns and test-signs the package, checks
its certificate/manifest/launcher and compares the extracted DEX before exposing
the candidate. It refuses missing or mismatched signers and reused output. The
public Wegert fixture is its explicitly bounded test lane; no production/private
key support or signing authority is inferred.

This producer is not independent `build-toolchain-v0` promotion. The caller must
retain checked-source/driver origin and the shared AICI acceptance receipt;
arbitrary historical hand-encoded DEX is not an accepted application input.
Installation, behavior, update identity and physical execution are separate.
The existing NativeActivity packager remains the owner for that different shape.

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
source commit and repeat that approved value as
`ANDROID_EXPECTED_SOURCE_DATE_EPOCH`. A mismatch fails before packaging.
`ANDROID_SOURCE_COMMIT` must name the exact 40- or 64-hex source revision. The
maintained packager stages resources and assets in bytewise relative-path
order, normalizes their timestamps to the epoch, normalizes files to mode 0644
and directories to 0755, and omits ZIP user/group extra fields. The native
library receives the same epoch and file mode. This opt-in mode requires a
minimum SDK of 24 or newer and explicitly uses APK signature v2 only,
disabling v1, v3 and v4. The consumer still supplies the signer; no new signing
or build authority is introduced. Ordinary calls retain their existing signing
defaults.

Every successful package emits an `android-ndk-nativeactivity-apk-v2` receipt.
Its material identity binds the schema, package and SDK policy, source
revision and epoch, normalization rules, manifest, resource/asset/native
closures, signer certificate, and exact packager, `aapt2`, `zipalign`,
receipt verifier, `apksigner` wrapper and implementation, `android.jar`, and
`zip` bytes. Separate fields record the
unsigned payload, aligned package, and signed APK digests. Paths, attempt IDs,
timestamps outside the approved epoch, and other attempt metadata do not enter
the canonical receipt. The ordered schema is
[`nativeactivity-receipt-v2.schema.tsv`](nativeactivity-receipt-v2.schema.tsv).

Run `verify-nativeactivity-receipt.sh RECEIPT APK` before consuming a pair. It
rejects changed field order, schema or material rows and a receipt whose final
APK digest does not match the supplied APK. APK and receipt publication remain
two filesystem renames, so this verification is required after interruption
or transport as well as after a normal build.

`apk/tests/reproducible.grease MANIFEST NATIVE ABI OUTPUT` exercises distinct
workspace roots, time zones, creation orders, input modes and timestamps. It
also checks resource/native material changes, old-packager and ZIP-metadata
mutants, wrong and invalid epochs, wrong signer, incompatible API floor,
mismatched receipt/APK pairs, and canonical receipt equality across different
attempt IDs. It requires the same explicit SDK and test-signer environment as
the maintained packager. This is a hosted packaging check, not device
acceptance, compiler reproducibility, signer update compatibility, or physical
application behavior.

## Resource and launcher identity continuity

An application may set ANDROID_RES_DIR to an application-owned Android res/
tree; the packager compiles it with aapt2 before linking the manifest. This
preserves launcher icons and string resources without introducing Gradle.

When ANDROID_EXPECTED_LABEL is supplied, the packager extracts
application-label from the finished signed APK and fails if it differs. The
expected label must be supplied from an independently approved application
identity contract, not from a new build's self-description. The observed label
is included in the packager receipt. Other mandatory package ID, signer and
NativeActivity checks remain in force. To prevent delivery of a bad candidate,
the APK is first signed and checked in temporary storage; only then does it
replace the designated output. The caller must still run the independent AICI
producer and version/update gate before publication. The optional identity
input here is defense in depth, not shared policy authorization.

### Declared direct DEX callbacks

`ANDROID_DEX_FILE` is an optional, explicit classes.dex input. It requires
`ANDROID_REQUIRE_NO_DEX=0`; the default policy remains DEX-free. The finished
signed APK must contain exactly those declared bytes, recorded in the receipt.

For an application requiring NativeActivity callback overrides, set
`ANDROID_ACTIVITY_CLASS` to the exact generated class name and supply
`ANDROID_BAKSMALI_JAR`. The packager pins baksmali3.0.10 by SHA256, independently
decodes the finished APK's DEX, and requires that the declared launcher directly
extends framework NativeActivity. A caller cannot turn this into an arbitrary
Java Activity by changing the manifest or an unchecked receipt.

The checked `examples/autogenerated/native-view-callback/ClickListener.idric`
plan supplies ordinary View clicks, document-picker results and new intents.
Its methods are native platform boundaries; no application/music state resides
in the adapter.
# Receipt continuity for pre-ICU consolidation

DEX-free packages retain the ordered v2 receipt schema. Explicit DEX packages
use `nativeactivity-receipt-v3.schema.tsv`; its material identity additionally
includes the exact launcher, extracted `classes.dex` digest and pinned subclass
oracle digest (the empty-input digest means no subclass oracle was needed).
The verifier selects the declared schema and independently checks the APK and
its extracted DEX. Both schema files remain available.

In reproducible mode, DEX receives the same timestamp, file-mode and stripped
ZIP metadata normalization as the native payload. The optional
`ANDROID_TEST_DEX_FILE` qualification input must be an actual emitted callback
fixture; the dependent checked-effects packaging job supplies it from the same
run and source revision. Its changed-byte control tests material identity only.
These checks establish packaging and inheritance, not fresh JNI execution.
