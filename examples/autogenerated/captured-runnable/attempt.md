# A checked source action retained by Runnable

## Real program and meaning

AVE needs a per-request callback that retains a typed source action after its
factory returns, then runs that action when the platform dispatches `run()`.
The existing callback bridge can forward its Activity receiver but captures no
request. The existing managed closure representation already retains checked
source records/lists/ADTs; it must remain the owner of that meaning.

The first program captures a `CapturedJob` containing a mode ADT, Text and a
List Text, together with a real platform StringBuilder sink. It returns an
ordinary Runnable reference. Creation must have no sink effect. Two different
jobs must retain distinct data; real platform dispatch later appends the right
text, including a repeated dispatch and a cross-thread dispatch. No app-specific
native callback body, shared global request slot or handwritten candidate
methods may replace the source action.

## Type sketch before compiler work

- Proposed bounded factory: `capture_runnable : IO () → PrimIO RunnableReference`.
- `RunnableReference` is a validated external `java.lang.Runnable` domain.
- The argument is a private managed checked IO action, never an arbitrary
  Object foreign ABI or serialised Text payload. Its World argument is supplied
  only when `run()` executes; the returned IORes is ignored for Runnable's void
  contract.
- Proposed explicit convention marker: `dex:capture-runnable`. It admits only
  this source action shape and effectful factory result. Ordinary static,
  virtual, constructor and callback metadata retain their existing rules.
- A generic synthetic Runnable class may privately retain the existing managed
  closure. Its bridge must reuse the existing checked apply dispatcher and
  preserve the per-instance reference. This is compiler/runtime representation,
  not a new application state model or JNI ownership policy.
- No public ADT/function ABI, arbitrary subclass model, unchecked field surface,
  captured Activity lifecycle, cancellation, IORef semantics or source exception
  handling is implied by a captured Runnable pass.

First establish the exact source/CFType boundary with the real program below.
Then implement only the required generic factory and its private class/field
machinery through the maintained typed writer. Preserve refusal controls for
wrong action/effect/result types. Candidate bytes must come from checked source;
Smali may supply only the independent runtime observer.

## Preserved first attempt

At backend `fe74f72`, exact retained frontend
`740bbf2b1d9e811fd00c719c3473eede17ceea3b` checks the source successfully (exit
0). The existing integration driver (SHA256
`56ba11e24ad9fc1a5060ad0730af5e6d617e44dbfb503759f8ac7f93c3fa4d9d`)
rejects emission with exit 1 and no DEX:

```text
Error: dex rejected foreign declaration: Missing dex foreign owner
```

The same invocation with `--dumpanf` records the actual checked metadata:

```text
CapturedRunnable.capture_runnable = Foreign call ["dex:capture-runnable"] [PrimIO.IO Unit, %World] -> IORes CapturedRunnable.RunnableReference
```

The checked `make_captured_runnable` constructs the record/list, then returns a
World closure; its action argument is another checked partial application
retaining the record and sink. `PrimIO.IO Unit` is the exact `CFUser` source
shape, rather than a platform Object or an arbitrary function ABI. Optimization
has removed the IO newtype wrapper around its private World closure. The new
operation will accept this shape only and retain that existing closure.

Local evidence directory is `captured-runnable-local/initial` outside the
repository. The first attempt is this unchanged source plus the failure above;
there is no fallback program.

## Implemented boundary

The explicit factory now accepts that exact shape, validates the external
Runnable result and selects the managed path when reachable. The generic
synthetic class retains one private final managed action reference; `run()`
reuses the existing checked apply dispatcher. A factory creates a new object
for each call and performs no source action. Source ADTs/list/Text remain
private checked values. No Heap change, JNI method or native body was added.

Typed instance object accesses use the maintained placement/encoder. Static
and instance field declarations are checked separately. High source/receiver
registers use two disjoint scratch slots, including aliased operands. The
same finalized multi-class graph produces binary and readable evidence.

The host plan qualification explicitly uses `covering` because the imported
bootstrap encoder is covering; this does not alter the candidate source's
totality contract. The first legacy-host run failed to write its relative
`build/argv-boundary.dex` because the harness ran it from the scratch root.
The harness now runs each compiled host program in its own evidence directory;
the source and writer were unchanged for that correction.

## Local result

The full backend typechecks and its Chez driver compiles. The unchanged source
emits 8,220-byte DEX with SHA256
`9335de9088183a4633c2839c91deb76df183e41de953e88d98eb4aadbb71d2ba`.
Repeat emission is byte-identical. Independent baksmali decoding shows both
Generated and the real Runnable class, its private final field, constructor
store and `run()` calling `__idricApply`. Reassembling both readable finalized
class outputs gives identical independently decoded methods and fields.

Host metadata/placement/writer qualification and the existing argv/static-field
qualification both pass. Wrong action, wrong action result, pure factory,
scalar result and ordinary ADT result fixtures all check as source and refuse
DEX with exit 1. The two source mutations emit distinct DEX:

| Candidate | SHA256 |
| --- | --- |
| Original-order mutation | `6abd7a119193be413904d728cc70f892c50a111aed074e473e3ebad17c3de3eb` |
| Text mutation | `439fa07c525bbfc3ef61f153a40cd8a35a1bf0cf337523ae4f3774c79197e186` |
| Initial independent observer | `576bbcb5aee6b25d4e2fb731e07d9f8fea12d40abc79254ace445217dfdbb245` |

The exact retained Grease parses both helpers. The verification helper takes
the source frontend repository separately from its retained runtime tree and
receives the exact Chez binary/heap directory explicitly, so relocated runtime
paths are not confused with source revisions. It pins frontend `740bbf2...`,
records driver/source digests and keeps host, emission and ART receipts apart.

The complete `verify.grease` execution exits 0 in
`captured-runnable-qualification-fixed`, including both host programs, both
source mutations, all source refusals, deterministic bytes, independent
decoding, readable-output round trip and observer assembly. The host directory
correction above is retained as a harness failure, not a source/runtime gap.

PENDING: real platform ART observation. No remote write, APK/widget run or
physical-device run was performed by this task.

## Observer assertion/termination correction

The initial harness is preserved in commit
`06b93d8ea17c2fcbd6c996257fe3e543ca7b449c` and by its observer digest above.
It allowed an arbitrary nonzero mutant exit except timeout/137, then required
the observer's AssertionError text on stderr. The separate callback-result
API34 failure exposed why that is insufficient under `app_process`: an uncaught
Throwable can be written to logcat and followed by process self-termination.
No captured-Runnable ART failure is claimed from that separate result.

The independent runner now catches its assertion failure at main, prints the
exact stack trace and exits 93. Other Throwables print and exit 94. Positive
checks and their order remain unchanged. Mutant lanes require exactly 93 and
the existing exact assertion message; signal-style death, timeout and unrelated
exceptions cannot become a successful mutation rejection. The observer retains
bounded before/after all-buffer logcat, separate stdout/stderr, actual process
and logcat status and a distinct process name before checking any lane result.

The corrected runner assembles and independently decodes with both ordered
catch handlers and designated exits. Its SHA256 is
`81cea22adc1e252f930cb78eec20188d6ff7708453e75eba8fcc19b8e44f4959`.
The changed observer parses with the exact retained Grease runtime. Candidate
source/compiler files are unchanged; a fresh source emission remains
byte-identical to the original 8,220-byte candidate. ART is still pending.
