# MIRO C67 / MediaTek Helio G36 CPU target research

The original model/platform note came from
[isomorphisms/android-NDK PR #13, “Document MIRO C67 hardware and unresolved Android ABI”](https://github.com/isomorphisms/android-NDK/pull/13).
Its October 2 ABI uncertainty is superseded by Cat Food's October 5 physical
observation, retained on main at `602a2862d248dcfd9629c48c442574f1959513aa`.
Cat Food owns supported-system build/deployment facts; this dossier records
their consequences for native compilation.

## Model/platform facts retained

Retail material identifies a MediaTek Helio G36 at up to 2.2 GHz.
MediaTek's specification lists eight Cortex-A53 cores, 64-bit CPU capability,
a maximum 2.2 GHz CPU clock, and a 12 nm process.

- https://www.mediatek.com/products/smartphones/mediatek-helio-g36
- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005

These are model/platform sources. The physical property `MT6765` does not
by itself prove the exact retail SoC bin or fabrication process.

## Recorded physical facts and compiler consequences

Use the maintained [Cat Food profile](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/android/devices/miro-c67.md) and
[October 5 observation ledger](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/docs/observations/miro-c67-hardware-2026-10-05.tsv) for the concrete device values.
The ledger records MT6765, eight Cortex-A53 cores (CPU part `0xd03`), primary
ABI `arm64-v8a`, both 64-bit and 32-bit ABI lists, and an `aarch64` kernel.
Full CPU implementer/revision values are not retained in that ledger.

A C67-specific payload can therefore select the existing `arm64-v8a` lane.
Do not invent a C67 compiler ABI or use Cat Food's shared `tablet` package
column as evidence that the C67 is TAB_P10. Keep the application's minimum SDK;
physical API 34 does not require `minSdk=34`.

The declared `armeabi-v7a` compatibility lane is not an exact ARM32 artifact
execution receipt. The [runtime dossier](../runtime-abi/miro-c67-unverified.md)
keeps that execution boundary and page-size uncertainty explicit.
The A1 CPU/ABI cross-index pair is
[Android NDK issue #5](https://github.com/isomorphisms/android-NDK/issues/5) /
[ComputerScience issue #72](https://github.com/walnut-burgundy/computer-science/issues/72).

## Optimization boundary

Cortex-A53 tuning, scheduling and instruction selection remain independent
from ABI selection and require exact compiler support and consumer semantics.
Prefer more parallel narrow values when semantics and hardware permit; that
preference does not prove usable SIMD, a speedup, or safe precision loss.
Retain the original measurement questions conditionally: actual 32-bit native
execution, CPU implementer/revision, runtime page size, and whether a selected
tuning mode improves a consumer without changing its result. No broad benchmark
or new port is required by this cross-index.

The existing MIRO A1 ARMv7 receipt applies only to its recorded phone and bytes.
