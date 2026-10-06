# MIRO C67 memory and storage evidence

Cat Food owns supported-device and deployment facts. The
[October 5, 2026 observation ledger](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/docs/observations/miro-c67-hardware-2026-10-05.tsv),
landed at `602a2862d248dcfd9629c48c442574f1959513aa`, supersedes this dossier's
earlier model-only status for the following fields.

## Recorded physical observations

| Field | Retained value | Interpretation boundary |
| --- | --- | --- |
| MemTotal | 3865468 kB | Kernel-reported usable RAM total; not a RAM package size or current available memory |
| SwapTotal | 2126000 kB | Aggregate reported swap capacity; not extra physical RAM, zram disksize or a compression ratio |
| /data size | 47G | Rounded df observation; not exact capacity or current bytes available to an app |
| /data filesystem / option | ext4 / inlinecrypt | Captured mount state; not raw-flash geometry or permission for another writer |
| Block device | mmcblk0 | Observed MMC block path |
| Transport class | eMMC-style MMC block device | Cat Food labels this an inference; exact package, vendor and revision remain unresolved |

Cat Food records firmware
`MIRO/C67/Miro_C67:14/UP1A.231005.007/1727680044:user/release-keys`.
Its ledger is a dated field summary, not a unique unit ID, raw workload trace
or present-state receipt. Do not transfer these values to another C67, A1 or TAB_P10.

Exact RAM package/vendor, flash package/geometry, zram disksize, selected and
available compressors, backing device, writeback support/counters and
workload pressure remain UNKNOWN in this source set. The ledger explicitly
says exact swap backing/compressor was unreadable from shell. That denial
does not establish absent zram or an unsupported kernel feature.

## Consequence for active consumers

[IB #95, “Inventory device, disk, SD-card and RAM capabilities before Longview writes”](https://github.com/isomorphisms/ib/issues/95)
must consult Cat Food history, then observe current capacity and actual writer
authority. Its [existing read-only report](https://github.com/isomorphisms/ib/blob/843c7bcf5336c685c4a96a4b4bc28b96fbc7a5dc/docs/android-device-capabilities.md) has memory totals/available,
swap rows, storage state and an app-UID view. Reuse it; historical total capacity
cannot authorize a current large allocation or write.

The zram [staged policy](https://github.com/fuego-ironworks/zram/blob/b5cfe463403149a06ea9b247eabf1b6e34e17c8d/notes/staged-compression-policy.md)
is a proposal for fast compression, idle recompression and bounded internal
writeback. Neither Android 14, a swap total nor ext4 proves Android 17 mmd,
multiple compressors, writeback availability or successful process retention.
Removable SD is not the proposed backing tier.

Preserve narrow-value parallelism where semantics and hardware permit.
These capacity observations do not prove SIMD, safe lossy representation,
memory bandwidth, the cause of an application hang or a performance gain.

## Smallest observations when needed

For a current IB budget, retain its existing report's observation time,
installation label, product/firmware/ABI and authority, MemAvailable/SwapFree
and app-visible available bytes. No write test, provisioning, root or compiler
is needed for that read-only stage. App-reported access remains distinct from
IB #96's deliberately bounded write acceptance.

If selecting a zram codec or writeback policy becomes an active requirement,
the existing [collector](https://github.com/fuego-ironworks/zram/blob/b5cfe463403149a06ea9b247eabf1b6e34e17c8d/devices/miro-a1/collect-hardware.sh) already names
`/sys/block/zram0/comp_algorithm`, `disksize`, `mm_stat`, `backing_dev`
and `bd_stat`. Read only the needed nodes on the identified device; do not
write compressor/reset/backing settings. Missing output from that collector
can mean a skipped unreadable file: preserve denial/absence/unknown separately.
Do not run its A1-labeled default receipt as a C67 identity attestation.
No broad pressure or throughput benchmark is required by this reconciliation.

## Preserved product/platform research

The earlier retail description lists Android 14, 4 GB physical RAM plus
4 GB marketed expansion, 64 GB storage, 1600 × 720 / 90 Hz display and a
4900 mAh battery. These remain product claims, not this memory receipt.
Expansion is not installed physical RAM; battery/display claims are not settled
by the storage observation.

- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005

MediaTek's Helio G36 platform lists LPDDR3 at 933 MHz or LPDDR4X at 1600 MHz,
up to 8 GB memory and eMMC 5.1. The physical MMC path does not prove that
interface version, DRAM generation/frequency or exact retail SoC bin.

- https://www.mediatek.com/products/smartphones/mediatek-helio-g36

Original workload questions remain conditional: swap activity, read/write
latency and LMKD/process survival need workload-specific evidence if needed.
Paired research indexes: [Android NDK #3](https://github.com/isomorphisms/android-NDK/issues/3)
and [zram #3](https://github.com/fuego-ironworks/zram/issues/3).
