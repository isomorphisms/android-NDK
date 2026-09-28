# PowerVR precision and instruction-layer research

Copied from `fuego-ironworks/idris-shader-backend` and the matching ComputerScience floating-point work.

This note is target research. Physical GE8322 renderer acceptance lives in [miro-a1-powervr-ge8322.md](miro-a1-powervr-ge8322.md).

## F32 versus F16 semantics

The shader-backend research corrected an important ambiguity:

```text
Idris Double -> GLSL ES float
```

does **not** mean binary64 arithmetic on the GPU.

The existing shader path was made explicit as:

```text
semantic F32 -> explicit highp float / highp vecN
```

F16 is a distinct semantic width, not an alias for F32 and not an implicit demotion.

Key invariants from the research:

1. no unlabelled `Double` -> GLSL narrowing in typed diagnostics;
2. F32 emits high precision explicitly;
3. F16 and F32 remain distinct in backend policy/types;
4. no implicit F32 -> F16 conversion;
5. vector width and float width are both preserved;
6. portable GLES `mediump` is not claimed to be exact binary16 without target evidence;
7. PowerVR gets a target profile rather than a global text replacement of `highp` with `mediump`;
8. CPU-width-controlled oracles and real-device framebuffer tests decide whether reduced precision is acceptable.

## Portable GLES versus PowerVR

Portable GLSL ES defines minimum precision/range guarantees for `mediump`; it does not universally promise IEEE binary16 storage/arithmetic.

Imagination's PowerVR guidance documents `mediump` shader variables as FP16 on the relevant PowerVR architecture family and recommends lower precision when range/accuracy permit it.

Therefore:

```text
semantic F16 request
    != generic proof of binary16 on every GLES implementation

PowerVR mediump/FP16 documentation
    + physical driver/framebuffer evidence
    = stronger target-specific basis
```

The later physical MIRO acceptance separately proved the real GE8322 driver identity and successful shader execution.

## CPU ABI is a separate axis

Floating value width and Arm procedure-call ABI must not be conflated:

- `soft`: software arithmetic, base/core-register calling convention;
- `softfp`: hardware floating arithmetic permitted, base/core-register calling convention;
- `hard`: VFP procedure-call variant.

Likewise scalar versus vector execution is separate from F16/F32 value semantics.

## USC instruction layer

The PowerVR teaching work also made a strict layer distinction:

```text
source helper
    -> typed shader representation
    -> GLSL ES operation/builtin
    -> vendor compiler
    -> PowerVR USC instruction selection/fusion/scheduling
```

A GLSL builtin is **not** a PowerVR machine instruction.

The historical USC catalogue was seeded from Imagination's public Series 6 instruction-set material and marked generation-dependent material explicitly. It exists as an architectural reading aid, not as proof that a particular GLSL expression lowers one-to-one to a named USC instruction on GE8322.

## Canonical research

- https://github.com/fuego-ironworks/idris-shader-backend/pull/10
- https://github.com/fuego-ironworks/idris-shader-backend/pull/17
- https://github.com/walnut-burgundy/computer-science/pull/10
- `fuego-ironworks/idris-shader-backend/docs/float-semantics.md`
