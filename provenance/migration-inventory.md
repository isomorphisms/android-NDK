# NDK / DEX / JNI migration inventory

Branch: `ndk-dex-jni-migration` from `isomorphisms/android-NDK` main
`1c6f8a8d2a6f8fa4fe9151e13f77eea69cdd687a`.

This is an accounting record, not a claim that every source project now uses
one implementation.  “Moved” means this repository owns the generic copy.
“Reference” means the original project remains canonical for the detailed or
application-specific work.

## Recovered material and disposition

| Recovered component | Source and revision | Paths inspected | Classification and disposition |
| --- | --- | --- | --- |
| Existing Android-NDK hardware cross-index | `isomorphisms/android-NDK` main `1c6f8a8` | `hardware/` and issues [#1–#10](https://github.com/isomorphisms/android-NDK/issues) | **Copied specialized reference material.** Original device dossiers remain canonical; Android-NDK owns only the working cross-index and generic constraints. |
| Existing DEX/JNI migration lane | `isomorphisms/android-NDK` branch `migration/dex-jni-nativeactivity`, commits `e21b839`, `3d6ea6e`, `0afb782`, `579923a`, `bdb7667` | `dex/idric/`, `licenses/idric-arm-thumb-LICENSE` | **Moved to this branch by merge.** The existing five commits remain intact rather than being flattened or rewritten. |
| Direct Idriç DEX core | `fuego-ironworks/idric-arm-thumb` `harden/dex-architecture-boundary` `53d2e822e41d7cc66e5e4d0b61f3f6e43cd17575` | `src/Backend/DEX/{Codegen,Encode,Hash,IR,Lower,Main,Smali}.idr`, `README.md`, `AUDIT.md`, opcode and pseudo-register notes | **Moved generic implementation.** The imported `dex/idric/src/Backend/DEX/` core matches this source tree byte-for-byte after its path prefix changes. |
| DEX branch history | `idric-arm-thumb`: `dex-backend` `2e1f194`, executable slice `4f64e5c`, Idriç integration `efd912b`, NativeActivity/JNI `0b12417`, provenance gate `25ed95d`, hardening `53d2e82` | DEX backend history and tests | **Retained in source and recorded.** The copied core preserves the current hardened source snapshot; source history remains the primary historical record. |
| DEX branch-separation guard, Reddit/ICU work, and app fixtures | `idric-arm-thumb` `harden/dex-architecture-boundary` and branches `dex/reddit-cli-jni`, `dex/icu-*` | `tests/dex/branch-separation*.sh`, Reddit and ICU paths, source workflows | **Retained in place and linked.** The branch-separation guard protects Idriç's own sibling-backend topology. Reddit and ICU hold application/unfinished semantics; no generic substitute or partial rewrite moved here. |
| Hand-encoded NativeActivity/JNI fixtures | `idric-arm-thumb` `53d2e82`, especially prior `feature/dex-nativeactivity-jni` `0b12417` | `EncodeNativeActivity*.idr`, `wegert-dex.ipkg`, Wegert/NativeActivity manifests and tests | **Copied historical integration reference.** It remains inside `dex/idric/` with its app-specific names. It is not declared a generic class/object lowering layer. Wegert remains canonical for its app integration. |
| ICK Android release qualification | `dilapidated-shed/ick` `foundation/android-release-toolchain` `37c30cdb2d557bad8c811e2669f629a79ff4e5b3` | `docs/android-release-gate.md`, `qualification/android-boundary/`, Android ABI workflows | **Retained in place and linked.** It qualifies ICK-specific source, ABI, ELF, and NDK-link slices; it must not be relabeled as general Android release support. |
| Wegert direct DEX/JNI APK lane | `isomorphismes/wegert` direct-DEX head `a2192d37` and inspected main `0a7a55e` | `android-direct/` at the direct-DEX head; `_/build/android-direct/` after its later project reorganization; direct-DEX workflow, native renderer, and signing lane | **Retained in place and linked.** It proves one app's DEX → JNI → native integration. Renderer, shaders, resources, package identity, and release lanes stay with Wegert. |
| Generic AAudio input source | `isomorphismes/Fourier-sound` `audio/native-input` `0c05d1f5228cb4bba0f639b2c7f6f3e6281f7d59` | `audio/interface/`, `audio/android/`, fake-AAudio host test | **Moved generic implementation.** Exact copies live in `native/audio/`; framing, Fourier conversion, permissions, acceptance UI, manifest, APK, and microphone procedure remain in Fourier-sound. |
| Speaker/output sink | Android-NDK [issue #10](https://github.com/isomorphisms/android-NDK/issues/10) and Fourier-sound audio source | issue and audio source | **Unresolved / not implemented.** The recovered source supplies input only; no invented output interface was added. |
| Android accelerometer adapter | `Ashtray-Archer/utilities-android-phone-user` `a8722e10318c63ea656729ee2c2cce526a423754` | `accelerometer/android/android_accelerometer.[ch]` | **Moved generic implementation.** Exact copies live in `native/sensors/accelerometer/`. Compact state, inspection model, CLI, app, and detailed device work remain in the source project. |
| Pauli Android viewer | `isomorphismes/pauli` native viewer history, main `5133a5b`, production branch `android/orbital-viewer` `5d43e69` | `android/`, manifest, native renderer, historical direct-DEX commits | **Retained in place and linked.** Pauli's production shape is NativeActivity with no application DEX. Orbital mathematics and renderer do not move here. |
| Analytic Continuation direct-DEX overlay consumer | `isomorphismes/analytic-continuation`, app revision used by the source DEX workflow `196b567c3de420dca52ed6164802d26aec0e9924` | Android package and source workflow reference | **Retained in place and linked.** Its application code and Android build lane do not establish a generic DEX or JNI implementation. |
| SURFER prepared-surface native work | `isomorphismes/algebraic-variety-explorer-mobile` branch `surfer`, `3fd55197bb834661ac49ffd62cc36f49654970c1` | `native/surfer_raytracer.[ch]`, `native/README.md` | **Retained in place.** It is an application ray-tracing core with an unfinished JNI ownership boundary; it is not a complete Android DEX/JNI precedent. |
| GLES/shader and GPU evidence | `fuego-ironworks/idris-shader-backend` plus existing Android-NDK hardware dossiers | GPU dossiers and source-linked receipts | **Copied specialized reference / retained source.** Shader code and device performance choices remain target-specific. |
| Literal `ndk-jni-dex` repository label | project conversation history | no owner/name/commit/path recovered | **Unresolved.** No source repository could be identified safely, so no invented substitute was copied. |

## Source links

These point to the preserved source revision or its closest recoverable
historical entry point.  A source repository remains canonical for the work
classified above as reference or retained in place.

| Component | Preserved source link |
| --- | --- |
| Android-NDK prior migration lane | [`migration/dex-jni-nativeactivity`](https://github.com/isomorphisms/android-NDK/tree/migration/dex-jni-nativeactivity) |
| Idriç direct DEX core | [`src/Backend/DEX` at `53d2e82`](https://github.com/fuego-ironworks/idric-arm-thumb/tree/53d2e822e41d7cc66e5e4d0b61f3f6e43cd17575/src/Backend/DEX) |
| Idriç DEX hardening history | [`53d2e82` commit](https://github.com/fuego-ironworks/idric-arm-thumb/commit/53d2e822e41d7cc66e5e4d0b61f3f6e43cd17575) |
| ICK Android release gate | [`docs/android-release-gate.md`](https://github.com/dilapidated-shed/ick/blob/37c30cdb2d557bad8c811e2669f629a79ff4e5b3/docs/android-release-gate.md) |
| Wegert direct DEX lane | [`android-direct/` at `a2192d37`](https://github.com/isomorphismes/wegert/tree/a2192d371555d45235fdf05e67a4766c883789a3/android-direct) |
| Fourier-sound native input | [`audio/` at `0c05d1f`](https://github.com/isomorphismes/Fourier-sound/tree/0c05d1f5228cb4bba0f639b2c7f6f3e6281f7d59/audio) |
| Utilities Android accelerometer adapter | [`accelerometer/android/` at `a8722e1`](https://github.com/Ashtray-Archer/utilities-android-phone-user/tree/a8722e10318c63ea656729ee2c2cce526a423754/accelerometer/android) |
| Pauli native viewer | [`android/` at `5d43e69`](https://github.com/isomorphismes/pauli/tree/5d43e69a63173b44120782d684c77283316120bd/android) |
| Analytic Continuation consumer revision | [`196b567` commit](https://github.com/isomorphismes/analytic-continuation/commit/196b567c3de420dca52ed6164802d26aec0e9924) |
| SURFER prepared-surface work | [`surfer` revision `3fd5519`](https://github.com/isomorphismes/algebraic-variety-explorer-mobile/tree/3fd55197bb834661ac49ffd62cc36f49654970c1/native) |

## Reciprocal backlink status

The generic repository points to the detailed source material above.  The
following reciprocal documentation changes were published as separate,
one-file source branches and pull requests, then merged without altering the
source material that they describe.

| Source location | Status | Published backlink |
| --- | --- | --- |
| Fourier-sound `README.md` and `docs/architecture.md` | already present at the recovered source revision | [existing Android-NDK link](https://github.com/isomorphismes/Fourier-sound/blob/0c05d1f5228cb4bba0f639b2c7f6f3e6281f7d59/docs/architecture.md) |
| Idriç DEX backend README | merged into source `main` | [fuego-ironworks/idric-arm-thumb PR #105](https://github.com/fuego-ironworks/idric-arm-thumb/pull/105) |
| ICK Android release gate | merged into source `main` | [dilapidated-shed/ick PR #35](https://github.com/dilapidated-shed/ick/pull/35) |
| Wegert direct DEX/JNI README | merged into source `main` | [isomorphismes/wegert PR #62](https://github.com/isomorphismes/wegert/pull/62) |
| Utilities accelerometer README | merged into source `main` | [Ashtray-Archer/utilities-android-phone-user PR #78](https://github.com/Ashtray-Archer/utilities-android-phone-user/pull/78) |
| Pauli Android README | merged into source `main` | [isomorphismes/pauli PR #18](https://github.com/isomorphismes/pauli/pull/18) |

## Preservation checks performed

- The merged DEX core tree matches the `idric-arm-thumb` hardening snapshot for
  every copied `src/Backend/DEX/` blob.
- All ten audio and accelerometer source files in `native/` match the recorded
  source blobs exactly.  Only their repository path changed.
- The incoming Android-NDK migration lane was merged as its existing sequence
  of five commits; no bulk delete/reconstruction replaced it.
- The existing `hardware/` policy still names original repositories as
  canonical for detailed device facts.

## Evidence not upgraded by this migration

- The imported DEX backend was not rebuilt here: its current compiler checkout
  and declared Idriç API-install environment are absent from this workspace.
- No Android SDK/NDK package, APK build, emulator launch, or physical-device
  test ran as part of source migration.
- The copied AAudio test is a host fake-backend test only.  It does not prove
  microphone access, permissions, physical audio, or a packaged application.
- ICK's branch-specific ABI receipts remain ICK evidence.  They do not qualify
  every native consumer or a store release.

## Follow-up boundaries

- Add a source-controlled backlink from each important consumer/source location
  to this canonical repository without moving its application logic.
- Recover an exact source identity for any real repository named
  `ndk-jni-dex` before changing or deleting anything under that label.
- Extend direct DEX only with checked source fixtures and independent ART
  acceptance evidence; the present compiler slice still rejects broad class,
  object, string, array, exception, floating-point, and framework-call work.
- Implement an audio output sink only after recovering or defining its own
  source contract and acceptance evidence.
