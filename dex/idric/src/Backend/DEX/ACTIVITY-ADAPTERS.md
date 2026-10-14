# Checked Activity and text-view adapter

`%cg dex activity create_export action_export` selects a bounded Android
Activity shape. The checked create export must accept Activity and return
IO (); the checked action export accepts Activity and View and returns IO ().
The emitter generates an Activity-initializing constructor, onCreate(Bundle)
which invokes super.onCreate before the checked create body, and onClick(View)
which forwards both the Activity receiver and actual clicked view.
Missing, ambiguous, malformed or mismatched declarations refuse emission.
At most one Activity declaration belongs to a class. Ordinary interface
callbacks retain their implicit listener receiver exclusion.

The superclass is explicit FilePlan metadata shared by finalized binary,
plan and smali emission. InvokeSuper has separate compact/range opcodes.
MkFilePlan still defaults to Object; the explicit MkClassFilePlan record
constructor now includes a superclass field.

`dex:cast:SOURCE_DESCRIPTOR:TARGET_DESCRIPTOR` accepts one checked external
domain and returns another. The compiler proves both domains external, binds
their distinct descriptors, emits an object move and Android check-cast,
and retains runtime cast failure. It cannot reinterpret an integer, source
sum or ordinary constructor as a framework object. Placement stages casts
whose register exceeds the opcode's byte-sized register field. The encoder
uses actual type_ids, not a string index; missing/malformed target types refuse.

Checked Text inputs may widen to platform CharSequence because their existing
representation is java.lang.String. A CharSequence result is a distinct
external domain and cannot be declared Text. ForeignOperation distinguishes
MethodInvocation from CheckedReferenceCast; MkDEXForeign remains the ordinary
method-call construction helper.

Views are constructed by application-owned Android XML/resources. No source
object factory, captured listener field, arbitrary source heap representation,
store, parser, worker, browser policy or JNI path is introduced.

Local qualification: 16 Activity/cast/text-boundary assertions, the existing
10 interface callback assertions and the compatibility foreign-convention
suite pass. Actual ActivitySource.idric emits DEX. The IB-owned reader also
emits DEX independently parsed by AOSP dexdump, links its declared resource
IDs and packages under the existing test signer.
These are host/source/encoding/packaging observations. ART lifecycle, native
click/text behavior and physical C67 replacement installation are NOT_RUN.
The inherited Chez compiler bootstrap remains unqualified producer debt.
Compiler source: Idriç 2734ac5a86610eddfab73b1644d72b4ac85a65ee.
No earlier ff4 receipt is reused.

The actual IB retained-source title consumer rejects with
`DEX tail-loop parameter needs a supported first-order runtime representation`.
Next language work: a checked runtime representation for its existing source
collections, followed by source-to-DEX/ART execution of that exact consumer.
