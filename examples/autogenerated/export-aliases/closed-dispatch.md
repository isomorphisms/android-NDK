# Checked closure dispatch for export and pure entry contracts

The installed IB candidate emits a dispatcher containing every reachable
definition, including direct-call definitions that cannot be closure targets.
Actual Android logs report its 21,414 code units exceed ART's JIT limit.
That observation alone does not establish the cause of the reader display
failure. Separate source-readback and main-stack traces are being qualified.

Managed command entries already derive dispatch targets from checked partial
applications across every reachable branch. Public export boundaries admit
scalars and opaque SDK references, never arbitrary managed heap values, so the
same proof applies to managed exports and pure Text entries. Those two plans
now use the existing checked closure-target collector. Direct calls and their
checked methods remain present; closure tag assignments and partial-application
semantics do not change. The undersaturated IO export still applies its World
suffix through that same dispatcher.

The real expanded IB Activity and all maintained consumers emitted and decoded
with this change on the host. The alias fixture and its effect mutant emitted
deterministically; ordinary-data ABI refusal still returned 1 without DEX.
Independent literal expectations and compiled controls on API 29 and 34 remain
required at the changed head. This is a reusable compiler repair, not a claim
that the installed native reader is complete or that its stall is resolved.

Run 41279233397 at b5f673062bb5681c29f70a9ee7c5412b4e8b785c passes
the complete API 34 lane. API 29 did not boot: the runner had 2470.98 MiB free
while the default AVD requested a 7372.80 MiB userdata partition. Its ART
checks are NOT_RUN, not a compiler failure or pass. The runtime fixture now
declares a 2048M userdata disk through the pinned emulator action's supported
`disk-size` input. No candidate, expectation, SDK/API or compiler changes; no
host toolchain or application data is deleted to free space. Fresh execution
must still observe every runtime and mutation check.
