# Program attempt: Quick Settings bindings

Status: `PASS` for source binding acceptance; Android execution `NOT_RUN`.

## Purpose

Make Android Quick Settings APIs available to Idriç consumers, including IB's
Pensieve line, without selecting a tile purpose or installing a tile.

## Intended behavior

Provide reusable source bindings for the public Android SDK surface through
API 34. Importing the package performs no action. Application code will later
own its service subclass, component, resources, event handlers, and any request
for the user to add a tile.

## Type-system sketch

### Values and domains

- Framework-owned references: TileService, Tile, Context, ComponentName,
  StatusBarManager, Icon, CharSequence, Dialog, Intent, PendingIntent, Runnable,
  Executor, Consumer<Integer>, and boxed Integer.
- Tile states: unavailable, inactive, active.
- Addition results: declined, already present, added, documented error codes,
  and an unrecognized code retained unchanged.
- Android API levels and exact DEX method descriptors.

### Types and signatures

Framework references use Idriç's existing `[external]` data declarations. They
are distinct types, not integer IDs or forged host pointers. They preserve raw
framework reference semantics, including null where the API permits it; this
slice supplies no unchecked null-to-non-null conversion.

Representative public signatures:

- `tile_for_service : TileService → IO Tile`
- `set_tile_state : Tile → TileState → IO ()`
- `update_tile : Tile → IO ()`
- `request_add_tile : StatusBarManager → ComponentName → CharSequence → Icon → Executor → TileAddResultConsumer → IO ()`

### Actions and effects

Every framework call remains `PrimIO` at the foreign boundary and `IO` in the
public module, including getters. State/result decoding is pure. No foreign
action executes merely by importing or typechecking the package.

### Laws, invariants, and errors

- API names, descriptors, widths, overloads, and callback erasure must match
  the public SDK; Java `int` and Boolean registers use explicit `Int32`.
- The three public state values map to 0, 1, and 2; unknown input is refused.
- Unknown addition results remain distinguishable from success.
- Tile and service receivers cannot be interchanged.
- Framework exceptions remain framework exceptions; a `void` update is not
  proof of a visible SystemUI change.
- Addition requires the platform's user-consent flow; the package cannot
  silently place a tile, grant privileges, or start a service.

### Runtime and backend boundary

Calling convention: the existing `dex:<kind>:<owner>:<name>:<descriptor>` from
the preserved android-NDK foreign-call work. No NDK C export or stable private
Binder protocol exists for these SDK methods. This does not introduce JNI,
Java source, Gradle, RefC, or another backend.

The current main DEX backend does not lower these object/IO calls. The separate
foreign-call slice handles a narrower source ABI and does not yet supply
general service subclasses, interface callback objects, or this six-register
addition call. Binding/typechecking evidence must stay separate from emitted
DEX, ART execution, and a working tile.

## Idriç attempt

Implementation: `quick-settings/idric/src/Android/QuickSettings.idric` and its
`References` and `Foreign` modules. Consumer and refusal fixtures live here.

Compiler: actual Idriç `ff4d852862a3942592f8ade9afde8d409d9803be`, reporting
`0.8.0-ff4d85286`. The existing compiled image SHA-256 is
`10002074cfae31a15e6f136cd191b6abe9f8d58efcec438d21145e72802b2819`.
No compiler was rebuilt and no target-code generator was invoked.

[`verification.txt`](verification.txt) records exact commands, dependency and
source digests, isolation, and output boundaries. Actual results:

- All three package modules pass `--typecheck` (exit 0).
- `QuickSettingsBindings.idric` passes `--check` (exit 0). Its `Refl` proofs
  establish the public state/result goldens, all state round trips, refusal of
  unknown state values, and preservation of unknown addition results by compiler
  normalization. Ten unevaluated aliases check public method/callback types.
- `WrongTileReceiver.idric` fails `--check` (exit 1), specifically rejecting
  `TileService` where `Tile` is required. It is a deliberate negative fixture.
- The retained external-reference probe passes `--check` (exit 0).
- Independent review of all 25 foreign method declarations against the pinned
  Android 34 sources finds matching owners, dispatch, descriptors, argument
  order, and result types. This is source/API review, not classfile linkage.

The first golden-fixture attempt encountered inherited automatic implicit-name
shadowing in proof types. Qualified decoder names resolved it; the final
positive source checked without warnings. The binding implementation needed
no change for that fixture correction.

## Fallback

None.

## Idriç language work exposed

The next runtime slice must preserve external object references and effects
through checked-source DEX lowering, generate service/interface callbacks, and
support the addition request's receiver plus five arguments (`invoke/range`
or equivalent register lowering). Its acceptance must execute a directly
emitted class under ART and observe real callbacks; a host mock is insufficient.

## Evidence boundary

Package and consumer source checking, pure compiler normalization, receiver
refusal, and independent SDK signature review passed. Emitted DEX, APK, ART,
service callbacks, and physical-device behavior have not run. No app behavior
is part of this request, and no binding call was executed on the host.
