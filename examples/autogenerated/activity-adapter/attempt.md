# Checked Activity adapter

Purpose: remove the first-party Java Activity requirement from IB's frontend.
The existing checked callback emitter supplies stateless interface forwarding,
but cannot extend an Activity or pass its receiver to a checked source body.

Types: a checked external Activity reference and Bundle reference enter a
source export `ActivityReference → BundleReference → IO ()`. An Android view
reference enters a checked action export with the Activity receiver. These are
platform references, not browser tasks or source records. A cast between two
external view domains must emit Android's checked runtime cast and may fail.

Invariants: one declared superclass; matching source/Android signatures;
super.onCreate before the checked create action; an inherited superclass
constructor; no semantic logic in the bridge; no Java, javac, Gradle, d8 or
handwritten candidate DEX. Existing interface callbacks retain their receiver
exclusion rule. Invalid or ambiguous declarations refuse DEX emission.

Target: the existing pinned checked ANF -> DEX plan -> direct byte emitter.
Host plan/source checks, independent DEX parsing, ART dispatch, APK packaging
and physical C67 behavior are separate evidence. The inherited compiler
bootstrap has not acquired ICK/NDK producer qualification through this work.

Required language work: superclass metadata, explicit receiver forwarding and
invoke-super; checked external-domain casts. XML/native framework views remain
application-owned. No browser model, store or serializer is introduced here.

Implemented: an explicit Activity superclass; inherited initialization and
receiver forwarding; invoke-super; checked external-domain casts; Text input
widening to CharSequence with explicit refusal of the reverse result claim.
XML/resource view construction stays application-owned.

Actual local verification uses Idriç
2734ac5a86610eddfab73b1644d72b4ac85a65ee and its installed bootstrap modules,
including Network/Linear needed by the compiler API. The two initial driver
attempts failed at an ambiguous bootstrap elaboration and then an absent
Network.Socket.Raw import path. Those failures were corrected; neither was
counted as DEX acceptance. The built driver, 16 Activity/cast assertions,
10 existing interface callback assertions and foreign-convention suite pass.
ActivitySource.idric and IB's real NativeReader.idric emit fresh direct DEX.
AOSP dexdump checksums/disassembles the actual native-reader bytes.

The existing Grease runtime was invoked through its verified consumer entry;
its compiled ELF is an inherited development build. The remaining compiler
bootstrap/producer qualification gap is explicit; no ICK/NDK build-policy
acceptance is claimed. No fallback selected. ART lifecycle/click behavior and
physical C67 are NOT_RUN.

First remaining language capability: checked first-order runtime representation
for IB's existing source collections/records. Its actual retained-source title
consumer typechecks, then fails DEX lowering with the precise tail-loop
representation diagnostic. Execute that original consumer on DEX/ART before
claiming full source recovery or retiring its incomplete-migration blocker.
# Pre-ICU integration

The integration retains both the explicit `extends`/`override` lifecycle form
from framework construction and this branch's `activity` shorthand. Mixing
the two parent/lifecycle ownership declarations fails closed. Both keep the
original Bundle in the superclass call and pass the actual Activity receiver
to checked source. One `FilePlan` and one encoder serve both forms.

`ForeignOperation` remains the tagged call/cast representation. Constructor
calls use its `MethodInvocation InvokeDirect` case, allocate their own receiver,
exclude that receiver from source arguments, require PrimIO and a void JVM
constructor, and return the initialized opaque owner. Compatibility views
`construction`, `foreign_argument_types` and `foreign_result_type` preserve the
constructor checks without inventing a method for a cast. The raw-constructor
test now inspects the tagged operation and still requires a void result.

The encoder keeps the existing string/type argument order, modified UTF-8,
UTF-16 ordering and cast type-pool discovery, and includes `NewObject` in the
same type-pool discovery. Allocation and casts keep their separate high-register
placement rules. Both original fixture families and both runtime suites remain
in qualification; no negative fixture was removed. Two additional controls
exercise conflicting declaration ownership. No fallback compiler is introduced.
Hosted qualification, rather than local parsing, must establish execution.
