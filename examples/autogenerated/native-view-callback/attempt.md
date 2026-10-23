# Program attempt: native Android View callbacks

Status: HOST_PASS; ART_NOT_VERIFIED.

Purpose: let a NativeActivity construct ordinary platform Views and receive
their click events in a native boundary without Java/Kotlin source.

Type sketch: a fixed platform adapter implements
`android.view.View.OnClickListener`. Its only virtual method is native
`onClick(View) : void`. Its constructor delegates to `Object.<init>`. The
application registers its C callback with JNI and owns every event meaning.
No application state, music operation or rendering decision lives in this DEX.

`ClickListener.idric` is a checked host-side adapter encoder. It reuses the
maintained DEX hash/file writer. This is explicitly a platform adapter, not a
claim that the generic ANF lowerer already implements objects or callbacks.
The raw DEX format requires sorted metadata, interface and parameter type lists,
constructor code, native-method flags, checksums and signature.

Implementation provenance: layout follows the existing
`Backend.DEX.EncodeNativeActivityShell` writer in the maintained backend.
Helpers are adapted at this raw encoding boundary, under the same GPL license.

Executed: checked and compiled ClickListener.idric using maintained Idriç
0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35 plus its Unicode subtraction fix,
and the DEX backend based on 9271de485f64d225d3dca05afa8504cc3a896de6.
The encoder emitted native-listener.dex; pinned baksmali 3.0.10 independently
decoded its constructor, native callback and interface. No Java source compiler
was used. The maintained packager included the declared DEX byte-for-byte in
both signed ARM development APKs and verified the finished signatures.

Fallback: none in this platform adapter. Installation, launch, native callback
execution and physical-device behavior remain unverified at this checkpoint.

First language boundary: generic checked object/callback lowering remains a
separate compiler task. This adapter must stay replaceable when that exists.
