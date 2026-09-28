# SVITOO TAB_P10 / Allwinner A333 microarchitecture research

Copied from `fuego-ironworks/idric-x86-aggressive-backend`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/6  
Original cross-index: https://github.com/fuego-ironworks/idric-x86-aggressive-backend/issues/37

## Target identity

Physical Android receipts identify the tablet hardware string as:

```text
model     TAB_P10
hardware  sun65iw1p1
ABI       arm64-v8a
```

The microarchitecture research associates the target with Allwinner A333.

## CPU organization

The retained A333 note records an asymmetric CPU complex:

```text
1 × Cortex-A73
4 × Cortex-A53
```

Native optimization must not flatten that into one uniform “five-core ARM” cost model. Big/little scheduling, thermal behavior, and sustained versus burst performance matter.

## GPU relation

The same target research records:

```text
Mali-G57 MC1
Valhall-family GPU
```

GPU execution evidence lives separately under `hardware/gpu/tab-p10-mali-g57.md`.

## Optimization boundary

The research explicitly separates:

- architectural ranges documented by Arm;
- facts attributed to the Allwinner A333;
- physical measurements still required on this exact tablet.

It does not claim that target-specific A64 optimization is already implemented merely because the microarchitecture has been identified.

## Physical-measurement direction

Retain measurements for:

- which CPU executes a workload;
- clock/frequency behavior;
- big/little migration;
- thermal throttling;
- memory bandwidth/contention;
- GPU/CPU shared-memory effects.

## Canonical source

- https://github.com/fuego-ironworks/idric-x86-aggressive-backend/pull/32
