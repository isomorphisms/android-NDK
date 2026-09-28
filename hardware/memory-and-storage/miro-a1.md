# MIRO A1 memory, zram and storage research

Copied from `fuego-ironworks/zram`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/3  
Original cross-index: https://github.com/fuego-ironworks/zram/issues/3

## Physical facts retained by the original dossier

```text
product/model      MIRO A1 / A1
Android            14 / API 34
primary ABI        armeabi-v7a
ABI list           armeabi-v7a,armeabi
kernel machine     armv7l
kernel             5.15.149-android13-8-g8407b75767d0-dirty
page size          4096 bytes
C library          Bionic
```

The canonical observed-facts ledger deliberately leaves these unproven until a retained physical receipt establishes them:

```text
exact physical RAM bytes
RAM package vendor/model
internal-storage transport/vendor/product/revision
NAND type/geometry
zram size
zram primary/supported compressors
zram writeback support
zram backing device
```

Do not fill those fields from a retail listing.

## Model/platform documentation

Model-level material advertises 2 GB RAM and 32 GB internal storage.

The UNISOC SC9863A platform reference documents:

- LPDDR3 or LPDDR4/LPDDR4X support;
- eMMC 5.1 storage interface.

Those are model/platform expectations, not physical-package receipts.

## Storage evidence boundary

The board receipt independently observes eMMC-style block/boot partitioning on the MIRO. The zram dossier still keeps exact package/vendor/geometry unresolved.

The hardware collection path distinguishes:

- `mmcblk*` plus MMC sysfs identity -> eMMC/SD-style block devices;
- SCSI `sd*` plus UFS host/sysfs evidence -> UFS.

Unique serials/CIDs are intentionally omitted from retained public evidence.

## Memory-tier design research

The zram work separates:

```text
RAM
  -> zram
  -> optional bounded internal-/data writeback
```

Removable SD storage is not treated as the proposed zram backing tier.

The research also separates:

- fast compression for the first zram tier;
- idle recompression where useful;
- bounded writeback;
- flash-wear concerns;
- Android LMKD/process-lifecycle behavior;
- newer Android mmd work from what this Android 14 phone actually implements.

## Canonical sources

- https://github.com/fuego-ironworks/zram/pull/1
- `fuego-ironworks/zram/devices/miro-a1/README.md`
- `fuego-ironworks/zram/devices/miro-a1/observed-device-facts.tsv`
- `fuego-ironworks/zram/notes/staged-compression-policy.md`
