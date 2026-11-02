# Deterministic direct checked-DEX APK staging

Purpose: retain the existing checked-Dex/aapt2/zipalign/apksigner producer while
making repeated packaging of identical inputs produce identical signed bytes.
The caller still supplies the manifest, resources, DEX, payload, package identity
and existing public test key. No candidate Java, Kotlin, smali, d8 or alternate
packager is introduced.

Type sketch: validated manifest/resources + checked DEX + bounded declared
payload + explicit existing signer -> signed package with independently checked
identity, alignment and byte-preserving entries. Archive metadata is a producer
property. Document bytes, native modes and signing identity remain input
properties.

The independent ai-ci reproduction at observer
48065212f0ed9e2ef39110363fd8a6c097b00f8f, run 41365426201, used frozen IB
d02fe516833d0941e8ff1ab2b84369c1661aee6c inputs, backend
9861b303a7e6d989125d80cee552a46cb2503555 and artifact 13101964714. Two valid
packages created three seconds apart had SHA256
c2a00225486a4b8738c5b29312f1bfa949881ff756ae5cc3463bb44e5d31f4ed and
10f24dc7392d9ecbcd1cc7dc46a50734627b1a54bba5f47927d3bf6961e835a0.
The comparator exited 1. This is an observed packaging failure, not a reader or
physical-device result.

The producer now copies DEX and validated payload files into its fresh owned
output, preserving input Unix modes. Only those copies receive the ZIP minimum
1980 UTC timestamp. zip runs in UTC with host extra fields excluded. The caller's
source paths are never touched to normalize metadata. Payload ordering, declared
entry restrictions, DEX integrity, ELF ABI checks, existing key validation,
signature, package, alignment and extracted-byte comparisons remain in force.

Independent acceptance must repeat the old producer as a failing control and
this producer as the positive with the same frozen inputs at separated times,
check source bytes/modes/mtimes remain unchanged, and retain actual hashes. That
test is pending at this commit. A pass here cannot qualify IB0d2 native behavior,
an ARM runtime, a TAB_P10 signer/update or a physical Binder/Shizuku transaction.
