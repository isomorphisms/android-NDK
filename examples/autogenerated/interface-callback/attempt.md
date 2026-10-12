# Program attempt: checked source behind a platform interface callback

Purpose: remove IB-D01's inbound click barrier without moving action semantics
into Java, smali, C or an alternate compiler. Continue the existing checked
DEX backend at `d0080ff0ad938680d319519bf484f98f540d3e89`.

## Type-system sketch

An interface callback declaration names an interface descriptor, virtual method,
declared JVM signature and existing checked static export. The signature must
equal that export's validated source ABI. The initial bridge admits void
callbacks only and carries no closure, captured state or new retained model.
Its mechanical instance method forwards declared arguments to the checked
static body. The generated class implements the declared interface and has an
Object-initializing constructor. An implicit receiver occupies its own incoming
register word; it must never be forwarded as the source's first argument.

Keep the existing static file/method constructors available for prior consumers.
Add explicit method mode and class interface metadata to the same finalized
plan used by binary emission, textual plan and smali observation.

## Intended acceptance

Source checking and fresh checked DEX must precede runtime claims. Exercise
successful callback dispatch, wrong signature, missing checked export and
wrong receiver/argument forwarding. Independently parse emitted DEX and match
its direct/virtual class data, interface list, constructor and incoming words.
An external Android observer may construct and click a real view; it must not
implement the candidate callback. A source-mutated callback must fail the same
observer. Preserve producer status and exact input/artifact identities.

## Execution boundary

Status: SOURCE_ATTEMPT. The exact Idriç core
`ff4d852862a3942592f8ade9afde8d409d9803be` is currently bootstrapping here.
Its C support uses NDK r29 host clang. The inherited Chez bootstrap is checker
construction, not IB's selected Android runtime. Existing bootstrap debt is
not promoted to consumer build-policy acceptance. DEX/ART/APK/Material and
physical-device results remain NOT_RUN until independently observed.

Fallback: none. Unsupported callbacks must refuse in this backend rather than
retry Java, RefC or a handwritten implementation of the source action.

## Initial checking receipt

The pinned core's inherited bootstrap checker `0.8.0-1b5176dc9` checked all
eleven DEX backend modules through `Backend.DEX.Codegen` (exit 0). This is a
compatibility source check, not the rebuilt ff4 checker or DEX execution.
Earlier checks caught a reserved `parameters` binder and the missing new
InvokeDirect case in foreign argument classification. Both were repaired;
the subsequent full source check passed. No failing attempt was called a pass.

The two Grease verifier files parsed (exit 0) with the preserved actual Grease
fork's documented implementation entry at Oils
`5651cf97a1b5042f24f14112a7ade9a1518eb0bc`, binary SHA-256
`7e31cd05b7a9d8fb2a4a9e003a7f3fcb0159138506d17f0fb28da8cbe22aa85c`.
Calling the raw historical binary by a new `grease` basename refused with
`Invalid applet 'grease'`; it was not an execution pass. Parsing used that
fork's existing entry inside the Grease/Oils boundary. The application/CI
interface remains Grease. Host assertions and ART are still NOT_RUN here.
