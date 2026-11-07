# Program attempt: bounded compiler Boolean tags

Status: `SOURCE_CHECKED`; host execution is pending the next hosted verifier.

The hosted checked DEX driver built successfully at backend revision `037f6ef`
and passed the invocation, foreign-parser, and encoder host checks. Its first
source fixture, `DexArithmetic.choose_less`, then failed with `Unsupported DEX
case constant 1` before producing DEX.

The pinned compiler's `Compiler.Opts.Constructor.enumTag` emits `B8`, `B16`, or
`B32` constants for enums; Bool uses `B8`. Its ordinary ANF printer displays all
integer constant constructors as bare numbers. The generalized DEX case handler
retained only `I32` and bounded `I`, losing the former Boolean tag recognition.
The direct Bool result path has the same missing representation.

This regression program will construct the relevant typed ANF boundary directly
and call the actual public `lower_method`. It will accept zero/one Boolean tags,
preserve the full signed Int32 case range, and reject non-Boolean unsigned or
arbitrary-precision values. A Bool tag must not become a new Int32 literal ABI.
Every case probe has an explicit fallback so its tested alternative is actually
validated. The existing arithmetic and Boolean source fixtures remain the
end-to-end DEX and ART checks.

The program uses Idriç and the pinned compiler API. It executes no Android IO,
and uses no alternate candidate backend. Source checking and execution results
will be recorded separately.

## Change and source-stage verification

`Lower.constant_tag` recognizes only zero and one before any cast. The general
case handler now uses it as a fallback after the existing Int32 and bounded
machine-integer cases; the Bool literal handler uses the same guard. The change
does not admit arbitrary unsigned or unbounded integer literals as Int32.

Actual pinned compiler `0.8.0-ff4d85286`, source revision
`ff4d852862a3942592f8ade9afde8d409d9803be`, passed a fresh `--check` of Codegen and
all nine backend dependencies. It also passed `--check` of
`DexConstantTagChecks.idric`. Both checks used the compiler's own API TTCs and
the coherent installed bootstrap prelude/base/linear/network package roots;
no final source-tree library TTC directory was substituted.

`failure.checked.anf` is the unchanged hosted compiler output for arithmetic.
Its source artifact ZIP SHA256 is
`a07b164cf45d08b715c2481ea87517b3836cdee7510ae4732468914d0b698ade`.
The printer hides integer constructor kinds; the pinned compiler's enum
optimization source supplies the B8 representation evidence.

No local driver rebuild, host regression execution, candidate emission, or ART
execution is claimed by these source checks. The expected host receipt is
`PASS: DEX bounded compiler Boolean tags`; successful arithmetic/Boolean DEX
emission and their runtime runners remain separate required results.
