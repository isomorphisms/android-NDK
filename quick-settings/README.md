# Quick Settings source bindings

This package exposes the public Android Quick Settings interface to Idriç
consumers, including IB/Pensieve. It contains typed source declarations and
`IO` wrappers. Importing it does not install a tile or run a framework call.
The application has not assigned these bindings a purpose.

## Import

Package: `idric/idric-android-quick-settings.ipkg`

Source root: `idric/src`

Public module: `Android.QuickSettings`

The public module exposes tile state, labels/icons/accessibility descriptions,
listening and lock-state operations, the addition request, and the two distinct
activity-launch overloads. Exact DEX calls live one level down in
`Android.QuickSettings.Foreign`; opaque framework references live in
`Android.QuickSettings.References`.

Consumers pin this repository and typecheck the package before importing its
TTC output. The package has no executable entry point, application resources,
Android manifest, service implementation, startup hook, or automatic addition
request. IB's dependency owns only access to this shared package.

## API coverage

| Android API | Binding surface |
| --- | --- |
| 24 | TileService, tile state/icon/label/content description, updates, listening, lock/security state, dialog/unlock actions, legacy Intent launch |
| 29 | Tile subtitle |
| 30 | Tile state description and toggleable metadata name |
| 33 | StatusBarManager addition request and its result codes |
| 34 | PendingIntent launch overload and Tile activity-launch-for-click accessors |

[`api.tsv`](api.tsv) records the exact public method descriptors and directions.
The callback rows describe calls from Android into a future application adapter;
they are not outbound methods that simulate Android events. `Consumer.accept`
receives an `Object` containing a boxed `Integer`, not an unboxed `int`.

The parcel-serialization interface of Tile, general Context/resource/object
construction, hidden system methods, and API 36.1 tile categories are outside
this package. Tile has no public SDK constructor; the framework supplies it
through the bound TileService. The caller obtains StatusBarManager from its
Context using `statusbar` and supplies the other framework objects.

## Reference and effect contract

`[external]` declares framework reference domains. Tile, TileService, Icon,
CharSequence, and the other references are distinct types. The binding does
not allocate Idriç constructor boxes around them or reinterpret them as C
pointers. The eventual DEX backend must preserve their exact reference values.

These are raw references, not proofs of non-nullness. `getQsTile` can return
null when the tile is unavailable. Icon, label, subtitle, content description,
state description, and activity-launch accessors can also carry null. A null
PendingIntent passed to `set_click_activity` restores ordinary `onClick`
dispatch; a non-null value must target an Activity. No invented null test,
unchecked cast, or automatic conversion to `Maybe` is supplied. A future
adapter must validate nullable references before calls that require non-null
receivers or arguments.

The three state constructors encode only the public values 0, 1, and 2.
`decode_state` returns `Nothing` for any other integer. Addition-result decoding
distinguishes the three public results, all six API 33 errors, and unknown
codes without turning an unknown into success.

Every framework operation is effectful, including reads. Foreign primitives
return `PrimIO`; the public wrappers return `IO`. Java Boolean registers use
the existing DEX foreign convention's `Int32` representation, converted at the
public boundary. Framework exceptions are not swallowed or replaced by a
success result. `updateTile()` returns void; that is not acknowledgement that
SystemUI displayed the update.

## Android-owned lifecycle and consent

The future application adapter owns its TileService subclass and the handlers
for added, removed, start-listening, stop-listening, and click callbacks. The
framework may recreate the service between events; adding a tile and rebinding
a service are different events. Tile updates require the valid listening
interval. `request_listening` is meaningful for active-mode tiles.

The eventual manifest must declare an enabled, exported TileService protected
by `android.permission.BIND_QUICK_SETTINGS_TILE` and advertising
`android.service.quicksettings.action.QS_TILE`. This permission controls who
binds to the service; it grants the app no additional authority. The constants
provided here do not amend a consumer's manifest.

API 33's addition request is asynchronous. Its manager, component, label, icon,
executor, and result consumer must be non-null. The app must be foreground,
belong to the current user, and own the requested component. The user may add
or decline the tile. Request submission is not addition success, and the
package makes no automatic request.

On Android 14, `start_activity_legacy` throws for apps targeting API 34 or
later. The PendingIntent overload is separately named and requires API 34.
The package neither selects an overload nor changes an application's SDK
floor or target. The caller must check availability before invoking a newer
method on an older platform.

## Compiler boundary

These are SDK/DEX methods, not NDK C exports or a public native Binder
transaction protocol. The `dex:` calling-convention format follows the
existing foreign-call work in this repository. Keeping source declarations
independent avoids importing an unrelated Binder implementation or changing
the NativeActivity packager.

The checked DEX extension in
[`FRAMEWORK-EFFECTS.md`](../dex/idric/src/Backend/DEX/FRAMEWORK-EFFECTS.md)
adds typed outbound framework references, ordered PrimIO/IO calls, scalar and
void results, and the addition call's receiver plus five argument registers.
Its source fixtures import these public wrappers directly. Algebraic wrapper
results can be projected inside checked source; an unprojected source sum has
no external DEX ABI and is rejected.

The extension does not generate a TileService subclass or
Runnable/Executor/Consumer callback objects. The application must still supply
real platform references, nullable-reference handling, and lifecycle ownership.
No Java, Gradle, JNI, smali-candidate, or RefC fallback is introduced by this
package.

Source checking proves that consumers can import the typed declarations. It
does not prove DEX emission, SDK linkage, ART execution, tile registration,
or physical-device behavior. The original
[source-checking attempt](../examples/autogenerated/quick-settings-bindings/attempt.md)
records the declaration-stage evidence. The separate
[public-wrapper fixture](../examples/autogenerated/quick-settings-runtime/attempt.md)
and pinned workflow retain later evidence for each boundary. Runtime tests use
real Integer, Parcel, and String objects; they do not register a tile or deliver
an Android callback.

## Primary references

The signature audit is pinned to Android's API 34 source snapshot
`88c7ff1cd72d6305ec59f97aadc2198cc2dc3592`:

- [TileService source](https://android.googlesource.com/platform/prebuilts/fullsdk/sources/+/88c7ff1cd72d6305ec59f97aadc2198cc2dc3592/android-34/android/service/quicksettings/TileService.java)
- [Tile source](https://android.googlesource.com/platform/prebuilts/fullsdk/sources/+/88c7ff1cd72d6305ec59f97aadc2198cc2dc3592/android-34/android/service/quicksettings/Tile.java)
- [StatusBarManager source](https://android.googlesource.com/platform/prebuilts/fullsdk/sources/+/88c7ff1cd72d6305ec59f97aadc2198cc2dc3592/android-34/android/app/StatusBarManager.java)
- [Public API levels and signatures](https://developer.android.com/reference/android/service/quicksettings/Tile)
- [Adding a tile and receiving consent](https://developer.android.com/develop/ui/views/quicksettings-tiles)
- [Android 14 launch behavior](https://developer.android.com/about/versions/14/behavior-changes-14#tiles-launch)
