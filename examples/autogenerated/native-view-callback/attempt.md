# Program attempt: native Android View callbacks

Status: HOST_PASS; ART class load verified in the application, interaction pending.

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
registered this class. Native callback interaction and physical-device behavior
still require their own evidence.

First language boundary: generic checked object/callback lowering remains a
separate compiler task. This adapter must stay replaceable when that exists.
