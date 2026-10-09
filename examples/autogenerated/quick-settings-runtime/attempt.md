# Program attempt: Quick Settings runtime bindings

Status: `PARTIAL` — public source accepted; the baseline dedicated driver
rejected its export ABI; external runners assembled and independently parsed.
Updated-backend DEX emission and ART execution are still pending.

## Purpose

Exercise the merged public Quick Settings package through checked Idriç source
as the direct DEX backend gains object and effect support. The user has not
chosen a tile purpose. These exported diagnostic functions are binding tests;
they do not install a tile, register a service, or become IB startup behavior.

## Intended behavior

The future caller supplies real framework references. One function obtains the
service's tile, another reads its state, and another sequences setting the
Active state before sending its update. A fourth forwards the addition request
with its manager and five arguments. The result-payload function reads a real
boxed Integer through the public binding, then projects every declared result
case back to its documented code, preserving unknown codes.

The source imports `Android.QuickSettings` directly. It does not redeclare a
foreign call, invent a framework constructor, or use a lower-level replacement
for the public library functions under test.

## Type-system sketch

### Values and domains

`TileService`, `Tile`, `StatusBarManager`, `ComponentName`, `CharSequence`,
`Icon`, `Executor`, `TileAddResultConsumer`, and `BoxedInteger` are the public
package's distinct external reference types. `TileState` and `AddTileResult`
are the same package's domain choices. `Int32` is the explicit DEX scalar
result used only at the test-observation boundary.

### Types and signatures

- Service tile access: `TileService → IO Tile`.
- Public state read inside the fixture: `Tile → IO (Maybe TileState)`.
- Projected state observation at the external boundary: `Tile → IO Int32`.
- Sequenced state write and update: `Tile → IO ()`.
- Addition submission: `StatusBarManager → ComponentName → CharSequence → Icon → Executor → TileAddResultConsumer → IO ()`.
- Callback payload observation: `BoxedInteger → IO Int32`.
- Callback constructor-tag observation: `BoxedInteger → IO Int32`.
- Pure result projection: `AddTileResult → Int32`.

The positive fixture returns `-1` for an unrecognized tile state and the
documented state code for `Just state`. `UnprojectedTileState.idric` retains
the direct `Tile → IO (Maybe TileState)` export as a separate expected backend
refusal until an external algebraic-result ABI exists. Source acceptance of
that declaration does not define a Java representation for `Maybe TileState`.

### Actions and effects

Every platform operation remains in `IO`; its public wrapper uses `PrimIO`
internally. Result projection is pure. The compiler must preserve ordering and
erase only the actual source effect/world plumbing justified by checked ANF.
It must not relabel a platform read as pure to fit an older foreign-call path.

The diagnostic `main` is empty and calls none of the exported functions. The
direct DEX backend selects the explicitly annotated exports for an external
runner to invoke independently.

### Laws, invariants, and errors

The observed result codes must be 0, 1, and 2 for the three ordinary results;
1000 through 1005 for the six declared errors; and the unchanged input for
`UnrecognizedAddResult`. This mapping must not turn an error or an unknown
code into addition success.

A second, observation-only export `callback_result_tag` distinguishes the
nine known constructors with tags 0 through 8 and the unknown constructor
with tag 9. Checking only decode-then-project code identity could miss a
decoder that always selects the unknown constructor. The external runner
must compare both the raw code and the independent expected tag for every
boxed input.

`set_active_then_update` must call the state setter before the updater. The
addition request must preserve the receiver and the five arguments in order;
six reference registers do not fit DEX's five-register short invoke form.

Framework references include Java null. The signature does not prove
non-nullness, API level, or service lifecycle. Actual tile writes require a
valid framework-supplied Tile during a listening interval. Tile has no public
SDK constructor, and no invented constructor or fake object is used here.
Framework exceptions remain failures rather than successful default values.

### Runtime and backend boundary

The intended route is checked `.idric` source → compiler ANF → typed DEX
instructions → directly encoded DEX → ART. The existing dedicated driver is
`Backend.DEX.Main`, built as `dex/idric/build/exec/idric-dex`. An installed
Idriç executable without the `dex` generator is a different boundary.

An external ART runner may supply ordinary `Integer.valueOf(code)` objects to
the payload function. That would prove real reference/IO/payload execution;
it would not prove asynchronous callback dispatch, TileService lifecycle, a
valid tile, or successful user-approved addition. A separate custom oracle for
argument order and side effects remains test-only evidence, not an Android
Quick Settings implementation.

## Idriç attempt

Source: `QuickSettingsRuntime.idric`.

Repository base: `42f04d7654d54309ec3f8787bfd2bc40730399d7`, whose tree is
`fab868b58afa8105fe14dd73ae22f59a8d96e3a9`. The package originated at
`65769fd68a30a26e0dacd2d0f9ba182850857e86` and is consumed unchanged.

Source checking used the verified existing Idriç compiler
`ff4d852862a3942592f8ade9afde8d409d9803be`, with explicit package and standard
library checked-module paths. Its executable payload SHA-256 is
`10002074cfae31a15e6f136cd191b6abe9f8d58efcec438d21145e72802b2819`.
The runtime fixture's source SHA-256 is
`c366e38b4a960abe73bddaf00a85b5c1c9c56f1e8224d68259ba1a07837fbd0e`.
Exact source-check commands and output are retained in `source-check.txt`.

The original source, before projecting the state result, is preserved in
`initial/QuickSettingsRuntime.idric`. Its actual baseline compiler graph is
`initial.checked.anf`. The projected source before adding the tag observation
is preserved in `projected/QuickSettingsRuntime.idric`; its actual baseline
graph is `projected.checked.anf`. Both graphs were dumped by the dedicated driver
before it rejected the source ABI; they are not hand-authored lowering input.

## Result or failure

Pinned public package source check: `PASS`, exit 0.
Runtime fixture source check: `PASS`, exit 0.
Constructor-tag-enhanced runtime fixture source check: `PASS`, exit 0.
Unprojected expected-refusal fixture source check: `PASS`, exit 0.
Baseline dedicated-driver DEX attempt: `REJECTED`, no candidate DEX.
External runner assembly and independent disassembly: `PASS`.
Updated dedicated-driver DEX attempt: `NOT_RUN`.
ART and Android Quick Settings execution: `NOT_RUN`.

The actual baseline diagnostic was:

```text
Error: dex rejected source ABI for `QuickSettingsRuntime.callback_result_code`: unsupported source type. The checked executable boundary currently admits explicit Int32 and Text parameters/results only.
```

That baseline driver returned process status 0 after printing the rejection.
The output DEX was absent. A positive compiler check must therefore require
a newly emitted nonempty artifact and inspect diagnostics, rather than treat
exit status alone as acceptance. Exact baseline identities and commands are
retained in `baseline-dex-rejection.txt`.

The source result demonstrates the declared external types, public imports,
effect signatures, and complete result projection. It does not show that the
dedicated backend can lower those checked functions. No runtime value or
Android reference was fabricated to obtain this source result.

## Fallback

None. No Java, JNI, Gradle, generated-C, or handwritten candidate DEX replaces
the checked source path.

## External test runners

These smali programs are independent observation callers. They provide real
platform inputs and compare the checked candidate's outputs. They do not
define `LIdric/Generated;`, which must come from the relevant Idriç fixture.

| Runner | Candidate source | Observable contract |
| --- | --- | --- |
| `QuickSettingsRunner.smali` | `QuickSettingsRuntime.idric` | All fourteen real boxed inputs retain their codes and return independently expected constructor tags: 0–8 for the nine known results, 9 for each unknown. Raw-code failure exits are 61–74; tag failure exits are 121–134. |
| `ParcelEffectsRunner.smali` | `../quick-settings-source-effects/QuickSettingsSourceEffects.idric` | Primitive and IO reads return 91; the ordered write/seek/read returns 31337, leaves position 4, and independently stores 31337. Both recycle exports return normally. Failure exits are 81–85. |
| `InvokeRangeRunner.smali` | `../dex-invoke-range/DexInvokeRange.idric` | Six-word String calls preserve receiver, unequal offsets, length, case flag, and boolean result. Two reordered-export calls also exercise argument staging. Failure exits are 91–100. |
| `BooleanRunner.smali` | `../quick-settings-source-effects/QuickSettingsBoolean.idric` | Real `Z` descriptors carry both Bool values through constants, identity, negation, Int32 equality, and boxed-Integer IO equality. Failure exits are 101–112. |

The Boolean runner tests Int32 equality on 1/0/2 and boxed Integer equality
on those same three values, so nonzero two cannot silently become true.
The public `is_locked` and `is_secure`
wrappers are checked for emission in that candidate but will not be invoked
without a real service. This runner does not construct a TileService.

Each candidate fixture emits the same class name, `LIdric/Generated;`. Run
each runner with its own candidate DEX; combining the candidate DEX
files on one classpath would create a class collision and invalidate the
test. Runner assembly used the repository's pinned smali 3.0.10 oracle;
baksmali 3.0.10 independently parsed the resulting runner DEX. Commands,
hashes, and the descriptor inspection are in `runner-check.txt`.

Assembly proves that these caller artifacts can be encoded and parsed. It
does not resolve their candidate references or execute them. The Parcel
runner checks the real read/write state but does not use a recycled Parcel
to invent a post-recycle guarantee. The String runner is an argument-order
test; it does not exercise Android Quick Settings.

## Idriç language work exposed

The observed first boundary is export ABI handling for an external reference
inside `IO`. The dumped ANF also contains ordered void-effect lets, imported
function applications, the public library's IO-map closures, Maybe and result
constructors, and a six-reference foreign call plus its trailing World token.
The backend must handle those actual forms while preserving effects. The
presence of a checked graph is not evidence that lowering succeeded.

Acceptance requires the exact checked exports in the emitted DEX and an
independent ART caller observing the results and effect order. Actual tile
updates and addition consent remain separate platform acceptance.
