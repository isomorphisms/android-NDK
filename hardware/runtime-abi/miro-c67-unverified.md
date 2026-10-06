# MIRO C67 Android runtime / ABI evidence

The filename is retained for existing links. The October 2 statement that no
physical ABI observation existed is superseded by Cat Food's October 5 profile,
landed at `602a2862d248dcfd9629c48c442574f1959513aa`.
[Cat Food's profile](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/android/devices/miro-c67.md) owns concrete runtime/deployment facts;
the [observation ledger](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/docs/observations/miro-c67-hardware-2026-10-05.tsv) retains their commands and evidence class.

## Evidence boundary

| Claim | Evidence | What remains separate |
| --- | --- | --- |
| Android 14 / SDK 34, primary `arm64-v8a`, declared ARM32 and ARM64 ABI lists, Linux 4.19.191 `aarch64` | October 5 physical properties in Cat Food | Exact native payload execution in each lane |
| Eight-core Cortex-A53 / MT6765 | Retained CPU/property observation | Exact CPU revision, compiler support, SIMD behavior or speed |
| Runtime page size | UNKNOWN in the October 5 ledger | A retained observation from the selected C67 |
| Bionic/native-boundary suite | NOT_RUN on C67 in the records inspected for this batch | C67 execution of exact Android/Bionic payloads |
| Application compatibility | ABI selection only | Package, signer, install, launch, replacement and behavior per APK |

The exact C67 fingerprint is maintained in Cat Food. It identifies the captured
firmware, not a unique physical unit. Do not transfer storage, privilege, driver
or runtime state from MIRO A1, TAB_P10 or another C67.

## Existing procedure and smallest missing observation

[isomorphisms/catfood PR #115, “Reconcile current Android delivery and retire old generations”](https://github.com/isomorphisms/catfood/pull/115)
at reviewed source `fe7d665cb98ce28f2267859e081ac2eeeb7a9d7b` implements
[the C67 recorder](https://github.com/isomorphisms/catfood/blob/fe7d665cb98ce28f2267859e081ac2eeeb7a9d7b/android/record-c67-runtime.sh).
Implementation presence is not a physical receipt. It reads page size through
`getconf PAGESIZE` (or `/proc/self/smaps`) and invokes the delivered Linux
AArch64 jq. Its runtime-binary pin is jq 1.8.2, SHA-256
`8b85c817833814ddca00a144c33705546355afccf0cf39b188f3cdb48b852309`.
That probe does not establish Bionic, the ARM32 lane, compiler-generated SIMD,
or APK behavior.

Reuse an existing `c67-runtime.tsv` together with its referenced jq
runtime-binary receipt if they exist, checking C67 identity and exact bytes
read-only. If absent, the smallest page-size observation is the recorder's
existing read-only `getconf PAGESIZE` path plus the current model, product,
fingerprint, SDK and ABI lists. Do not run provisioning just to collect a
page size. A native-execution claim additionally needs the exact already
delivered artifact and its source/package/digest identity; do not install
build tools or compile on the phone.

## Retained historical questions

The original six receipt requirements remain useful: firmware/SDK, full ABI
lists, kernel, page size, native execution for each claimed lane, and exact
package/compiler identity. The first three now have a physical observation;
the last three still require claim-specific evidence. Generic build/publication
is not itself physical-device acceptance.

The earlier model-only sources remain:
https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005 and
https://www.mediatek.com/products/smartphones/mediatek-helio-g36.
Retail silicon capability alone did not settle ABI selection; the later
physical properties did.

Related: [A1 native receipt dossier](miro-a1-bionic.md) and its
[Android NDK issue #9](https://github.com/isomorphisms/android-NDK/issues/9) /
[AICI issue #166](https://github.com/isomorphisms/ai-ci/issues/166) pair.
