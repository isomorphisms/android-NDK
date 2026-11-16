# Generated application owner

The Android 6 manifest parser rejects the existing `Idric.Generated` Activity
name: a fully qualified component name must start with a lowercase letter.
The application needs to select its real emitted class, with the same owner in
its manifest, DEX and JNI declarations. Changing a manifest string alone does
not satisfy this requirement.

## Type sketch

The input is a list of compiler directives. Owner selection returns either a
diagnostic or one validated object descriptor and the remaining directives.
The default remains `LIdric/Generated;` for existing consumers. An explicit
selection must be a qualified ASCII class descriptor whose first component
starts with a lowercase letter; framework namespaces and repeated selections
are refused.

The compiler first checks source ABIs, managed fields, callbacks and native
contracts using its existing internal generated-owner vocabulary. A pure
typed-plan operation then maps the generated class and its captured Runnable
to the selected owner. It maps typed declarations and references, including
array reference descriptors, but preserves ordinary string constants. The
result enters the existing finalizer and binary encoder. No emitted Smali or
DEX bytes are rewritten.

Central operations:

- `select_generated_owner : List String -> Either String (String, List String)`
- `relocate_generated_classes : String -> List FilePlan -> List FilePlan`

Default compilation must remain byte-for-byte identical. Explicit selection
must change every generated self-reference consistently, preserve unrelated
types and text, and remain independently decodable. The application owns the
corresponding JNI symbol names and manifest. This compiler change cannot
claim APK installation, Android execution or physical-device acceptance.

## Verification

The 27-module driver builds through the pinned checked frontend. The real
source fixture combines an ordinary Activity, a private managed state field,
captured IO actions, exception handling and synchronous JNI. Independent
decoding confirms the selected primary and companion class definitions,
field/native/helper references and unchanged literal data. Repeated custom
compilation is byte-identical and independent reassembly succeeds.

Malformed, uppercase/unqualified, invalid component, framework namespace,
array and trailing-data owners are refused. Identical and conflicting repeated
selections are refused. Each refusal also removes an intentionally seeded
stale candidate. These checks run in the existing canonical qualification.

The default fixture emitted by the previous driver and by the new driver has
identical SHA-256
`d7a66004d8a0a4a4b6a4dcd11ee5aa6e90fd88727b827e2968f7dd69384d1790`.
The custom-owner candidate has SHA-256
`6d2fb10140849b90cacf69f86edb822ce0eecc39d85658184ed5eedc69b554d7`.
This comparison covers the fixture, not every possible source program.

An initial test JNI row used the historical three-column map and refused
`Int32` as expected by that legacy contract. The current row explicitly selects
the existing synchronous checked contract. The checked source is preserved;
this configuration repair required no fallback or widened ABI.

The actual APK must still establish that the manifest, emitted class and JNI
owner agree on Android. Application installation and physical behavior remain
separate acceptance, owned by the consuming application.
