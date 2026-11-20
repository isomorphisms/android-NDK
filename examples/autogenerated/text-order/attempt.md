# Unicode Text ordering required by the real IB history consumer

The unchanged native reader history compares a bounded canonical generation
spelling against its signed platform limit. Managed DEX refused `<=String`.
The type sketch is `Text → Text → Text`: the result records `<`, `<=`, equality,
`>=` and `>` as five bits, while checked Text remains distinct from a platform
integer comparison result. The one-argument pure export and IO entry exercise
their separate entry contracts; the real reader exercises framework exports.

The reusable Heap lowering now admits ordered Text primitives and calls a
compiler runtime helper that compares Unicode code points. It advances UTF-16
offsets with Character.charCount and handles empty/equal/proper-prefix inputs.
Java String.compareTo is unsuitable: the valid supplementary scalar U+1D11E
orders after U+E000 in the maintained frontend and before it in UTF-16 order.

The separately compiled negative module deliberately uses the platform UTF-16
comparator. The independent ai-ci observer must pass
ASCII/prefix/equality cases, distinguish supplementary/BMP order and reject that
control at its Unicode expectation. No normalization or locale collation is
claimed. The original IB lowering refusal is retained in its source-bound
compilation log. No IB semantics or candidate DEX is handwritten to bypass it.

The initial fixture put the foreign comparator behind a false Boolean. Its
checked graph still contains that branch, so the pure entry correctly refuses
the platform foreign declaration. `initial/` preserves that attempt as a
mandatory refusal with exit 1 and no stale DEX. The positive pure source has no
foreign comparator; the negative managed source owns it explicitly. The repair
does not relax the pure foreign boundary. Pure Text selection now also inspects
checked Text ordering/concatenation requirements when optimization removes
ordinary source constructors; it retains the separate one-argument pure ABI.
