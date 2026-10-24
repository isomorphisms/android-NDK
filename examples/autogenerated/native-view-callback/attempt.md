# Program attempt: native Android View callbacks

## Pre-ICU consolidation

The missing shared module is recovered verbatim from
`fuego-ironworks/idric-arm-thumb@c13a6a223a24c211d090d2c88a395c134ed8d469`,
`src/Backend/DEX/FrameworkClasses.idr`, blob
`1ce706303759a18123389c9db66e5b3108db16a3`. No ICU branch is used.
It shares the canonical DEX writer/hash modules; its bounded native-method
class plan stays distinct from checked-ANF application method lowering.

The qualification input is this checked `FrameworkClass` plan. The output is
a fresh DEX file; invalid class/interface/native-method plans must return
`Left` before writing bytes. A pinned Idriç compiler builds the library and
fixture. Independent AOSP decoding and baksmali check inheritance, interfaces
and native callback signatures. Repeated generation must be byte-identical.

Packaging combines that actual DEX with the existing native fixture and signer.
The DEX-free receipt remains v2; the explicit-DEX lane uses v3 and includes
launcher, DEX bytes and subclass-oracle identity in material identity. The DEX
payload receives the same epoch/mode/ZIP normalization as other payloads.
The independent verifier checks both the APK and its extracted DEX digest.
Host compilation/decoding, reproducible packaging and historical API29 callback
execution remain separate evidence. Fresh native callback execution is not
inferred from a package check. No fallback language or compiler is introduced.

The current generic language boundary remains arbitrary checked heap values
and callbacks; this import only repairs the declared native-adapter dependency.
The acceptance test for future replacement must exercise real source callbacks
through ART/JNI rather than treating this host-side class plan as source-ANF
object lowering.

Status: HOST_PASS; ART class load and real View click callbacks verified on API29.

Purpose: let a NativeActivity construct ordinary platform Views and receive
their click events in a native boundary without Java/Kotlin source.

Type sketch: a fixed platform adapter implements
`android.view.View.OnClickListener`. Its only virtual method is native
`onClick(View) : void`. Its constructor delegates to `Object.<init>`. The
application registers its C callback with JNI and owns every event meaning.
No application state, music operation or rendering decision lives in this DEX.
The second declared class extends framework NativeActivity and forwards
onActivityResult and onNewIntent to native platform callbacks. This permits
the standard Android document picker and single-task intent delivery.

`ClickListener.idric` is a checked host-side adapter encoder. It reuses the
maintained DEX hash/file writer. This is explicitly a platform adapter, not a
claim that the generic ANF lowerer already implements objects or callbacks.
The raw DEX format requires sorted metadata, interface and parameter type lists,
constructor code, native-method flags, checksums and signature.

Implementation provenance: the initial hand-encoded adapter was replaced when
the maintained FrameworkClasses encoder became available. ClickListener.idric
now supplies a checked class/native-method/interface plan to that encoder.
The reusable interface type-list extension and hostile tests belong to the
backend repository. This file owns only the Android platform declaration.

Executed: checked and compiled ClickListener.idric using maintained Idriç
0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35 plus its Unicode subtraction fix,
and the DEX backend based on 9271de485f64d225d3dca05afa8504cc3a896de6.
The final shared class/interface-plan dependency is
c13a6a223a24c211d090d2c88a395c134ed8d469, reconciled with maintained framework
classes at6ecf378dd3e8dac59091ce8d7f3c3f315f43e4a5.
The encoder emitted native-listener.dex; pinned baksmali 3.0.10 independently
decoded its constructor, native callback and interface. No Java source compiler
was used. The maintained packager included the declared DEX byte-for-byte in
both signed ARM development APKs and verified the finished signatures.

Fallback: none in this platform adapter. The signed x86_64 application installed
and launched on the API29 emulator; its C boundary successfully loaded and
registered this class. Actual Save, transpose-up and transpose-down View clicks
reached native callbacks and the application's checked Idric DEX operations.
Process restart reopened the stored Unicode source. Physical-device behavior
remains unverified. The document-result callbacks have been built and loaded;
their interaction acceptance is tracked separately by the application.

The canonical packager's executed fixture suite passes, including rejection
of a declared subclass without DEX. A finished signed application APK also
passed the pinned disassembler's exact declared-class/superclass gate.

First language boundary: generic checked object/callback lowering remains a
separate compiler task. This adapter must stay replaceable when that exists.
