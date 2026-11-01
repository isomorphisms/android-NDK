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

ICU's checked command is carried as a DEX asset for the separately authorized
worker. The producer correctly included DEX assets in its integrity check but
used the entry's slash-containing name as a diagnostic filename without
creating that diagnostic directory. Flatten only the diagnostic filename,
preserving the asset entry and byte checks. The qualifier now includes a valid
DEX asset and rejects a separately corrupted DEX asset. Local packaging and
all six refusal controls pass with the real integrated reader Activity DEX,
platform declarations and ICK-produced x86_64 library. This remains packaging
evidence, not installed worker or physical-device evidence.
