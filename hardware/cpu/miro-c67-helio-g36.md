# MIRO C67 / MediaTek Helio G36 CPU target research

This dossier records **model/platform** evidence only. No physical MIRO C67 CPU/ABI receipt has been retained yet.

## Model/platform facts

Retail material for the MIRO C67 identifies a MediaTek Helio G36 at up to 2.2 GHz.

MediaTek's Helio G36 specification identifies:

```text
CPU cores        8
CPU type         Arm Cortex-A53
CPU bit width    64-bit
max CPU clock    2.2 GHz
process          12 nm
```

Sources:

- https://www.mediatek.com/products/smartphones/mediatek-helio-g36
- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005

## Compiler/ABI consequence

The silicon being 64-bit does **not** establish the Android userspace ABI on the physical phone.

Keep these separate until a physical receipt is retained:

```text
silicon / tuning family   Cortex-A53 / 64-bit-capable
Android primary ABI       UNKNOWN
32-bit ABI list           UNKNOWN
64-bit ABI list           UNKNOWN
kernel machine            UNKNOWN
page size                 UNKNOWN
```

Do not choose `arm64-v8a` merely from the SoC specification, and do not choose
`armeabi-v7a` merely because existing MIRO A1 packages use it.

Once the physical ABI is known, the product should map onto the existing Android
ABI lane rather than creating a C67-specific compiler ABI. A Cortex-A53 tuning
mode may then be evaluated independently from the ABI baseline.

## Optimization questions for a physical receipt

Retain enough evidence to answer:

- whether Android exposes `arm64-v8a`, `armeabi-v7a`, or both;
- whether 32-bit execution is actually enabled when the primary ABI is 64-bit;
- exact CPU implementer/part/revision from `/proc/cpuinfo` or an equivalent retained receipt;
- runtime page size;
- whether target-specific scheduling or instruction selection beats the generic ABI baseline without changing semantics.

The existing MIRO A1 ARMv7 receipt is evidence for that phone only.
