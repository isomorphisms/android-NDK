# Deliver a new Android Intent to checked Idriç

Purpose: unblock IB's receipt of a ChordReader ACTION_SEARCH while its Activity
already exists. This extends the existing checked Activity override owner.

Types: ActivityReference and IntentReference are distinct external platform
domains. The lifecycle bridge receives the actual framework Activity and Intent
and invokes a checked `ActivityReference → IntentReference → IO ()` export.
It must call the parent lifecycle first and preserve both object references.
The checked source explicitly retains the Intent using Activity.setIntent.

`onCreate(Bundle)` retains its existing receiver-only compatibility. A new
Intent handler must accept the Intent argument; omitting it is refused. Wrong
SDK signatures, missing exports, wrong source domains, repeated overrides and
missing Activity superclass must fail before usable DEX is emitted.

The example retains the Intent only to expose an observable platform effect.
Search validation, provider choice, caller authorization, history and network
acquisition remain IB-owned. No application manifest, package or signer changes
belong to this compiler example.

Target: checked Idriç → existing ANF → existing direct DEX encoder → Android ART.
The plan observer runs on the host and is not Android execution. Runtime and
physical acceptance must remain separately recorded. No fallback is selected.

Implemented in the maintained Callback lowerer. Eight host plan checks passed,
including superclass/signature/export/argument and repeated-override refusals.
The actual checked source emitted deterministic DEX, independently decoded
with baksmali 3.0.10. Two independently typechecked source mutations were
refused without DEX at the intended lifecycle-signature checks. The existing
onCreate compatibility remains unchanged.

Frontend: isomorphisms/Idric 740bbf2b1d9e811fd00c719c3473eede17ceea3b.
Compiler base: android-NDK 973c24bc0b4eab6f3c88699102f7cb0e7fd8951f, with
the adjacent maintained Callback patch. Verification used the actual compiled
Grease runtime with leak scanning disabled for its instrumented container
execution. An initial missing frontend support-data path was repaired; a first
negative fixture was tightened after it failed at descriptor discovery rather
than at its intended omitted-Intent check. Both attempts remain in scratch
receipts; the qualified attempt requires the specific refusal diagnostics.

ART, installed Activity delivery, cold/warm APK behavior, C67 and A1 are NOT_RUN.
This removes one compiler limitation; it does not complete IB search. The real
IB receiver-to-google_icu_url attempt still stops at Prelude.Types.fastUnpack
in the framework/scalar lowering path. The separate managed command path is
not an Activity bridge.
