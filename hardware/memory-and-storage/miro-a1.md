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

## Dated memory observation, reconciled October 6, 2026

The [September 26 operator receipt](https://github.com/fuego-ironworks/zram/pull/1#issuecomment-5849140850) reports
an externally inspected new/backup A1 target, with a second matched A1 acting
as the ADB host:

| Field | Observed value |
| --- | --- |
| MemTotal | 1937676 kB |
| SwapTotal | 1453252 kB |
| Android / ABI | 14 / API 34; armeabi-v7a,armeabi |
| Kernel | 5.15.149-android13-8-g8407b75767d0-dirty |
| /data filesystem size | Approximately 25 GB; around 14 GB used / 11 GB available at capture |

This adds kernel-reported totals without filling `ram_physical_bytes` or
`zram_size_bytes` in the original ledger. MemTotal is not exact installed
chip capacity; SwapTotal is not a direct zram disksize or compressor observation.
The receipt's description of a zram-swap tier is an operator interpretation;
its listed counters alone do not identify backing or compression.
Those original UNKNOWN fields remain valid.

The receipt omits a unique target-unit label and fingerprint. Do not identify
its backup A1 with the September 17 Bionic target or an October IB session
solely from model/kernel. The companion A1 ADB host is a separate device.
Historical free space is not current capacity.

[Cat Food](https://github.com/isomorphisms/catfood) retains supported-system
configuration/history; the original zram repository retains this specialized
receipt and policy. [IB #95](https://github.com/isomorphisms/ib/issues/95) consumes
those owners and [its maintained live report](https://github.com/isomorphisms/ib/blob/843c7bcf5336c685c4a96a4b4bc28b96fbc7a5dc/docs/android-device-capabilities.md) rather than deriving
current memory or app-write permission from this dossier. The October 4 Cat Food
ordinary-file IB baseline has no memory measurement and does not accept zram
or current storage capacity.

[C67's memory dossier](miro-c67.md) has distinct October 5 totals and an
MMC/ext4 observation. Do not transfer either phone's storage, privileges,
compressors or runtime claims to TAB_P10.

The original [collector](https://github.com/fuego-ironworks/zram/blob/b5cfe463403149a06ea9b247eabf1b6e34e17c8d/devices/miro-a1/collect-hardware.sh) only reads hardware/kernel nodes apart
from its bounded output receipt, but silently skips many unreadable nodes.
Blank output is not proof of zero capacity, no swap or unsupported writeback.
This batch executes no device observation or memory-pressure workload.
