# Reusable checked Idriç → DEX compiler, version 0.2.0

This directory is a standalone Idriç package hosted inside android-NDK. The
compiler owns checked ANF lowering and direct DEX emission. Consumer-native
implementations keep their own semantics and cross explicit JNI boundaries.

Use a pinned Idriç frontend with its matching `idris2` compiler API installed.
The executed frontend is 0e8cfdd1106ebdeffd01b6c519880ea3afc7dc35 with the
Driver error-status repair published at 740bbf2b1d9e811fd00c719c3473eede17ceea3b.
No Java/Kotlin/Gradle/d8 or new refC stage produces candidate DEX.

`backend.ipkg` builds independently with Idriç's `--build` interface. The
Makefile accepts explicit IDRIC, IDRIC_REPO and GREASE paths. Compiler API
installation uses the frontend's idris2api.ipkg, not its executable package.
The copied package's source root is src; nothing requires an ARM backend.

`verify-reconcile.grease` runs host regression and malformed-plan suites.
`verify-sources.grease` emits and independently decodes real checked source,
checks determinism and requires unsupported-source exit 1 with no DEX.
The separate ai-ci observer executes source-generated calls under ART and
rejects a compiled wrong-helper mutation. Host checks do not imply ART or
physical-phone acceptance.

See RECONCILIATION.md for source ownership, provenance, implemented behavior
and the precise real ICU blocker. Source and dependency pins, executable DEX
identities and evidence categories live in reconciliation-receipt.tsv.
