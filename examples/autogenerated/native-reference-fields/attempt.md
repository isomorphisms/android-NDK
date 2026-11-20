# Native reference fields for the Shizuku boundary

IB's app-owned Shizuku provider must receive the maintained
`moe.shizuku.api.BinderContainer` Parcelable. Its `binder` is an instance
reference, while its `CREATOR` is static. Encoding both as static would share
capabilities across instances and change the wire container's semantics.
Retain that representation rather than replacing it with an unrelated map.

The required compiler slice is a declared public/private instance reference
field alongside the existing static references. It does not admit primitive
fields, source-level unchecked field operations, invalid descriptors or mixed
access flags. The old static declaration API remains compatible; static access
instructions still require a declared static field, never merely a matching
name in the instance set. ART initializes each instance reference independently.

`NativeReferenceFields.idric` uses the maintained typed class/DEX writer. It
emits a positive class and a field-kind mutant, checks deterministic declaration
ordering and rejects duplicate, invalid-flag, primitive, malformed-array and
static-to-instance access declarations. Candidate DEX is not assembled from
smali. Independent reflection on real ART must reject the compiled field-kind
mutant before this slice can qualify the actual Android provider.

Protocol reference: RikkaApps/Shizuku-API
`a27f6e4151ba7b39965ca47edb2bf0aeed7102e5`,
`provider/src/main/java/moe/shizuku/api/BinderContainer.java`.
This binding prerequisite is not evidence of an app-owned Binder transaction,
Shizuku authorization, a working reader, or physical TAB_P10 acceptance.

The frozen pre-repair generator at 0f9b6e1 exits 1 with
`DEX static field declaration must be public/private static reference`.
The repaired writer emits a 540-byte positive class and an independently
decoded field-kind mutant. Local generation, declaration-order determinism
and the five refusal controls pass with frontend 740bbf2b1, whose local native
support uses qualified ICK c61e4482. Fresh API 29/34 reflection is required and
is owned by ai-ci 821a95c5; it is not replaced by the host decoder.

That checkpoint `6c1ebcd14c8d1d1736fdf088db7c6de2ec6a09c5` passed API 29/34
reflection and the static-field control in run 41245527257. The subsequent real
IB provider declarations exposed a different shared-writer defect: an empty
interface list reused the previous class's nonzero interface offset. The
provider consequently decoded as implementing DeathRecipient. Resetting only
the per-class offset to zero preserves the shared type-list data and map.

The extended consumer places a Runnable class before a plain class and checks
declaration-order determinism. With the frozen prior TTC writer, independent
decode exits 1 with `FAIL empty class inherited another class interface list`.
The repaired writer must emit no interface for the plain class; ai-ci separately
reflects the two classes on ART and rejects an otherwise valid, compiled
interface-list mutant. Existing field controls remain mandatory. These mixed
class declarations also cover the real provider; they do not implement or
simulate Shizuku authorization.
