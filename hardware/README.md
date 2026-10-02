# Hardware research

This tree collates hardware work that was originally saved in other repositories.

The generic Android-native route is described in
[`../ARCHITECTURE.md`](../ARCHITECTURE.md).  This hardware tree does not become
the owner of every hardware implementation; it preserves references and
constraints needed by generic Android-native work.

## Rule

The original repository remains canonical. Files here are working copies for Android NDK development. Every dossier records its provenance and its paired Android-NDK cross-index issue when one exists.

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
| memory/storage | [MIRO C67 model memory/storage](memory-and-storage/miro-c67.md) | — |
| sensors/input | [MIRO A1 accelerometer](sensors-and-inputs/miro-a1-accelerometer.md) | #4 |
| sensors/input | [MIRO A1 touchscreen](sensors-and-inputs/miro-a1-touchscreen.md) | #2 |
| runtime/ABI | [MIRO A1 Bionic/native boundary](runtime-abi/miro-a1-bionic.md) | #9 |
| runtime/ABI | [MIRO C67 unverified runtime/ABI](runtime-abi/miro-c67-unverified.md) | — |
| runtime/ABI | [TAB_P10 Android/AArch64 receipt](runtime-abi/tab-p10-aarch64.md) | #8 |
| physical outputs | [current state](physical-outputs/README.md) | — |

Board-level GPIO/pinmux research belongs under board/kernel unless a pin has a proven device function. Sensor/input pins belong with the corresponding input device. Speaker, vibrator, flashlight/light, GPIO-output and similar actuator research belongs under physical outputs once evidence exists.

See [AGENTS.md](AGENTS.md) for the filing/evidence rules future hardware work should follow.
