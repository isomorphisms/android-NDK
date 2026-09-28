# MIRO A1 CPU and Android ARMv7 ABI research

Copied from `walnut-burgundy/computer-science`, `fuego-ironworks/zram`, and the physical Android receipts.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/5  
Original cross-index: https://github.com/walnut-burgundy/computer-science/issues/72

## Proven execution target

The physical MIRO A1 has established:

```text
primary ABI       armeabi-v7a
ABI list          armeabi-v7a,armeabi
64-bit ABI list   empty
kernel machine    armv7l
Android           14 / API 34
page size         4096
C library         Bionic
```

This proves a 32-bit Android userspace target. It does not prove that the silicon itself is an ARMv7-era core.

## Android ARM ABI boundary

For native application binaries the established target is:

- AArch32;
- ARMv7-A compatibility baseline associated with `armeabi-v7a`;
- A32 and Thumb-2/T32 code forms;
- 32-bit pointers;
- VFP/NEON available as instruction-set facilities where the target permits them.

The CPU-instruction research keeps A32/T32 distinct from A64/AArch64.

## Floating-point call ABI

The Android `armeabi-v7a` public call boundary is **softfp**:

- floating-point arguments/results cross public call boundaries in core registers/stack according to the ABI;
- VFP/NEON instructions may still perform the arithmetic in hardware;
- this is different from a hard-float ABI even when the code uses VFP.

That distinction matters for hand-written ARM/Thumb, FFI, JNI/native stubs, and compiler backends.

## Silicon versus userspace

Model/platform material associates the SC9863A family with Cortex-A55. Cortex-A55 is an Armv8-class core capable of AArch32 execution. The safe distinction is:

```text
physical CPU family/material: Cortex-A55 / SC9863-family reference
verified Android execution:   armv7l + armeabi-v7a
```

Do not infer “the CPU is Armv7” from `uname -m = armv7l`.

The zram device dossier intentionally keeps exact physical CPU implementer/part/revision and exact physical architecture revision unresolved until a retained CPU-ID receipt proves them.

## Canonical research

- https://github.com/walnut-burgundy/computer-science/pull/5
- `walnut-burgundy/computer-science/Armv7-A A32-T32 - Android/`
- `walnut-burgundy/computer-science/Arm A64 - Cortex-A55/`
- `fuego-ironworks/zram/devices/miro-a1/README.md`
