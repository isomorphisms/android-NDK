# MIRO C67 memory and storage target research

This dossier records **model/platform** evidence only. Exact physical packages,
storage transport, memory pressure behavior, and zram configuration remain
unverified.

## Product-level facts

Retail material lists:

```text
Android          14
physical RAM     4 GB
marketing RAM    8 GB = 4 GB physical + 4 GB expansion
internal storage 64 GB
display          1600 x 720, 90 Hz
battery          4900 mAh
```

Source:

- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005

## SoC memory/storage capabilities

MediaTek lists the Helio G36 platform as supporting:

```text
memory           LPDDR3 @ 933 MHz or LPDDR4X @ 1600 MHz
maximum memory   8 GB
storage          eMMC 5.1
```

Source:

- https://www.mediatek.com/products/smartphones/mediatek-helio-g36

Those are platform capabilities, not proof of which DRAM or eMMC parts the C67
actually contains.

## Physical facts still required

Retain a physical receipt for:

- exact `MemTotal`;
- zram size, compressor and supported compressors;
- swap/zram activity under the intended workload;
- internal-storage block transport and filesystem;
- relevant read/write/latency measurements;
- LMKD / memory-pressure behavior if it materially affects the workload.

Do not use the advertised "4 + 4 GB" expansion figure as physical RAM.
