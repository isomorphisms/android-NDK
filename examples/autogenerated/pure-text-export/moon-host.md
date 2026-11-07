# Independent replay of the reconciled export paths

Moon checked clean source `a92ad9edcfd33e9283ea4c2e2af8daeae6d6c672`, tree
`c040f5cfe7f5b50f39dd17131b4845b9422a4366`, on Linux x86-64 Ubuntu 24.04.
Every backend source digest matched the build receipt. The existing exact-source
driver was reused, not independently rebuilt; its program SHA-256 was
`e92c2f67a606fe66dd728e729d75157da2eb7ec68b3a9b4854eed444370b2346`.

Both maintained source qualifiers executed again with separate fresh evidence
directories and exited zero. Inputs were frontend
`740bbf2b1d9e811fd00c719c3473eede17ceea3b`, IB reader
`59716dabd375f0d49b8fb67a18dfd604b33a923a` and IB search
`dcbd86c0f7a69c4e0b381c0ab53f7c41f9966900`. Native Grease executable SHA-256
was `7e31cd05b7a9d8fb2a4a9e003a7f3fcb0159138506d17f0fb28da8cbe22aa85c`;
`ASAN_OPTIONS=detect_leaks=0` was explicit. The verified Idriç 94df bundle's
launcher supplied the Chez runtime environment; the candidate compiler remained
the recorded frontend-740 backend driver. Oracle JAR digests matched the hashes
in `verify.grease`.

| Source and boundary | Reproduced DEX SHA-256 |
| --- | --- |
| Automatic pure IB projection | `3800b35d2e3476e09ade2ea444253f32168d09b91e71dcfdca745620be780544` |
| Explicit managed generic exports | `3f8fea8a9a6e5ab8f1c2ae57ec48b8be4e9115763c4220ca851ffd01c3c269e9` |
| Explicit managed IB search | `479abee4229eefa1670dd41d6c0df89d1744616afc19c674aa08e22b9950cd6c` |
| Explicit managed IB projection | `7c20301a781f4726d3925b1ccbd43602e2940e39b91a3b82d8f897eac0be244d` |

The copied IB module graphs and exported consumer sources compare byte-for-byte
with the pinned originals. The automatic qualifier passed host title goldens,
repeated emission, independent wrapper decoding, view-only Unpack preservation,
an allocating marker, scalar and command controls. Its unsupported ABI,
generated-name collision, hidden IO and framework-directive cases each refused
with exit 1 and no DEX. Its actual wrong-title source mutant compiled separately.
The explicit qualifier passed generic recovery determinism, independently
decoded both unchanged IB consumers, emitted a distinct semantic mutant and
refused a source-typechecked wrong platform signature without DEX. The pure
external caller and all three managed external observers assembled successfully.

Workflow review confirmed exact-head checkout and explicit-mode deferral in the
automatic selector. All existing core, argument, managed, ICU preparation and
ICU ART commands remain required. Core/managed/pure ART now precedes the
separate ICU preparation and ART steps; both emulator steps retain API 29
x86-64. No failure was made optional. The renewed Grease archive independently
rehashes to `6296b49206d5b9e16e2c30c49384dc7c86396f389dc2a5b013588a4f432dadbe`,
and its extracted executable matches the tested runtime digest above.

This is independent host execution, source-generation and decoding evidence.
The fifteen host suites were not repeated by Moon. ART, Activity lifecycle,
Binder, APK and physical A1/C67 execution remain NOT_RUN in this replay. Emitted
source mutants are runtime rejection obligations, not runtime passes.
