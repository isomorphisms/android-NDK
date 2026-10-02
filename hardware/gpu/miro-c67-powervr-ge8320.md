# MIRO C67 / PowerVR GE8320 GPU target research

This dossier records **model/platform** evidence. Physical MIRO C67 EGL/GLES driver identity and shader execution remain unverified.

## Platform facts

MediaTek's Helio G36 specification identifies:

```text
GPU              IMG PowerVR GE8320
max GPU clock    680 MHz
```

The MIRO C67 retail listing identifies the Helio G36 SoC.

Sources:

- https://www.mediatek.com/products/smartphones/mediatek-helio-g36
- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005

## Evidence boundary

Do not copy the MIRO A1 PowerVR Rogue GE8322 acceptance result onto the C67.
GE8320 and GE8322 are related PowerVR parts, but a model-level GPU name does not
establish the physical Android driver, GLES version, precision behavior,
framebuffer behavior, or timing.

Physical C67 acceptance should retain at least:

```text
EGL version
GL_VENDOR
GL_RENDERER
GL_VERSION
GLSL version
declared extensions/capabilities needed by consumers
compile/link results for the retained shader probes
framebuffer/readback results
timings for the same fixed probe set used on the A1
```

That receipt can then drive shader selection and GPU/CPU work partitioning without
mixing model documentation with physical execution evidence.
