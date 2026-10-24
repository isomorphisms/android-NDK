# Checked unpack-derived character views

This candidate continues android-NDK #22 / Flexible Pipes #76, stacked on the finalized-layout repair in PR #23. IB storage, task records, serializers and browser source are unchanged. It extends the existing DEX compiler using checked ANF, not a source recognizer or a separately implemented validator.

## Scope

The pinned Prelude's actual foreign declaration `fastUnpack : Text -> List Char` is validated against its checked CFTypes and pinned conventions. The compiler represents its result as original text, a runtime array of code points, a position and a length. Android `String.codePoints()` and `IntStream.toArray()` require API24; the qualification target remains Android14/API34. Array head access uses the platform reflection primitive; tails advance a private position without copying. The array is never exposed or mutated by generated source operations.

`fastPack` supports views/suffixes of that original unpack and an empty list. Reconstructing the exact observed head and tail preserves the original view only when register provenance agrees. Arbitrary constructed lists, escaping List ABI, unknown runtime closures and mutual/non-tail recursion remain errors.

Direct checked self-tail calls use loops with fresh private parameter registers and staged simultaneous argument assignment. Record/Maybe constructors and known closures are specialized only while their shape is known. Constant Integer arithmetic remains exact during compilation; this does not implement dynamic arbitrary-precision generations or arbitrary heap records.

Code-point head/tail operations must handle supplementary characters as one Char, preserve embedded NUL, preserve aliases, and reject the same control characters through the unmodified source. Null platform String references and malformed isolated surrogates are not qualified as ordinary Idriç Text inputs by this slice. No claim of general Unicode normalization, zero-allocation conversion, minimal memory use or universal list runtime is made.

## Tests and evidence

`verify-unpack.grease` executes real Idriç host controls, compiles unchanged checked source fixtures to DEX, validates with AOSP, and requires source-check-success before rejecting escaping/non-tail examples. A source validator mutant must produce DEX and fail the same independent ART observer; compile errors are not mutation success.

The workflow also checks out exact IB source 446a183e245632608bf2868d4a34eb2f5225bd67 and attempts its unchanged LongViewAndroid export. Its result and two production mutants have separate evidence. The final required gate needs actual IB ART success, so standalone unpack success cannot hide an unsupported full consumer. A passing diagnostic still proves only that export's constructed task states, not disk restoration, arbitrary persisted generation values, full renderer callbacks, authenticated sessions, Shizuku or a phone APK.

Existing finalized-layout, arithmetic, reference/effect, source-refusal and ART checks are retained. Candidate bytes are produced by Idriç; smali builds only external observation callers. This is a draft authoring candidate, not a registered FP dispatch, independent ai-ci promotion, merge or release.
