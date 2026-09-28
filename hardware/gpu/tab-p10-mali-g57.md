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
