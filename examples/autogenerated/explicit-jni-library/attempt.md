# Explicit application JNI library name

## Reduced production failure and owner/type sketch

A production direct-DEX Activity initializes `Idric.Generated` before its source
entry can set a library-path property. The existing JNI-map header
`library_property contract.library` makes that initializer call
`System.load(System.getProperty("contract.library"))`; it requires a property
set before class initialization. Application source cannot satisfy that
precondition from a method on the same class. The current map parser also
accepts no literal library-name header. This is a compiler/source boundary,
not permission to set a global property, generate a Java class or hardcode a
native application path.

The reduced checked `LibraryIdentity.idric` retains a real typed JNI call and
export. `library.tsv` selects the requested application-owned logical library
name. Against the old driver its first blocker is the map-header refusal;
the property map preserves the historical getProperty/load initializer.
The production lifecycle failure is established by that initialization order;
no physical APK launch or missing-property runtime exception is claimed here
without a retained observation.

An additive typed JNI-library selection distinguishes an absolute-path property
from a logical library name. The latter emits a literal followed by
`System.loadLibrary`. A logical name is nonempty ASCII letters/digits/underscore,
matching the existing framework-class native-library profile; paths, suffixes,
whitespace and ambiguous headers refuse. Each map still selects exactly one
header and one nonempty checked native-service set. Native signatures and
ownership policies do not change.

The historical property initializer retains its API and exact instruction plan.
Source qualification must independently decode the new initializer, repeat its
DEX bytes deterministically, reject malformed/duplicate headers, and compare
the unchanged property fixture against an exact pre-change driver. No candidate
Java, smali or native loader workaround participates. A native library remains
application-owned and must actually be packaged for each ABI before APK/runtime
acceptance can follow. Driver build and target execution are separate gates.

## Retained pre-change observation

The selected pre-change driver program has SHA256
`f80c83b5f51f9403f27a6fa693a4005720d203385e25936e70a42534ac70ac7b`.
Its backend source at `0ae25e38` is identical under `dex/idric/src` to this
patch's base `c1afd27b6b233c5a2b20553463f1487e440d1640`; the same qualified
frontend is `740bbf2b1d9e811fd00c719c3473eede17ceea3b`.

The initial fixture draft omitted the frontend-required `main` and failed with
`Undefined name main`; an inert `pure ()` main corrected that fixture error.
The final checked source then reached the intended map boundary: the logical
name header exited 1 with the exact diagnostic retained in `before.txt` and no
candidate DEX. The property form exited 0 without source diagnostics and emitted
the bytes recorded by `property-baseline.sha256`. This is actual source
generation evidence, not a runtime missing-library observation.

The frozen source fixture SHA256 is
`0c294a71f19576f9b7d0b717814258c2f4a134a5448e91eacf4a4023c9a9f9f8`;
the property-map SHA256 is
`8fc82bf80e6672a824bef74222bded56ab815235a31e60b188c099b763e92302`.
The named-header source-generation and independently decoded post-change
checks use the agreed composite driver rebuild; no separate full driver build
was started for this patch.

The changed `NativeContract` module and its three backend dependencies
typecheck through the qualified frontend in a fresh TTC directory. The actual
`LibraryHeaderChecks.idric` program compiles and runs successfully against
those fresh interfaces, covering named/property selection and twelve malformed
header lists. The maintained Grease qualifier parses with the exact retained
runtime and is wired into the existing runtime workflow on both API lanes.

## Composite-driver source qualification

The complete qualifier passes against the composite driver built at
`55870ca`, program SHA256
`9b09ca2c61153b85d02214ea7cd310415c0742a67be5e3cd1ab0173a45348c11`,
and its explicit backend TTC directory. The helper requires that TTC path as
an argument and records the selected NativeContract interface hash; no old
checkout interface or copied private cache supplies the new header API.

Actual checked source emits the native `(I)I` declaration and call, the public
export, and one initializer containing the literal `contract` followed by
`System.loadLibrary`. Independent decoding finds no getProperty/load path in
that initializer. Repeated named candidates are identical with SHA256
`65c6710d49cc1ba0d92116db3b231e534e5dbde786c3ec62d8a3ee9acecec48a`.
Changing the map's logical name changes the decoded literal and candidate
SHA256 to `12f4eb33aad091f9e308604483283ef8b3d79124216a983f741157594fcc171c`.
The property candidate remains exactly the frozen `b691e906...` bytes.

All twelve actual malformed/duplicate header cases exit exactly 1 with the
expected map diagnostic and no candidate DEX. Exit statuses are retained
individually. While adding that stricter status receipt, an intermediate
qualifier incorrectly supplied a typed argument to external printf; the exact
Grease runtime refused it. Quoted ordinary arguments correct that helper, and
the final complete qualifier passes. This was a qualifier error, not a loader
or language fallback. APK/ART loading and physical execution remain unobserved
by this fixture; source generation and initializer decoding establish only the
new checked loader path.
