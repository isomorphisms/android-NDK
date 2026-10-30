# Execute checked ICU on ART

The input is ART's actual argument array. `System.getArgs` must retain its
checked library implementation, including its synthetic executable name,
64-bit indices, range construction, traversal and ordered IO. The output is
ICU's actual response bytes and process status, through the existing JNI
transport. The application must not be replaced with a handwritten client.

## Types and runtime representation

Checked ANF functions retain all their live arguments, including erased values
and the World token. Internal managed values cross internal method boundaries
as Object. Text remains String. Whole numbers and machine integers use
BigInteger storage; every fixed-width arithmetic/cast operation must restore
its declared signed or unsigned width. Constructors retain their checked name
and fields in a managed node; partial applications retain the checked target
and captured arguments. Applying a closure copies its captures, so reuse cannot
mutate an earlier closure. World is an erased token; evaluation order comes
from the checked ANF bindings, not from treating IO as a pure expression.

Source functions, constructor matches and closure dispatch are lowered to the
existing typed FilePlan/MethodPlan and canonical Backend.DEX.Encode. Platform
collections and BigInteger provide storage and arithmetic, not application
semantics. No second DEX serializer or source-generator fallback is permitted.

Foreign services are admitted by checked declaration and signature. Argument
count/access reuse Backend.DEX.RuntimeArgs. JNI transport retains ICU's native
HTTP/TLS implementation. Unsupported primitives or foreign declarations must
produce a nonzero compiler exit and no candidate DEX.

## Initial reproduction

Backend source: d555a95215e3ed533800ba2824a6fbbb9cf73d4c.
Frontend: 740bbf2b1d9e811fd00c719c3473eede17ceea3b.
Initial reproduction used ICU's default branch at
468355b780d17f9b0838c8ac975962596811c484 and Idric-Net at
d74a163962c4a73bf4dee527823f49126cf2ae99. The maintained JNI/capture continuation
is ICU b1c19dc281e5e7d3d326c9275093fb379bafd4bd with Idric-Net
b21801b72acb8ab835c297bbe298af8599550134. Qualification must use those retained
integration sources, including their unchanged src/Main.idric.

`icu-jni.tsv` explicitly links the checked C foreign declarations to the
maintained JNI symbols and their platform descriptors. The compiler checks
argument/result compatibility, keeps World ordered, rejects ambiguous mappings,
and checks 64-bit source integers before narrowing to JNI's signed 32-bit ABI.
The library path is supplied through the `icu.library` property and loaded by
ART; a missing library fails without selecting a replacement.

The real checked application exits 1 at `System.prim__getArgCount` without a
DEX. Its ANF also exercises runtime constructors, closures, recursive list
functions, strings, finite-width casts, output, exit and native transport.

Host generation, independently decoded DEX, ART execution, HTTP/TLS behavior,
packaging and each physical device remain separate acceptance results.

API review found that BigInteger.intValueExact/longValueExact require API 31,
while the emulator lane uses API 29. The runtime now checks signed bit lengths
before the API 1 narrowing conversions and throws ArithmeticException on loss.
The independent observer covers both signed minima/maxima and both overflow
directions at 32 and 64 bits; the host gate refuses API 31 exact-conversion
references. Android reference: https://developer.android.com/reference/java/math/BigInteger#longValueExact().

The next unchanged-ICU compile exposed the required numeric-to-Char primitive
in Network.HTTP.ascii_lower. Its implementation now follows the pinned checked
frontend's Unicode scalar contract: valid scalars retain their value; negative,
surrogate and out-of-range values map to NUL. CharacterCasts checks those bounds.
The pinned frontend rejects both prefix `−1` and binary `0 − 1`, with nonzero
process status. The fixture uses descriptive `negate 1`; both failed source
forms remain in initial/. No frontend syntax change is claimed.

The f007837c13a4853e1d5475f65cda495fbb136c59 hosted run emitted/decoded ICU
and rejected the wrong JNI signature, then failed inside the maintained
OpenSSL recursive build; the inner log was not retained. Source analysis found
that Configure had the NDK on PATH, while the later Make invocation did not.
The caller now retains that exact NDK path
for the entire recursive build and captures the inner build log on failure.
No native transport source is replaced.

## Integration capture-path regression

Run 40576160334 at backend c47d524c097770daab330bd135f84da3851e151b
retained `icu-art/framing-tests.txt`: the first failing assertion is
`tests/FramingTests.c:96`, acceptance of two absent output paths in a newly
created owner-private directory. The earlier framing cases and JNI checks
completed. This is a native path-validation boundary, before ICU ART HTTP/TLS.

`CapturePathProbe.c` observes `Path -> IO (read_errno, search_errno)` for every
ancestor and `CapturePaths -> IO Bool` using the provider's actual private
functions. C is required here to include the existing native implementation and
exercise its static POSIX descriptor operations without creating another FFI or
transport. This is a native ABI regression test, not an Idric fallback. No new
Idric compiler capability is required for the repair.

`native-transport.patch` is an integration-owned overlay on exactly ICU
b1c19dc281e5e7d3d326c9275093fb379bafd4bd. It changes only ancestor directory
descriptors to Linux `O_PATH`, retaining `O_DIRECTORY`, `O_NOFOLLOW`, owner/mode
validation, distinct absent leaves and mode-0600 exclusive file creation. The
non-Linux path keeps its previous access mode. Idric/JNI source and the entire
original framing suite remain byte-for-byte unchanged.

The producer builds original and repaired native candidates with the same NDK,
OpenSSL and fixture inputs and retains both identities. The observer requires
the original candidate to reproduce line 96, logs the actual ancestor errors,
requires the repaired path probe and original full suite to pass, then executes
all checked ICU ART HTTP/TLS cases. A hypothetical permission explanation is
not execution evidence; the recorded probe and candidate outputs decide it.
Physical A1/C67 testing remains NOT_RUN.

The first repaired-head run, 40984278908 at
eacbd9be960c95488794ba5de763b7e612b2ac03, established the cause on API 29:
UID 2000 receives Permission denied (13) for read opens of `/data` and
`/data/local`, but search opens succeed. The original validator returns 0 and
fails line 96; the repaired validator returns 1 and passes all 55 original
checks. All 10 original JNI checks pass. HTTP and HTTPS GET/UTF-8 POST,
wrong-certificate identity rejection and redirect observations then pass.

The next real failure was `http-error`: HTTP 500 emitted `hello` and exited 0,
while the unchanged canonical assertion requires 10. Native `send_request`
applied status failure only to file-capture callers. The overlay now preserves
that result for stdout callers too. The adjacent early-read error conversion
also collapsed typed malformed-framing status 13 to generic write status 7;
it is removed while retaining the established TLS identity conversion to 5.
The next qualification compares original native outcomes 0/7 with repaired
outcomes 10/13 through the exact same checked ICU DEX and server, and retains
all four outputs. Extra Content-Length, NUL/status-line and hostile chunk
cases use the independently pinned existing server fixtures.

The native probe compile/link stage selects NDK 27.2.12479018, Android API 24
x86_64, as does the provider's existing Android Makefile. ICK revision
fbe86e23d55cfec2000c08e61deea2a407fd7175 is qualified here for the host, not
for this Android Bionic plus pinned OpenSSL cross-link surface. This specific
gap is recorded in `ci/build-toolchain.tsv`; no generic host compiler fallback
is used. Host server compilation continues through qualified ICK.

`record-integration.grease` assembles an artifact copy of the integration ledger
after each lane's required checks. Its input domains are an exact Git revision,
one current workflow run and existing test receipts; its only effect is writing
the current lane's Markdown/sha256 receipt. This is shell file composition in
Grease, not another compiler, evaluator or runtime. It does not predict the
workflow conclusion or grant a PASS to a different lane or commit.

Source review also found that managed node getters return Object, while tag
comparisons invoke String.equals. Explicit checked String casts now preserve
that representation invariant for ART's verifier. The actual checked argument
and ICU ART gates exercise those constructor/closure/string-list paths.
