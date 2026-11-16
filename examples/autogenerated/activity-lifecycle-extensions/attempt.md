# Exact normal Activity lifecycle forwarding

## Type sketch before implementation

The new isolated `compiler/normal-activity-lifecycle` worktree starts at
`0ae25e38a35e829197644cecf8ec2d63935c0705`. The checked application probes have
already reached the existing lifecycle whitelist with real source status 1;
this work extends that whitelist rather than changing their source types or
substituting a raw application plan.

Required source handlers are:

```text
pause : ActivityReference -> IO ()
save_state : ActivityReference -> BundleReference -> IO ()
activity_result : ActivityReference -> Int32 -> Int32 -> IntentReference -> IO ()
destroy : ActivityReference -> IO ()
```

Each reference is a checked external source domain mapped to the exact SDK
descriptor. All callbacks return Unit/void. The bridge forwards its actual
Activity receiver and every original platform argument, including an unchanged
possibly-null Intent. Null classification and source exception handling are
outside this callback slice.

The existing `override EVENT SIGNATURE handler` contract remains parent-first.
New exact admitted forms are onPause()V, onSaveInstanceState(Bundle)V and
onActivityResult(I,I,Intent)V. Existing create/new-intent/resume/destroy forms
and receiver-only onCreate compatibility retain their behavior.

Proposed explicit source-order form:
`override before-parent onDestroy ()V handler`. Only this exact lifecycle
admits source-first order. It invokes the checked source handler and then the
real Activity superclass method before returning. If the source handler throws,
normal control flow never reaches super, matching original MainActivity's
close/shutdown followed by super; no finally/catch mechanism is invented.

Expected incoming words after one local scratch register: onPause uses this at
v1; onSaveInstanceState uses this at v1 and Bundle at v2; onActivityResult uses
this at v1, requestCode at v2, resultCode at v3 and Intent at v4. Both parent and
source must receive those exact registers and descriptors. Duplicate lifecycle
declarations, wrong signatures, missing/wrong source receiver/arguments/result,
absent superclass and source-first declarations for other methods must refuse.

The first qualification is typed source checking and host execution of the real
Callback planner/finalizer/encoder, including order and refusal controls. A
heavy DEX-driver build requires coordination. Actual checked source generation,
independent decode and installed framework lifecycle observation remain separate
gates. Direct calls on unattached Activities are not lifecycle acceptance.

## Results

The coordinating agent approved the exact three new events and explicit
onDestroy-only before-parent form before implementation. Only Callback compiler
source changed; the independent nullable-reference and library-loader owners'
Foreign/IR/Heap/NativeContract/Codegen paths were not edited.

The actual retained frontend successfully checked the changed Callback and its
three local source dependencies. The exact extended host suite passes all 32
forwarding/order/refusal cases, including finalization and binary encoding of
all four new forms. The existing ten zero-argument lifecycle cases also pass.
The reproducible `verify-plans.grease` invocation passed with receipts under
`/workspace/scratch/38fef1ec20fc/lifecycle-extension-plans-verified`.

The first host run used multiple module search directories and selected the old
Callback TTC, so the positive new-event cases correctly failed. The verifier
now constructs one isolated module overlay, copies the freshly checked Callback
there and byte-compares it before compiling host plans. This removes the
ambiguous lookup rather than interpreting old-code negatives as qualification.

Both new Grease helpers parse through the coordinating agent's exact retained
runtime. All four actual source fixtures pass frontend checking; the plain
frontend records its expected unknown-DEX-generator annotation warnings, and
does not thereby validate callback metadata. `verify-source.grease` prepares
four real source candidates, identical
repeats, independent decoded superclass/source ordering, eight checked source
refusals with seeded stale DEX, and a changed destroy-behavior candidate for
the installed independent framework observer. Actual source-to-DEX qualification
is pending a coordinated rebuilt driver; no full driver build has run here.
Framework lifecycle and physical execution remain pending.

## Language work

The intended addition is only bounded callback metadata and verified typed-plan
construction. No foreign descriptor, nullable-reference owner, JNI, source
effect, renderer or packaging change is selected.

## Combined-source continuation

The rebuilt composite driver emitted Pause and SaveState candidates, then the
actual Picker source refused with `DEX format 22t integer branches require
registers v0..v15`. The shared placement pass already knew how to legalize
high integer branches, but its initial staging decision considered only other
instructions. A branch-only method could therefore bypass that pass.
The generic staging decision now includes both integer-branch operands.
Host controls retain unchanged low-register placement and exercise the nibble
boundary plus high incoming parameters with no invocation to trigger staging.
The picker also uses the separately checked reference-null intrinsic so this
fixture does not acquire an API24 Objects.isNull dependency. Rebuilt source
qualification and installed framework lifecycle execution remain separate.

After placement was corrected, the real receiverless-pause refusal exposed
another boundary defect: an IO Unit export optimized to `pure ()` selected the
automatic command path and silently discarded its explicit Activity/override
declarations. Its emitted superclass was Object and it had no onPause method.
Explicit extends/activity/override/callback metadata now excludes automatic
command selection, so these programs go through the existing checked adapter
validation. Ordinary command and JNI-only command selection remains unchanged.
The same source qualifier requires the intended receiver-signature rejection
and deletion of a pre-seeded stale candidate.
