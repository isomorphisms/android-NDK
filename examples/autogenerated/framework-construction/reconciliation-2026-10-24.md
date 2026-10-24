# Restore the qualified Material reader construction path

The canonical reconciliation at 5e57a4d974e73fe5ba3914354869fad761c014df
retained the checked create/action Activity adapter and reference casts from
78522f32576b7c14f138a875c0c572f8243dc2eb. The separately qualified sibling
8040820ebd06e7441aab244ee7e62e727919c764 supplied `NewObject`, the checked
`dex:construct` operation, and `extends`/`override` lifecycle declarations.
Those construction capabilities were absent from the reconciled package.

This continuation recovers that implementation and its fixtures rather than
rewriting the Material screen or substituting XML inflation. The existing
discriminated foreign-operation representation now also carries a checked
constructor operation. Both lifecycle declaration surfaces feed the existing
common typed encoder. Mixed declaration forms fail instead of creating two
onCreate methods. Native class flags, JNI metadata, casts, scalar helper calls
and the create/action adapter remain covered by the existing regression suites.

Construction retains explicit IO, the checked external owner and argument
domains, a void JVM constructor and an initialized result reference. The
backend emits allocation followed by invoke-direct and preserves high-register
placement. Array allocation through new-instance is rejected independently.

## Executed local evidence

- Frontend source: 740bbf2b1d9e811fd00c719c3473eede17ceea3b. Built through the
  existing Chez compiler path from the exact Cat Food Linux x86_64 bundle
  94dfd99bd3e376507fedc8611053b7173b2519f0, archive SHA-256
  0be57deab9410e8d4c09c7198bf7e8ee0ec3e24121f76640147efa4a53d120da.
  This reuses its native host support library; no new native compiler bootstrap
  or independent producer promotion is claimed.
- Actual compiled Grease: binary SHA-256
  7e31cd05b7a9d8fb2a4a9e003a7f3fcb0159138506d17f0fb28da8cbe22aa85c,
  source 5651cf97a1b5042f24f14112a7ade9a1518eb0bc.
- Twelve canonical host suites PASS, including cast/Activity/callback, source
  loop/string, shared class/JNI metadata and independently decoded outputs.
  Both source-ownership mutants are rejected.
- The restored constructor suite passes typed construction/lifecycle controls,
  separate source checking, seven fresh checked-source compilations, wrong-name
  and nonvoid source refusals with exit 1/no DEX, independent baksmali decoding,
  three reader-source mutations and byte-identical recovery. Actual production
  mutations removing allocation staging or dropping the superclass Bundle are
  each rejected by their intended host control.
- The unchanged Material screen at IB
  8b6a1694ffb168f5e206262eeee89830d0733194 emits DEX SHA-256
  b2ce30b0af52bc52beffd167fcbac331d447eeb7ac4a13db0e068662be2d0c17.
  These are exactly the earlier qualified screen bytes. It remains a pinned
  snapshot screen, not a real URL reader.

The first local attempt started source execution before the new driver finished
linking its Chez object and failed with Permission denied on that incomplete
file. Another attempted allocation mutation was masked by a high-register cast
that independently requested staging. The corrected control puts the cast in a
low register while retaining the high allocation; the mutation is then rejected.
Neither earlier failure is relabeled as a pass.

## Remaining product boundary

The unchanged NativeSourceProjection consumer from IB
912ae8905ae137868ce6e9aff1a82c915c40ee85 was compiled against actual current main
source 0f3d8dcdc20239987ce30da3d27788a90d2c090a. With the rebuilt backend it still
fails with exit 1 and no reader.dex:

`DEX unpack cannot reinterpret a source object as an integer: source constructor _builtin.NIL in checked helper IB.Information.tokenize_chars`

This recovery does not implement the constructed lists, records, non-tail
helpers and required runtime primitives of that program. It does not prove
canonical source projection, real ICU acquisition, the joined reader pipeline,
links/Back/restart, a new APK, or physical C67 behavior. Fresh current-head CI
and ART evidence remain separate from these local host results. The original
October 14 ART/instrumentation receipts are retained as historical evidence.
