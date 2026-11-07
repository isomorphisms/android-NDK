# Checked long-jump stress fixture

## Type/effect sketch before implementation

The input is runtime `Text`; the output is an `Int32` flag. A pure checked
foreign call to Android's `String.indexOf(String)` observes whether each of
24 distinct markers occurs in the input. Empty input and any marker return 0;
a nonempty input without markers returns 1.

- `index_of : Text → Text → Int32` uses the established checked managed call.
- `layout_long_jump : Text → Int32` contains the branch stress directly,
  without a user helper that normal compiler factoring can shorten.
- Each marker condition depends on runtime input; compile-time evaluation
  cannot decide the branch chain.
- Expected results are independently asserted by an external ART observer.
- The original `LayoutText.idric`, its exports and existing observations
  remain unchanged. Its smaller code after helper discovery is valid.

The host gate must find a genuinely promoted `goto/16` or `goto/32` in the
candidate's finalized plan and independently decoded output. Source plan,
smali and decoded instruction words must agree. This fixture complements the
existing synthetic finalized-plan edge controls rather than replacing them.

## Observed regression and repair

The framework run `40161319217`, job `121073301186`, stopped at
`verify-effects.grease`'s old requirement that `LayoutText` contain `goto/16`.
Checked helper discovery now factors that fixture's `absent` calls into
separate methods. The source still compiles; its lack of a long branch is not
evidence of a semantic failure. The original fixture and its exports were
preserved byte-for-byte in source.

This dedicated fixture uses direct foreign calls in a single checked function.
The production compiler emitted a 2,912-byte candidate with a genuine
`goto/16`, independently decoded by baksmali with target `:goto_397`.

Local verification used the final native backend and checked frontend
`740bbf2b1d9e811fd00c719c3473eede17ceea3b`:

- Checked source → direct DEX emission: PASS.
- Repeated compilation into separate build/output directories: byte-identical.
- Independent baksmali 3.0.10 decoding and promoted-branch observation: PASS.
- Independent smali 3.0.10 assembly of the compiler's readable output, followed
  by baksmali decoding: its complete decoded class equals the candidate's
  decoded class. The oracle never supplies candidate bytes.
- External observation runner assembly: PASS. It checks empty input, an absent
  marker, early/middle/late markers, a marker substring, and non-BMP input.
- Grease parsing of all three changed qualification scripts: PASS.
- Full AOSP dexdump comparison and ART execution: NOT_RUN locally; the hosted
  framework lane now includes this candidate in its existing checks.

Candidate SHA-256:
`811d2cb5e0c6c5e689eb42e7ee3cdb5a39f8c4bee93cfc5fa271bf61558e4e7c`.
Observer SHA-256:
`47f4d305e7588552f8221d1c76e2ba848008efdbaea01f05c952b5415cc12c71`.

`verify-effects.grease` requires a widened jump in both the new finalized plan
and AOSP-decoded bytes. `verify-layout.grease` retains exact instruction-word
comparison and applies a jointly stale-plan/smali control to this real source
as well as the existing synthetic edge fixture. `verify-effects-art.grease`
executes the new independent observer without changing the existing runners.

Remaining boundary: hosted exact-source AOSP comparison and real ART execution.
No compiler implementation or ICU acceptance code changed in this repair.
