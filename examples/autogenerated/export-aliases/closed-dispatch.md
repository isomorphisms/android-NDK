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
