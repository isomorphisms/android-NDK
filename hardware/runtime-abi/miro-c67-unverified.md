# MIRO C67 Android runtime / ABI status

The MIRO C67 is a named Android target, but no retained physical ABI receipt is
present yet.

## Model-level evidence

Retail material lists the phone with Android 14 and a MediaTek Helio G36.
MediaTek identifies the G36 as a 64-bit, eight-core Cortex-A53 platform.

Sources:

- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005
- https://www.mediatek.com/products/smartphones/mediatek-helio-g36

## Not yet physically established

```text
ro.product.cpu.abi       UNKNOWN
ro.product.cpu.abilist   UNKNOWN
32-bit ABI list          UNKNOWN
64-bit ABI list          UNKNOWN
kernel machine           UNKNOWN
kernel version           UNKNOWN
runtime page size        UNKNOWN
Bionic/native receipt    NOT_VERIFIED
```

The SoC's 64-bit capability is not enough to assign the device to Cat Food's
AArch64 tablet lane or its current 32-bit ARMv7 phone lane.

## Required physical receipt

Before optimizing or publishing device-specific native packages, retain:

1. Android build fingerprint and SDK;
2. primary ABI and full ABI lists;
3. kernel machine/version;
4. runtime page size;
5. successful execution of a tiny native artifact for each ABI being claimed;
6. the exact package/compiler revision used for that execution.

Once that exists, cross-link it here and update the compiler/backend consumers.
