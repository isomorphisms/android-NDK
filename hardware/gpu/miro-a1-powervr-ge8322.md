# MIRO A1 / PowerVR Rogue GE8322 physical GPU research

Copied from `fuego-ironworks/idris-shader-backend`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/7  
Original cross-index: https://github.com/fuego-ironworks/idris-shader-backend/issues/65

## Physical device identity

A packaged ARMv7 GLES acceptance runner executed on the physical MIRO A1 and reported:

```text
device.manufacturer  Foxx
device.model         MIRO A1
device.android       14
device.sdk           34
device.abi           armeabi-v7a
device.abilist       armeabi-v7a,armeabi

EGL                   1.5
GL_VENDOR             Imagination Technologies
GL_RENDERER           PowerVR Rogue GE8322
GL_VERSION            OpenGL ES 3.2 build 1.18@6267915
GLSL                  OpenGL ES GLSL ES 3.20 build 1.18@6267915
```

This is physical-driver evidence, not a model-listing inference.

## Exact accepted shader package

Physical acceptance was recorded against idris-shader-backend commit:

```text
7a2c75f1564dfe82fddee4e975367faf5a3720e4
```

The published phone package was:

```text
powervr-runner-phone-armeabi-v7a.tar.gz
sha256 714e5f706a05224ff4f43188a6fb043e7fa39f6a7f7f6ea7b0ef0dcb424502de
```

The device did not compile the runner or shaders. It verified and executed the prebuilt payload.

## Physical execution result

Six shader probes compiled and linked through the vendor driver:

```text
1 set-pixel-3-rgb-52-39-182       compile/link PASS
2 set-block-32x32-rgb-52-39-182   compile/link PASS
3 dot-vector4-covector4            compile/link PASS
4 dot-vector32-covector32          compile/link PASS
5 subtract-vector8-norm            compile/link PASS
6 rotate-difference8-to-e1         compile/link PASS
```

All six framebuffer/readback probes also passed.

The unchanged packaged wrapper ended with:

```text
acceptance.generated_blobs: PASS
acceptance.renderer: PASS
acceptance.compile_link: 6/6 PASS
acceptance.framebuffers: 6/6 PASS
acceptance: PASS
```

One retained physical timing block recorded 4096 repeated draws:

```text
4x1 pixel-selection draw   3.485 us/draw
32x32 block-fill draw      3.684 us/draw
block/pixel ratio          1.057x
```

Other retained physical runs produced nearby values. No timing threshold was used for acceptance.

## Evidence boundary

Keep these separate:

- generated shader/source reproducibility in exact-head CI;
- Mesa/llvmpipe software execution;
- Android package integrity;
- physical PowerVR driver compilation/linking;
- physical framebuffer/readback;
- timing.

Mesa or an emulator does not substitute for this hardware receipt.

## Canonical sources

- https://github.com/fuego-ironworks/idris-shader-backend/pull/16
- https://github.com/fuego-ironworks/idris-shader-backend/pull/46
