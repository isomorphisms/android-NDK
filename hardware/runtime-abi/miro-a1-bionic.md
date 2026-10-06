# MIRO A1 physical Bionic/native-boundary receipt

Copied from `isomorphisms/ai-ci`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/9  
Original cross-index: https://github.com/isomorphisms/ai-ci/issues/166

## Exact physical run

The merged native-boundary ARMv7 bundle from:

```text
9df49d14f91a6596bd35f1183b85d4b1b0848a68
```

executed on the physical ARMv7 Android phone.

Observed summary:

```text
schema          aici-native-execution-v1
suite_revision  9df49d14f91a6596bd35f1183b85d4b1b0848a68
target          armv7a
execution_class android-runtime-unclassified
utc             2026-09-17T08:41:14Z
uname           Linux localhost 5.15.149-android13-8-g8407b75767d0-dirty #1 SMP PREEMPT Tue Aug 27 08:10:29 UTC 2024 armv7l Android
result          PASS
```

Both ordinary and `_FILE_OFFSET_BITS=64` probes reported:

- Bionic;
- runtime page size 4096;
- the exact source revision;
- `summary PASS failures=0`.

## Artifact identity

GitHub Actions artifact:

```text
artifact id/name  10415594437 / native-boundary-armv7a-35018084586
sha256            b27c2d2d0a195f09ba1b4c8bbf15017d96049ac41513fcb46056bd9fdf2ddc39
```

Contained runtime archive:

```text
native-boundary-armv7a.tar.gz
sha256 630a8fd44e39d04d7eac71f810deade60502a2770c692452309cbc7a0d20d604
```

## Attestation boundary

The bundle's own field remained:

```text
physical_device NOT_ATTESTED
```

by design. A binary bundle is not allowed to self-promote to physical-device evidence. Device identity came from independent operator evidence retained by ai-ci.

## NDK consequences

For the proven MIRO Android runtime, native work may rely on the observed facts:

```text
ABI          armeabi-v7a
libc         Bionic
page size    4096
kernel arch  armv7l
```

Large-file/default-offset behavior must still be tested according to the API and compile configuration rather than inferred from one typedef.

## Canonical source

- https://github.com/isomorphisms/ai-ci/issues/107
- [isomorphisms/ai-ci PR #111, “Accept exact ARMv7 physical-phone receipt”](https://github.com/isomorphisms/ai-ci/pull/111), merged; exact [follower receipt](https://github.com/isomorphisms/ai-ci/blob/0fd43ef714623c129bccc3b2825ca0a3d97f4c72/followers/receipts/native-boundary-armv7-phone-9df49d14.tsv).

## Exact widths and reuse boundary

The [complete operator receipt](https://github.com/isomorphisms/ai-ci/issues/107#issuecomment-5715968733) records execution at
`2026-09-17T08:41:14Z`, firmware
`MIRO/A1/A1:14/UP1A.231005.007/1736153679:user/release-keys`,
compile API 24 and NDK `27.3.13750724`.

| Type / property | Default probe | `_FILE_OFFSET_BITS=64` probe |
| --- | --- | --- |
| Pointer / long | 4 / 4 bytes | 4 / 4 bytes |
| `off_t` / `off64_t` | 4 / 8 bytes | 8 / 8 bytes |
| `time_t` | 4 bytes | 4 bytes |
| Runtime page size | 4096 bytes | 4096 bytes |
| Suite summary | PASS, failures=0 | PASS, failures=0 |

The bundle's unclassified / NOT_ATTESTED fields were preserved; the later
accepted record uses independent operator evidence. Do not rerun these probes
merely to repair cross-links. Firmware fingerprint is not a unique unit ID;
the later September 26 second-A1 ADB-host observation in issue #107 does not
prove it is this September 17 unit.

Use [Cat Food's C67 profile](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/android/devices/miro-c67.md) for that phone's observed ABI.
Its [native/page-size boundary](miro-c67-unverified.md) remains separate:
C67's ARM32 property list does not inherit these Bionic results or 4096-byte
pages. LP32 widths do not establish SIMD behavior, packed-number semantics,
compiler support or any performance improvement.
