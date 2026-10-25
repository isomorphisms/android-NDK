# Bounded managed/native contracts

JNI map rows retain the existing three columns:

```text
calling_convention native_method method_descriptor
```

These legacy rows keep their previous null/string conversions. They have no
newly inferred ownership, threading or nullability promise. In particular this
repair does not strengthen ICU's existing map or change its transport.

Compiler API migration: the internal `JNIService` record now carries a
`boundary_contract` field. Direct `MkJNIService` callers must supply
`LegacyUnqualifiedNativeBoundary` to preserve the old behavior, or the explicit
contract constructor when that obligation is actually declared. The map parser
supplies this field; existing three-column application maps need no change.

An explicit row appends this complete policy:

```text
current-thread synchronous borrowed-local nonnull-strings propagate-exceptions
```

This bounded contract admits int/long/String arguments and int/long/String/void
results. It declares execution on the calling thread, borrowed JNI local
references valid through return and no asynchronous retention. Strings are Java
Strings with UTF-16 contents. Native code must use the JNI string APIs with
their documented encodings: modified UTF-8 is not interchangeable with ordinary
UTF-8, and no implicit native byte-buffer representation is specified here.

Generated adapters reject null String inputs before invoking native code and
reject null String results after a successful native return. Existing exact
int/long narrowing remains before invocation. ART propagates pending JNI
exceptions; the adapter emits no catch or fake success value. The native body
must stop performing ordinary JNI operations when an exception is pending and
release its native resources. These are obligations of the declared native
implementation, not proofs obtained from the descriptor.

Retained references, callbacks, object handles and asynchronous/thread-changing
policies are deliberately refused by this contract. A future implementation
must provide an explicit ownership/release model before admitting them. A
numeric parameter is not automatically a verified native handle.

`prepare.grease` accepts REPOSITORY FRONTEND DRIVER BAKSMALI EVIDENCE. It runs
the host contract controls, compiles explicit and legacy versions of the checked
program, independently decodes both and checks retention refusal. The generated
candidate is `EVIDENCE/native-contract.dex`.

`native_contract_fixture.c` is a small JNI fixture. Build it for the selected
Android ABI on the maintained build host; do not build it on a phone. Place the
matching library at `EVIDENCE/libcontract.so`. `observe.grease` accepts ADB SERIAL
INPUT EVIDENCE and exercises identity of non-BMP text, signed narrowing, null
result refusal and native exception propagation on an x86_64 emulator. The repeat
case performs 10,000 native calls, each acquiring and releasing a temporary global
reference within the same invocation. It checks successful scoped reuse, not a
measured proof of absence of every native leak. Physical device acceptance is a
separate evidence category.
