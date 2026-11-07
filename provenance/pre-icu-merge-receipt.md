# ANDROID-NDK-MERGE-01 acceptance receipt

All nine scoped pull requests are merged to main. The code integration commit
is `34f7e2b05a221526eb649de6fb186f45bf00dae3`; its complete Git tree is
`e3d715ac5485b9642e0479d10399b16cf5ad0e56`, exactly equal to qualified candidate
`df4ab1aa4cc2bd6b7a4df874c2dbd7c469d39545`. This receipt is a documentation
addition after that integration; it does not identify its own publication
commit as the code-integration commit.

The [merge ledger](pre-icu-merge-receipt.tsv) records each actual two-parent
merge, its actual base and head hashes, and its destination. The
[architecture inventory](pre-icu-dex-baseline.md) records reusable interfaces,
limitations and original source provenance.

## Completed qualification at the exact combined candidate

| Boundary | Result and evidence |
| --- | --- |
| Fresh checked backend with pinned Idriç/compiler API | PASS, [checked-effects run 40144947700](https://github.com/isomorphisms/android-NDK/actions/runs/40144947700), checked-effects job 121024257584 |
| Host placement, encoding, layout/report consistency, constructors, both Activity forms, Unicode/loop values, source refusals and actual production mutations | PASS, same checked-effects job; original negative fixtures retained |
| Independent AOSP and pinned baksmali decoding, deterministic recovery | PASS, same checked-effects job |
| Android 14/API34 x86_64 ART: references/effects/range, unpack and actual IB diagnostic, real framework click, source loops, TextView instrumentation, native reader touch and chooser | PASS, same job; original/recovery succeed and the intended production mutants fail with their distinct observations |
| Actual NativeActivity callback class plan, negative controls and fresh emitted DEX | PASS, pinned compilation, deterministic regeneration and independent class/interface/method decoding; same checked-effects job |
| Grease-owned reproducibility and receipt verification; existing package identity/resources/signing and hostile fixtures | PASS, [packaging run 40144947702](https://github.com/isomorphisms/android-NDK/actions/runs/40144947702), job 121024186693 |
| Same-run callback DEX in a signed NativeActivity fixture, v3 receipt, normalized DEX payload, changed-byte material identity, default no-DEX refusal and wrong-parent refusal | PASS, dependent native-callback-package job 121025920370 in run 40144947700 |
| WebView native shells, invalid-plan controls, independent hashes/disassembly and deterministic regeneration | PASS, [run 40144947747](https://github.com/isomorphisms/android-NDK/actions/runs/40144947747) |
| Retained fake-AAudio host model and qualified ICK routes for armeabi-v7a, arm64-v8a and x86_64 assembly/linking | PASS, [run 40144947699](https://github.com/isomorphisms/android-NDK/actions/runs/40144947699); these are not physical microphone tests |

The declared-DEX reproducibility fixture produced APK SHA-256
`a6a487ddf31136a5a92b465b40e6c6740dba45dc67b20f03c05dd4c3e0eb8c62`
and material SHA-256
`a706f111ea173ba1754b55f3b5825fd2206c08eba661842a20dee377a67ccb46`.
The declared NativeActivity-subclass fixture produced APK SHA-256
`60d7ef581d3cc2fef319562c4a48e24199c1f3ce52d98dd4da6fa80fd66cd4d1`.
These are hosted packaging observations, not delivered or installed device
artifacts. The existing public Wegert development certificate was retained.

## Preservation and evidence boundaries

- Every file added by the nine original scoped heads remains in the combined
  tree. Their independently useful implementations, documents and negative
  fixtures survive; normal merge ancestry retains the original commits.
- FrameworkClasses matches original blob
  `1ce706303759a18123389c9db66e5b3108db16a3` from the original backend at
  `c13a6a223a24c211d090d2c88a395c134ed8d469`.
- The reproducible-packaging merge preceded accounting for its recorded
  source-policy objection. The final integration corrects the owned verifier
  and qualifier to tested Grease implementations. Old green Bash-based
  workflow results alone are not credited as resolving that objection.
  Failed Grease attempts remain recorded in the native callback attempt
  document and normal branch history.
- The checked-effects compiler pin is
  `ff4d852862a3942592f8ade9afde8d409d9803be`; WebView host qualification
  separately uses `e8b9173ab2d840ef0cf212698ea2fee97bd9e807`.
  Grease `f19c94c6df18cddbdc1e81463e5bd689533e3c13` is built through
  Cat Food `609a9628d5a52860f956bf62e0914a0cd03292ae`.
- Fresh native-callback ART/JNI behavior and physical A1/C67 acceptance are
  NOT_RUN. Historical API29 consumer execution remains historical evidence.
  The inherited Chez/compiler-bootstrap/shared producer-qualification debt
  remains separate; this receipt does not promote a compiler/toolchain
  producer or establish a general heap, closure or recursive-call runtime.
- [isomorphisms/android-NDK PR #30, “Canonicalize DEX/JNI and execute checked recursive calls”](https://github.com/isomorphisms/android-NDK/pull/30)
  remains open at unchanged head
  `973c24bc0b4eab6f3c88699102f7cb0e7fd8951f`. None of its 13 commits unique
  against the original scoped heads is reachable from the qualified
  candidate or the integration commit.
