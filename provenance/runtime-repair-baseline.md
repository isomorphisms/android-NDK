# Runtime repair baseline reconciliation

This local integration joins managed-runtime head
`973c24bc0b4eab6f3c88699102f7cb0e7fd8951f` and pre-ICU main
`1483366e4af156b816c2923fc75d02e2b360eb67` on an isolated repair branch.
It does not change either source branch or merge anything into main.

## Source reconciliation

- Retain the managed head's canonical `IR`, `Encode`, `Invoke`, `Placement`,
  `Smali`, `FrameworkClasses` and adapter encoder modules. They already
  include the pre-ICU features while replacing the earlier duplicate writers
  with shared typed plans. Main's older module copies would remove static
  fields, multi-class encoding, managed arguments, native methods and throw
  instructions.
- Preserve `ObjectConstruction` as the canonical checked operation and add
  main's public `construction`, `foreign_argument_types` and
  `foreign_result_type` compatibility views over it. No second constructor
  representation is introduced.
- Preserve managed graph/helper discovery and the checked runtime/JNI path
  alongside both Activity declaration forms and framework construction.
- Retain main's additional mixed-Activity refusal controls, native callback
  hostile-plan controls, their attempt records, the baksmali provisioning
  step, packaging changes, native callback package workflow and pre-ICU
  receipt/inventory.
- Preserve the managed head's stronger construction source controls and
  unchanged Material-screen qualification. The main tests for these paths
  are retained where independently useful rather than replacing the checked
  constructor operation with the older invocation tag.
- Retain both ownership/reconciliation and pre-ICU inventory documentation.

No ICU source, transport, observer, or expected result is changed by this
baseline reconciliation. Source qualification and physical-device evidence
remain separate from the retained historical records.

The pinned checked frontend used for local verification is
`740bbf2b1d9e811fd00c719c3473eede17ceea3b`. Later runtime feature changes and
their acceptance belong in separate commits and receipts.

## Local checks before the reconciliation commit

- Fresh backend package build and executable startup: PASS.
- All 14 suites in `verify-reconcile.grease`: PASS, including the merged
  Activity refusal controls and independent shared-class/argument decoding.
- Source-ownership self-test, including both deliberate boundary mutations:
  PASS. An initial invocation lacked Grease in PATH; the corrected explicit
  host environment passed.
- Checked construction/lifecycle controls and independent decode of the
  high-register constructor fixture: PASS.
- Main's checked native View callback fixture, hostile-plan refusals and
  independent decode of both callback classes: PASS.
- Fresh ART/JNI execution, package delivery and physical-device acceptance:
  NOT_RUN by this baseline reconciliation.

All these checks use the combined working tree, rather than claiming that
either parent's historical green results qualify the new integration.
