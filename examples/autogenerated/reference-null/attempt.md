# Program attempt: checked API23 reference null test

Status: compiler, host and actual source DEX qualification PASS;
ART API23/API29/API34 PENDING.

## Purpose and intended behavior

The real AVE normal Activity needs to test nullable KeyEvent, Intent, Uri and
OutputStream values while preserving its existing Android API23 floor.
`java.util.Objects.isNull(Object)` is API24 and cannot supply that contract.
The new compiler operation must emit a direct typed DEX null branch.

## Type-system sketch

- `ObjectReference` is a concrete checked external source domain associated
  with `Ljava/lang/Object;`; it is not a managed ADT or a nullable source ADT.
- Pure `%foreign "dex:reference-is-null"` has exactly the source type
  `ObjectReference → Int32`, returning one for null and zero otherwise.
- Precise platform domains retain their own descriptors. Existing checked
  `dex:cast` operations upcast them to the distinct ObjectReference domain
  without altering null or object identity.
- Ordinary ADTs, applied managed types, Text, wrong arity/result and effectful
  declarations must refuse. Codegen must continue checking the source TCon's
  external flag and conflicting descriptor constraints.
- Direct and managed foreign lowering share a typed reference-null branch;
  register placement and branch widening remain in their existing owners.

Required target: direct DEX and ART API23. No platform API24 call, reflection,
text conversion, native relay, or alternate candidate producer is permitted.

## Attempt and evidence boundary

Source fixtures, production mutation controls and the independent ART observer
will remain here. The pre-implementation diagnostic will be recorded from the
actual combined backend once its existing serialized build is available.
No heavy Chez build is authorized concurrently with the parent build.

The exact prepatch combined driver (source0ae25e38, executable SHA-256
`f80c83b5f51f9403f27a6fa693a4005720d203385e25936e70a42534ac70ac7b`)
typechecked the actual source, then refused DEX with exit1 and no candidate:

```text
Error: dex rejected foreign declaration: Missing dex foreign owner
```

The source frontend check itself passed. This is the retained calling-convention
gap, rather than an Android runtime failure.

The implementation adds `CheckedReferenceNull`, the typed shared
`ReferenceNullBranch` instruction, reference-preserving high-register placement,
21t encoding/branch relaxation, and direct/managed lowering. The existing
external TCon and conflicting-descriptor checks remain authoritative. The null
intrinsic introduces no platform method call. The managed runtime's existing
API19 `Objects.requireNonNull` entry validation remains; API24
`Objects.isNull`/`nonNull` are forbidden in the qualification helper.

Local pinned-frontend qualification passed all 25 backend module typechecks,
the full Chez backend executable build, and the host compiler-API fixture.
The fixture independently asserts exact 21t bytes, malformed input refusals,
high reference-register object staging and far conditional widening. The new
driver executable SHA-256 is
`5654630698007e36f5d58b7475a750ea01cbe23de100cb5d39c4e0cf94f744b5`.
The actual source frontend check, independent Smali observer assembly/decode,
and both helpers' parse checks also passed. Helper parsing used the retained
pinned Grease runtime (tar SHA-256
`03cc6ab334d5695b773e279350ef4ea3dc11191aeb874ea6ef234110d7a04a7f`).

The original null and non-null source is compiled separately in direct and
managed modes. Its observer checks Object, KeyEvent, Intent, Uri and OutputStream
without Activity bootstrap. A compiled source mutation inverts only
`object_null`; the observer requires designated exit95 and its exact assertion
line. Unexpected Throwable uses exit96, and process death cannot satisfy the
mutation gate. Source controls preserve ordinary-data, conflicting-descriptor,
wrong-signature and effectful-declaration refusals.

Using that exact local driver and the retained pinned frontend, the original
source emitted and independently decoded in direct and managed modes. Both
repeated outputs were byte-identical. Each decoded output contains the typed
null branch and five correctly described exports, with no API24 Objects null
predicate. Both compiled source mutants emitted different candidate bytes.
All four real source refusals exited exactly1 with their intended diagnostic
and no DEX. The baseline source's prepatch refusal also left no DEX.

| Artifact | SHA-256 |
| --- | --- |
| Direct source DEX | `df47dace32bb8b688bc1b376d1e687d96ca8a765fc12ee0946a1d8bb0c044cd2` |
| Managed source DEX | `de4680a52f83c12f3b24628141e6d81b7f04a527dccd6fd3941adadf52755272` |
| Direct compiled source mutant | `4e0dedf56d76e841a4c002c4a59fecfbd0b3ca15b8efe07b9cc5f8f90a17ecd9` |
| Managed compiled source mutant | `ca58685820410237118b4d6ba074560a35ab06395c64965fa00333a5da8254e4` |
| Independent observer DEX | `470ef44862209a707e77fd1505deaa13b15d0a854745984ccaf1546c3fbff54a` |

These local source checks used the exact retained executable/SDK-independent
observer tools through explicit commands. The complete portable verifier has
been parsed, but cannot run its frontend Git identity gate against the local
bootstrap archive, which lacks a Git checkout. The hosted workflow checks the
pinned frontend checkout before running the same producer and controls.
No local adb/emulator is available; null/non-null runtime results and designated
mutation rejection therefore remain pending.

The workflow adds one separate API23 emulator step in the API29 job, reusing
only these candidate bytes. It preserves the existing API29/API34 framework
suite boundaries. Each observer checks exact API, emulator and ABI, compares
pushed/pulled bytes, and captures bounded before/after logcat even on failure.

The first hosted API23 observation did not execute its candidate: API23 adbd
refused the observer's `shell -T` transport with `device only supports
allocating a pty`. Its API29 and API34 observations did execute successfully.
The observer now forces the API23 PTY transport, normalizes CR line endings,
and requires exactly one explicit remote process-exit marker in addition to
the expected semantic assertion. Transport failure, a missing/duplicate exit
marker, an unexpected remote exit, timeout or process death remains failure;
before/after logs are retained. API29/API34 keep the shell-v2 exit protocol.
Parsing that revised Grease helper passes locally; actual API23 execution
remains pending a new hosted run.

Fallback: none. ART/device/whole-Activity acceptance remain NOT_RUN until
separately executed against exact emitted bytes.

## First language work

Add the narrow checked pure intrinsic, typed reference-null conditional,
shared placement/encoding/rendering, and actual source/null-nonnull/refusal
qualification including the preserved minimum API23.
