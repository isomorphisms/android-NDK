# TAB_P10 / Mali-G57 physical GPU research

Copied from `fuego-ironworks/idris-shader-backend`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/7  
Original cross-index: https://github.com/fuego-ironworks/idris-shader-backend/issues/65

## Physical renderer receipt

The physical SVITOO TAB_P10 acceptance run reported:

```text
GL_VENDOR    ARM
GL_RENDERER  Mali-G57
EGL          1.5
GLES         3.2
GLSL ES      3.20
```

The same packaged six-probe GLES harness produced:

```text
package payload hash       PASS
shader compile/link        6/6 PASS
framebuffer/readback       6/6 PASS
timing block               complete
```

This is physical tablet evidence, not an emulator or a PowerVR result reused for another GPU.

## Target gate

The acceptance wrapper now treats the two physical targets independently:

```text
phone    -> Imagination / PowerVR required
tablet   -> ARM / Mali-G57 required
```

Regression checks explicitly reject substituting one renderer identity for the other.

## Architecture relation

Separate microarchitecture research identifies the tablet target with an Allwinner A333 / `sun65iw1p1` platform and Mali-G57 MC1 / Valhall structure. That architecture note belongs under `hardware/cpu/tab-p10-allwinner-a333.md`; the present file records the physical GLES driver evidence.

## Canonical sources

- https://github.com/fuego-ironworks/idris-shader-backend/pull/44
- https://github.com/fuego-ironworks/idris-shader-backend/pull/46

## Source and package boundaries, refreshed October 6, 2026

[Shader-backend PR #44, “Accept the physical Mali-G57 tablet renderer”](https://github.com/fuego-ironworks/idris-shader-backend/pull/44),
head `876bd99b922d1f06f16085680194ce6a02dd1511`, summarizes the physical
results above. That summary does not provide an unchanged byte-bound receipt
with capture time and archive digest here; do not invent those missing fields.
[PR #46, “Integrate Android GLES physical acceptance onto main”](https://github.com/fuego-ironworks/idris-shader-backend/pull/46),
head `59e54ffd882e524c7b967eb636f4fa14cef12c3d`, integrates the gate; a
source integration is not a fresh physical run.

Cat Food's staged [package row](https://github.com/isomorphisms/catfood/blob/fe7d665cb98ce28f2267859e081ac2eeeb7a9d7b/android/packages.tsv)
pins an AArch64 runner at `f3ed48fce28bbee0c0eb9d588e061502f4f323ff`,
archive SHA-256 `25ee1a7de1cbfed2ab20670e8e26824904d98efe079f080d7d66e79a5a29bb50`.
Do not assign that digest to the earlier summary without a matching receipt.
The same ABI can serve C67, but the [wrapper's Mali gate](https://github.com/fuego-ironworks/idris-shader-backend/blob/f3ed48fce28bbee0c0eb9d588e061502f4f323ff/tools/accept_powervr_android.sh)
cannot accept [C67 PowerVR](miro-c67-powervr-ge8320.md).

Cat Food's September 16 ordinary tablet provisioning receipt is not a shader
receipt. TAB_P10 storage, firmware, privilege and app-context claims each need
their own evidence; none is inherited from the C67 or A1.
