# Opaque SDK Object arrays and explicit Text upcast

## Type sketch before implementation

This isolated worktree starts at published combined backend
`55870cace37d3920008f325553ce8e152bcf95a1`. The current application probe for
`Resources.getString(I[Object)String` typechecks but its real DEX driver refuses
the previously unsupported reference-array descriptor. This slice preserves
the resource format strings and Java formatting semantics.

The only new array descriptor is exact one-dimensional `[Ljava/lang/Object;`.
It maps a concrete checked external source domain such as `FormatArguments` to
an opaque SDK array reference. Ordinary source Lists/ADTs do not become arrays;
different array descriptors, nesting, array indexing and new-array instructions
are not added. Existing `ArrayList` construction, boxed scalar factories,
explicit reference upcasts and `ArrayList.toArray()` produce the actual array.

Central source signatures are:

```text
new_arguments : PrimIO ArgumentList
add_argument : ArgumentList -> ObjectReference -> PrimIO Int32
arguments_array : ArgumentList -> PrimIO FormatArguments
box_integer : Int32 -> BoxedInteger
integer_object : BoxedInteger -> ObjectReference
text_object : Text -> ObjectReference
resource_format : ResourcesReference -> Int32 -> FormatArguments -> PrimIO Text
```

For Text, the only new cast form is explicit
`dex:cast:Ljava/lang/String;:Ljava/lang/Object;`, with checked source Text and a
concrete external Object result domain. The parser forces both descriptors;
there is no source CFString claim for an arbitrary class and no implicit
Text-to-Object method argument. Existing reference move/checkcast lowering is
reused. Resource formatting receives actual boxed Integer/Long and String
objects, so positional numeric and `%s` resource conversions stay platform-owned.

Admitting Object[] to the shared descriptor parser exposes a pre-existing
assumption in NativeContract: legacy array refusal recognizes only [D/[I.
The coordinating agent approved changing that refusal guard to recognize every
array descriptor. Object[] must remain refused by legacy, explicit scalar,
copied-input and output-array JNI contracts. No native array ownership policy
is broadened.

First qualification is source checking and host execution of the actual parser,
domain constraints, managed bridge, finalizer and encoder. Actual source
generation must exercise ArrayList.toArray, explicit Integer-to-Object and
Text-to-Object casts and Resources.getString's exact signature; ordinary,
conflicting and unsupported domains/descriptors must refuse. Heavy driver
builds wait for coordination. Resource-backed ART/Activity execution remains a
separate gate; no English text or manual `%1$s` substitution is a fallback.

## Results

Contract approved before implementation. The bounded Foreign edit typechecks
and the real `FormattedResources.idric` source typechecks. It uses actual
ArrayList.toArray and Resources.getString for rendering, completion and error
statuses; no reflective array allocation or manual format-string replacement
is selected.

A fresh NativeContract dependency check exposed an inherited combined-source
blocker: Lower's foreign-operation case omits the three managed exception
operations already present in ForeignOperation. The checker reports
`lower_foreign_call is not covering`, followed by dependent lowerer functions.
The coordinating agent was informed before any change to that separately owned
path. The partial check must not count as complete backend source acceptance.

The two changed source modules were then independently checked against the
supplied compiled dependencies. The reproducible `verify-plans.grease` unit
qualifier passes: exact descriptor/domain rules, the explicit Text cast and
its refusals, shared managed bridges, finalization/encoding, Object[] refusal
under every existing JNI array/scalar policy, and the inherited copied-array
contract suite. Receipts are at
`/workspace/scratch/38fef1ec20fc/sdk-object-array-plans-verified`; they explicitly
record a complete backend build as NOT_RUN.

The final formatting source typechecks. The independent Smali observer
assembles, SHA256
`ff4b54990b1f22364fc8183063761d366dd52d84e58247a1a5697ee25fc256df`.
Its positional-format, repeated-argument, padding/hex, negative/boundary Int32,
wide elapsed-time and literal-percent Text cases use actual platform formatting.
It also invokes all three source Resources wrappers against a real framework
resource, comparing its unformatted text. Application resource-format contents
are a separate installed-Activity observation, not supplied by that plain
framework-string check. The source qualifier preserves seven actual refusal
controls and a compiled argument-order mutation for subsequent execution.

Fresh full-backend checking, source-to-DEX generation/refusals, ART and actual
application resource/Activity behavior remain PENDING. No heavy driver build
was started in this checkout. The inherited Lower missing-exception cases must
be resolved by its owner for a fresh coherent backend check.

## Language work

The bounded requirement is an opaque SDK Object[] reference and an exact safe
Text-to-Object upcast. General reference-array operations, ordinary source
array representations and JNI reference-array transfer remain outside it.
