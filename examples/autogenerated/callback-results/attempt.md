# Checked callback results and an explicit Activity receiver

## Purpose and type sketch

Continue the existing checked direct-DEX normal-Activity route. The first real
UI blocker at source `daa6d66` is that callback declarations reject every
nonvoid result and their bridges unconditionally discard the checked result.
This prevents Boolean touch/long-click handlers and object-returning inset
listeners even though checked source exports and DEX instructions already
represent those values.

- `InterfaceCallback` retains the exact platform interface, method descriptor
  and checked static source export. One explicit flag requests the Activity
  receiver as the first source parameter; the existing receiverless declaration
  keeps its meaning.
- Callback results admit only the previously supported void result plus Boolean,
  Text and non-array object references. Wide, floating and other unqualified
  result forms remain explicit refusals in this slice.
- The public instance bridge preserves the platform parameters/result, imports
  this call's actual arguments, invokes the exact checked export, and returns
  its actual result with the matching DEX return instruction. No fixed result
  value or native/JNI callback body is substituted.
- `%cg dex callback receiver INTERFACE METHOD DESCRIPTOR EXPORT` requires the
  existing checked Activity superclass. The source signature must be exactly
  Activity followed by the platform parameters, with the exact platform result.
  The ordinary declaration does not acquire an implicit receiver or capture.

This does not add general object fields, listener closures, captured requests,
private callback object allocation, lifecycle methods or application state.
The qualification uses two distinct Activity instances and their existing Intent
properties solely to prove delivery of the actual receiver. It does not select
Intent as an application's state representation. Application UI state, formula
editing and rendering stay application-owned.

## Required observations

Compile actual Idriç handlers through the managed DEX path, independently decode
their Boolean/reference callback descriptors and move-result/return instructions,
then exercise real framework listener dispatch on ART. Boolean inputs must reach
both false and true branches; reference cases must preserve object identity or
return the actual checked framework result as selected by the handler. Two
receivers with distinct Intent actions must remain distinguishable.

Host plan checks must preserve receiverless behavior, verify the explicit
receiver's register, and reject missing/wrong source signatures, unsupported
result forms and receiver use without the checked Activity parent. Targeted
compiled source mutations must be rejected by the unchanged independent
observer. Source/generation/ART evidence remain separate.

## Source and observed checks

`Callback.idr` now preserves the exact checked result, returning it with the
appropriate Boolean/reference instruction. The explicit receiver form requires
the selected Activity superclass and an exact Activity-first source signature;
the ordinary declaration retains its previous argument/register behavior.
Paired argument placement also accounts for the existing Long/Double widths.

All 21 backend modules and the driver rebuilt with the exact retained
frontend740bbf2b1. The new 14-case typed-plan host program and the existing
10-case receiverless/void host program both executed successfully. Standalone
host checks explicitly select the installed `idris2` API package; this is a
compiler-plan test dependency, not a candidate runtime.

The actual checked `CallbackResultSource.idric` emitted a 5588-byte direct DEX.
Independent baksmali decoded the Activity parent, both Android interfaces,
the actual receiver/argument calls into the checked static exports, and
`move-result`/integer return plus `move-result-object`/reference return. A repeat
build produced identical bytes. Candidate SHA256:
`89c13f7aa419f97a2b7bc1f79f0032bcf1d4fa75b3fddc9b7b7df3939e32e771`.

Both actual source mutations generated and decoded, with different bytes:
Boolean mutation
`31e0db1008b55c7ea722cb3d54de756b199d1f5087aa7a38f0522e0743ce599e`
and reference mutation
`72a3898bb03d2a0a4c89ef1057108d33659193a39ee4577d01e7aab928b6151b`.
The independent observer assembled as
`6ab65544c10b7131c1578b5eabfd3981c0f5d34d9ddb5ec3b454fac0c33703de`.
Missing export, wrong result, undeclared implicit receiver, receiver without
the Activity parent and array result all refused with their intended callback
diagnostic, exit1 and no candidate DEX.

Both new Grease scripts parse through the actual retained pinned runtime. The
workflow reuses the existing runtime-repair setup and API29/API34 emulator
matrix; it retains the original regression work. Full scripted hosted
execution and ART observations remain PENDING. A separate read-only review
found no concrete descriptor, register, receiver or result defect; source review
does not replace those target observations.

The fixture follows the Android platform contracts for
[OnLongClickListener](https://developer.android.com/reference/android/view/View.OnLongClickListener)
and [inset listener dispatch](https://developer.android.com/reference/android/view/View#dispatchApplyWindowInsets(android.view.WindowInsets)).
The observer supplies a nonempty inset value, requires unchanged identity on
the keep path, and requires the actual consumed reference on the consume path.
Unexpected platform exceptions remain failures rather than designated mutation
rejections.

No final Activity, APK, framework editor, private captured state, renderer or
physical-device acceptance is inferred from this compiler slice.

The first hosted API34 run at `d2651550...` failed with retained exit 137 and
only `Killed` in the callback output; its exact first Throwable was not retained.
See [failure-d265.md](failure-d265.md) for the source/artifact identity, bounded
conclusion and diagnostic repair. Neither this failure nor its cause is hidden
by the earlier local emission/host-plan results.

The diagnostic rerun at `d9819ca0656c0f4ea4b7a520c423b32eba248549`
retained exit92 and the same first Throwable on API29 and API34:
`View.performLongClick` falls through to `showContextMenu` when the checked
handler correctly returns false, but the observer's Button had no parent.
The resulting null `ViewParent` exception is a fixture defect. The independent
observer now attaches the real Button to a FrameLayout whose context-menu
methods return false. It still registers and dispatches the actual generated
listeners through the framework, and the unchanged positive/mutation checks
still require their actual Boolean/reference results. No candidate code or
callback result is replaced by this observer repair. Repaired ART execution
remains pending until the exact new head runs.
