# Binder / system-service boundary

This directory owns the reusable Android Binder boundary used by native and
direct-DEX consumers. It does not own Shizuku policy, Crawl Space client
authorization, application package rules, or any one system service's AIDL
surface.

There are two implementation lanes because the public NDK Binder API and the Java/framework Binder API do not expose the same operations.

## NDK Binder lane

The public Android NDK Binder API (API 29+) provides enough machinery for a
substantial native broker:

- define and instantiate local Binder classes;
- receive transactions through an on-transaction callback;
- obtain Binder calling UID/PID while handling an incoming transaction;
- prepare/transact Binder calls;
- create/delete parcels and read/write typed parcel values;
- ping remote binders;
- link/unlink death recipients;
- bridge an NDK binder to a Java `android.os.IBinder` when a JNI environment is
  deliberately present.

The first native Idriç slice now lives in `binder/ndk/` and
`binder/idric/src/Android/Binder/NDK.idr`. It exposes typed `Binder`,
`Transaction`, and `BinderStatus` handles over a narrow C ABI. Binder and
transaction pointers are attached to Idriç GC finalizers so the C wrapper owns
the strong-reference and parcel cleanup rules.

`AIBinder_prepareTransaction` requires the remote object to be associated with
an `AIBinder_Class` carrying its interface descriptor. The native façade caches
those client-side classes by descriptor and makes the association explicit.

Three limitations matter for Shizuku semantics.

First, the NDK package used by ordinary application builds contains the
`binder_ibinder`, Binder-JNI bridge, parcel, and status headers, but not the
platform `binder_manager.h` or `binder_process.h` headers. Service-manager
lookup and ProcessState thread-pool controls are therefore not part of this
public-NDK façade. The current native slice operates on a Binder handle supplied
at another explicit boundary or returned by a transaction.

Second, the public NDK Binder API does not expose the Java
`Binder.clearCallingIdentity()` / `Binder.restoreCallingIdentity(long)` pair.
The underlying platform libbinder has an IPC-thread calling-identity mechanism,
but using private/platform libbinder interfaces is a separate boundary and must
not be mislabeled as ordinary NDK.

Third, public `AParcel` is a typed serialization interface. It does not expose
Java `Parcel.appendFrom` plus arbitrary data-position operations, so the NDK
lane cannot faithfully copy an opaque incoming Parcel into another transaction.
That specific Shizuku operation belongs to the direct DEX/framework lane (or a
separately identified private/raw Binder backend).

## Direct DEX / framework lane

A direct DEX broker can use the same framework classes as Shizuku without
generating Java source:

- `android.os.Binder`;
- `android.os.IBinder`;
- `android.os.Parcel`;
- `android.os.ServiceManager`;
- hidden framework helpers where the privileged program deliberately depends on
  them.

The Idriç DEX backend now has typed framework method references, invoke-35c
encoding including object and wide results, and a directly encoded Binder
framework probe that CI disassembles and checks. The remaining compiler boundary
is source lowering: checked Idriç source still cannot yet name one of these
framework operations and have the DEX lowerer generate the call automatically.

That source hook should use Idriç's existing ANF foreign-definition information
rather than hard-coding source function names into the DEX lowerer.

## Shizuku minimum

A faithful remote-transaction broker needs these semantic operations regardless
of which lower layer supplies them:

```text
receive client Binder transaction
    ↓
obtain caller UID/PID
    ↓
authorize caller
    ↓
decode target Binder + transaction code + flags + payload
    ↓
run forwarding under broker identity
    ↓
transact target Binder
    ↓
return target reply
```

The identity step is essential. A backend is not Shizuku-equivalent merely
because it can relay Parcel bytes.

## First acceptance ladder

Do not collapse these into one vague “Binder works” result.

1. **local-callback** — a locally defined Binder object receives a transaction.
2. **caller-identity** — the callback records the caller UID and PID.
3. **remote-ping** — obtain a remote Binder and successfully ping it.
4. **parcel-round-trip** — transact a harmless method and decode its reply.
5. **broker-identity** — prove the forwarded transaction is observed under the
   broker identity rather than the ordinary application caller.
6. **death** — remote/client Binder death triggers the registered cleanup path.
7. **delivery** — pass the broker Binder into an ordinary application process.

Each step needs its own evidence. In particular, NDK caller UID/PID and raw
transact evidence do not prove the broker-identity step.

## Crawl Space consumer

The Shizuku translation lives on `isomorphisms/crawlspace` branch `shizuku`.
Its Idriç files own the broker/client/user-service semantics. This directory
owns only the reusable Android Binder mechanics needed to lower those semantics.
