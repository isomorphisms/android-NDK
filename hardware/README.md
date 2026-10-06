# Hardware research

This tree collates hardware work that was originally saved in other repositories.

The generic Android-native route is described in
[`../ARCHITECTURE.md`](../ARCHITECTURE.md).  This hardware tree does not become
the owner of every hardware implementation; it preserves references and
constraints needed by generic Android-native work.

## Rule

The original repository remains canonical. Files here are working copies for Android NDK development. Every dossier records its provenance and its paired Android-NDK cross-index issue when one exists.

[Cat Food](https://github.com/isomorphisms/catfood) owns supported-system build/deployment facts and concrete device profiles. Original specialist repositories retain their research and exact acceptance receipts. Consumer requirements stay here; cross-links do not relocate those owners or grant acceptance.

Keep three evidence classes separate:

- **physical** — observed on a real device;
- **model** — documentation for the named product;
- **platform/reference** — SoC, BSP or reference-board material that may apply but does not prove this board's wiring.

Do not promote a reference value to a physical fact without a receipt.

## Current dossiers

| Area | Dossier | Android-NDK issue |
| --- | --- | --- |
| board/kernel | [MIRO A1 / SC9863A](board-and-kernel/miro-a1-sc9863a.md) | #1 |
| CPU | [MIRO A1 CPU + Android ARMv7 ABI](cpu/miro-a1-armv7-abi.md) | #5 |
| CPU | [MIRO C67 / Helio G36](cpu/miro-c67-helio-g36.md) | — |
| CPU | [TAB_P10 / Allwinner A333](cpu/tab-p10-allwinner-a333.md) | #6 |
| GPU | [MIRO A1 / PowerVR GE8322](gpu/miro-a1-powervr-ge8322.md) | #7 |
| GPU | [MIRO C67 / PowerVR GE8320](gpu/miro-c67-powervr-ge8320.md) | — |
| GPU | [TAB_P10 / Mali-G57](gpu/tab-p10-mali-g57.md) | #7 |
| GPU | [PowerVR precision + USC layers](gpu/powervr-precision-and-usc.md) | — |
| memory/storage | [MIRO A1 memory, zram, storage](memory-and-storage/miro-a1.md) | #3 |
| memory/storage | [MIRO C67 observed memory/storage](memory-and-storage/miro-c67.md) | — |
| sensors/input | [MIRO A1 accelerometer](sensors-and-inputs/miro-a1-accelerometer.md) | #4 |
| sensors/input | [MIRO A1 touchscreen](sensors-and-inputs/miro-a1-touchscreen.md) | #2 |
| runtime/ABI | [MIRO A1 Bionic/native boundary](runtime-abi/miro-a1-bionic.md) | #9 |
| runtime/ABI | [MIRO C67 observed ABI / unverified native execution](runtime-abi/miro-c67-unverified.md) | — |
| runtime/ABI | [TAB_P10 Android/AArch64 receipt](runtime-abi/tab-p10-aarch64.md) | #8 |
| physical outputs | [current state](physical-outputs/README.md) | — |

Board-level GPIO/pinmux research belongs under board/kernel unless a pin has a proven device function. Sensor/input pins belong with the corresponding input device. Speaker, vibrator, flashlight/light, GPIO-output and similar actuator research belongs under physical outputs once evidence exists.

See [AGENTS.md](AGENTS.md) for the filing/evidence rules future hardware work should follow.

## First reconciled batch — 2026-10-06

The 18 hardware cross-index issues form nine pairs. This batch reconciles the
CPU/ABI pair (#5 / ComputerScience #72) and native/Bionic pair (#9 / AICI #166).
The [C67 CPU dossier](cpu/miro-c67-helio-g36.md) and
[runtime dossier](runtime-abi/miro-c67-unverified.md) now point to Cat Food's
landed October 5 observation, replacing stale ABI-unknown wording while keeping
native execution and page size unknown. The C67 has no paired issue in this
original set; no new issue is required solely to mirror these links.

The CPU/runtime reconciliation above is preserved. The GPU companion batch below
repairs its previously deferred GPU wording. Sensor, board/kernel
and tablet-native pairs remain separate; memory/storage is reconciled below.

## GPU companion reconciliation — 2026-10-06

The CPU/ABI mapping in [#5](https://github.com/isomorphisms/android-NDK/issues/5) /
[ComputerScience #72](https://github.com/walnut-burgundy/computer-science/issues/72)
was refreshed concurrently on this branch. This companion change preserves that
work and updates the GPU pair [#7](https://github.com/isomorphisms/android-NDK/issues/7) /
[shader-backend #65](https://github.com/fuego-ironworks/idris-shader-backend/issues/65).
No competing branch or duplicate CPU issue update is needed.

| Intention | Reconciled result | Remaining boundary |
| --- | --- | --- |
| Select A1 versus C67 native ABI | A1 ARMv7 and C67 primary arm64-v8a observations are linked by the prior CPU batch | Compiler/artifact-specific execution; advertised C67 ARM32 compatibility is not an execution receipt |
| Reuse GPU evidence | Direct September 16 A1 receipt and scoped TAB_P10 summary | Exact new consumer context, bytes and behavior; A1 receipt omits firmware/unit ID |
| Resolve stale C67 GPU unknowns | Cat Food's landed October 5 SurfaceFlinger GE8320/driver observation | Consumer EGL/GLSL, precision, shader and readback results remain unknown |
| Consume shared AArch64 packages on C67 | ABI lane can be shared | The pinned shader wrapper requires tablet ARM/Mali-G57; it has no C67 PowerVR gate |
| Preserve parallel narrow numeric preference | Prior CPU notes retain it | No inferred SIMD lowering, speedup or safe precision loss |

[Fourier-sound PR #28, “Keep FFT spectrum GPU-resident through Wegert rendering”](https://github.com/isomorphismes/Fourier-sound/pull/28)
at `3c2ecaafd9384b2096dd55b11cca5a74ec0c6c83` requires GLES 3.1
compute/SSBO behavior and currently produces an A1-only GPU APK. Historical
six-fragment acceptance and hosted builds cannot accept that compute path,
the C67, or a different device unit.

Read the [C67 GPU dossier](gpu/miro-c67-powervr-ge8320.md) for exact
Cat Food/shader source and archive identities, the wrapper mismatch, and the
smallest existing prebuilt-runner observation. No device ran in this batch.
Existing shader-wrapper host regression tests passed at shader source
`4a29362e580df393e4d64a9929e4c1e592ac4c53`; that verifies wrapper
target discrimination only.

No issue was closed, PR merged, device procedure executed or shader gate changed.
The memory/storage continuation below now compares that dossier with Cat Food;
other untouched indexes remain separate bounded work.

## Memory/storage continuation — October 6, 2026

This batch updates the paired [Android NDK #3](https://github.com/isomorphisms/android-NDK/issues/3) /
[zram #3](https://github.com/fuego-ironworks/zram/issues/3) and connects
[IB #95](https://github.com/isomorphisms/ib/issues/95) as the active pre-write
capacity consumer. CPU, native and GPU work above is preserved.

- [A1](memory-and-storage/miro-a1.md): direct September 26 operator summary,
  with MemTotal/SwapTotal and dated approximate /data capacity; backup target
  remains distinct from its A1 ADB host and other A1 receipts.
- [C67](memory-and-storage/miro-c67.md): Cat Food's landed October 5 ledger,
  reviewed at `602a2862d248dcfd9629c48c442574f1959513aa`, resolves previously requested
  MemTotal/SwapTotal, /data filesystem and MMC-path observations.
- Kernel totals, RAM packages, compressed-swap implementation, current writer
  capacity and actual workload behavior remain distinct.

Discoverability is satisfied; current IB app/shell capacity reconciliation and
zram codec/writeback/process-retention behavior remain separate acceptance.
The [existing IB report](https://github.com/isomorphisms/ib/blob/843c7bcf5336c685c4a96a4b4bc28b96fbc7a5dc/docs/android-device-capabilities.md) and original zram collector are linked,
not executed or replaced. No issue closure, PR merge, kernel-setting change,
storage write, new registry or benchmark is part of this batch.
