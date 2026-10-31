# Direct APK native payloads

IB's checked Activity needs separately generated platform declarations and NDK
libraries in the same signed APK. The maintained direct packager owns that
assembly. It accepts an optional directory of numbered secondary DEX, named ABI
libraries and assets; existing single-DEX consumers keep their interface.

This is Grease orchestration of aapt2, dexdump, readelf, zipalign and apksigner.
It does not replace the checked compiler, generate application Java or assume
an installed device ABI. Every accepted name is bounded by the packaging grammar;
special files, primary-DEX replacement, missing DEX numbers, invalid checksums
and an ELF under the wrong ABI refuse. The final signed entries are compared
with every input and input hashes are checked again before exposing an APK.

The qualifier consumes actual checked Activity/platform DEX and an Android
x86_64 library, packages and independently reads them back, then exercises
symlink, primary-DEX override, sequence-gap, corrupted-DEX and wrong-ABI controls.
The existing explicit signer, package and certificate controls remain required.
Successful packaging does not establish ART execution, update compatibility,
Shizuku authorization, a working browser or physical tablet acceptance.
