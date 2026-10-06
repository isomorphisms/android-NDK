# MIRO C67 / PowerVR GE8320 GPU evidence

Cat Food owns the physical device profile. Shader-backend owns shader execution
receipts and its acceptance wrapper. This dossier connects those owners.

## Recorded physical identity

The [October 5, 2026 Cat Food ledger](https://github.com/isomorphisms/catfood/blob/602a2862d248dcfd9629c48c442574f1959513aa/docs/observations/miro-c67-hardware-2026-10-05.tsv), landed at
`602a2862d248dcfd9629c48c442574f1959513aa`, records this SurfaceFlinger context:

| Field | Observation |
| --- | --- |
| GL vendor | Imagination Technologies |
| Renderer | PowerVR Rogue GE8320 |
| GL version | OpenGL ES 3.2 build 1.13@5776728 |
| EGL implementation | 1.4 Android META-EGL |

This supersedes the earlier claim that physical GPU/driver identity was entirely
unverified. It records the compositor's context, not a consumer's EGL context,
GLSL version, enabled extensions, precision or successful shader execution.
The A1 application runner's EGL 1.5 and GE8322 driver build cannot replace it.
These differently scoped contexts are not a proven EGL contradiction.

## Package compatibility is not a device gate

Cat Food [PR #115, “Reconcile current Android delivery and retire old generations”](https://github.com/isomorphisms/catfood/pull/115),
audited at `fe7d665cb98ce28f2267859e081ac2eeeb7a9d7b`, lets C67 consume
the AArch64 manifest lane. Its [shader package row](https://github.com/isomorphisms/catfood/blob/fe7d665cb98ce28f2267859e081ac2eeeb7a9d7b/android/packages.tsv)
pins the tablet runner to shader source/package
`f3ed48fce28bbee0c0eb9d588e061502f4f323ff`, archive SHA-256
`25ee1a7de1cbfed2ab20670e8e26824904d98efe079f080d7d66e79a5a29bb50`.

However, the [exact packaged wrapper source](https://github.com/fuego-ironworks/idris-shader-backend/blob/f3ed48fce28bbee0c0eb9d588e061502f4f323ff/tools/accept_powervr_android.sh) requires
`GL_VENDOR: ARM` and `GL_RENDERER: Mali-G57` for
`package.target=tablet`. Current shader-backend main at
`4a29362e580df393e4d64a9929e4c1e592ac4c53` retains that rule.
An ABI-compatible C67 PowerVR run cannot pass this Mali gate. That is a source
constraint, not an observed C67 runner failure. Do not relabel C67 as TAB_P10,
edit a receipt to PASS or remove the existing Mali/PowerVR protections.

## Consumer requirement and smallest observation

[isomorphismes/Fourier-sound PR #28, “Keep FFT spectrum GPU-resident through Wegert rendering”](https://github.com/isomorphismes/Fourier-sound/pull/28)
at `3c2ecaafd9384b2096dd55b11cca5a74ec0c6c83` requires GLES 3.1 compute
shaders and SSBOs. Its GPU APK is A1-only `armeabi-v7a`; the historical six
fragment probes do not prove its FFT, compute/SSBO synchronization, microphone,
frame pacing or no-spectrum-readback path. No C67 GPU APK acceptance follows
from that PR's hosted builds.

The smallest C67 observation is the existing prebuilt six-probe runner in its
own EGL context, after exact package/ABI/hash verification, retaining C67
product/model/fingerprint, runner source, raw exit/output, EGL/GL/GLSL identity
and six compile/link/readback results. Preserve the existing timing block and
consumer-required extension/capability queries; precision behavior remains an
independent question. It requires no on-device compilation.
The existing tablet wrapper has no C67 gate: raw results would be diagnostic
evidence only until the shader owner supplies an explicit C67 identity gate.
Do not count its fixed 4096-draw characterization as a comparative speedup or
start a broader benchmark. This batch has not run that observation.

## Preserved model/platform research

MediaTek's Helio G36 specification lists IMG PowerVR GE8320 at up to 680 MHz.
The clock is a model/platform maximum, not a measured C67 operating clock.

- https://www.mediatek.com/products/smartphones/mediatek-helio-g36
- https://www.newegg.com/miro-c67-6-75-black/p/23B-00MN-00005

Indexes: [Android NDK #7](https://github.com/isomorphisms/android-NDK/issues/7)
and [shader-backend #65](https://github.com/fuego-ironworks/idris-shader-backend/issues/65).
The [A1 receipt](miro-a1-powervr-ge8322.md) and
[TAB_P10 evidence](tab-p10-mali-g57.md) remain device/package-specific.
