# Binder / system-service boundary

This directory owns the reusable Android Binder boundary used by native and
direct-DEX consumers. It does not own Shizuku policy, Crawl Space client
authorization, application package rules, or any one system service's AIDL
surface.

There are two useful implementation lanes.

## NDK Binder lane

The public Android NDK Binder API (API 29+) provides enough machinery for a
substantial native broker:

- define and instantiate local Binder classes;
- receive transactions through an on-transaction callback;
- obtain Binder calling UID/PID while handling an incoming transaction;
- prepare/transact Binder calls;
- create/delete/copy parcels;
- ping remote binders;
- link/unlink death recipients;
- bridge an NDK binder to a Java `android.os.IBinder` when a JNI environment is
  deliberately present.

That makes a native Idriç/ICK/NDK broker a serious implementation option rather
than merely a test shim.

A limitation matters for Shizuku semantics: the public NDK Binder API does not
expose the Java `Binder.clearCallingIdentity()` /
`Binder.restoreCallingIdentity(long)` pair. The underlying platform libbinder
has an IPC-thread calling-identity mechanism, but using private C++ libbinder
interfaces is a separate, unstable boundary and must not be mislabeled as NDK.

## Direct DEX / framework lane

A direct DEX broker can use the same framework classes as Shizuku without
generating Java source:

- `android.os.Binder`;
- `android.os.IBinder`;
- `android.os.Parcel`;
- `android.os.ServiceManager`;
- hidden framework helpers where the privileged program deliberately depends on
  them.

The checked Idriç DEX backend does not yet lower that object/method-call slice.
The type plan for the required extension is in
[`dex/idric/src/Backend/DEX/Framework.idr`](../dex/idric/src/Backend/DEX/Framework.idr).

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
