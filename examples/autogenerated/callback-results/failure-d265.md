# First hosted callback-result ART failure

The exact first run is
[isomorphisms/android-NDK runtime-repair run 43804750228](https://github.com/isomorphisms/android-NDK/actions/runs/43804750228),
[API34 job 133092945764](https://github.com/isomorphisms/android-NDK/actions/runs/43804750228/job/133092945764),
at source `d2651550b08116d99b1b2295ed027dfc6dd0d383`.
The retained
[artifact 14198349382](https://github.com/isomorphisms/android-NDK/actions/runs/43804750228/artifacts/14198349382)
ZIP SHA256 is
`d7357e59e24e2652781e426c53a5720f530d0be49d8c3a7f9d54db03b1440337`.
The downloaded ZIP matches that digest.

The runtime and binary64/Int32 stages pass before the callback stage. At
05:05:58 the positive candidate and observer are pushed and read back. At
05:05:59 the observer exits with these exact retained files:

```text
callback-results/art/positive.exit: 137
callback-results/art/positive.txt: Killed
```

That shell status conventionally corresponds to signal 9. It does not identify
the origin of the termination. In particular, an Android uncaught-exception
handler can kill the process after writing its exception to logcat; the word
`Killed` alone does not prove memory exhaustion or a native crash.

The archive contains no callback-stage/global post-callback logcat, tombstone
or kernel log. Its retained `native-art/*.logcat` snapshots all predate this
callback process. The job console contains no first Throwable. Therefore the
existing evidence cannot establish a hidden-API failure, invalid context,
Button/theme exception, source callback defect or resource kill as the cause.
The Float32 ART stage was skipped after this failure; its earlier emission
does not become ART acceptance.

## Focused diagnostic repair

The observer now retains bounded before/after snapshots of all logcat buffers,
separate stdout/stderr, the actual process status and the logcat statuses for
every candidate, before checking success or mutation rejection. It records
signal-style shell status as an inference, distinguishes a 60-second host
timeout, uses a distinct process name and enables JNI checking. It preflights
the exact API29/API34 x86_64 emulator before remote mutations. It does not
clear unrelated process diagnostics.

The independent runner keeps every callback assertion and the same context,
widget and receiver setup. A small main wrapper prints the first unexpected
Throwable to stderr and exits 92; stage markers identify the last completed
setup/dispatch boundary even if a signal prevents exception printing. Positive
success still requires exit 0 and the original PASS line. Both compiled source
mutations still require exit 91 and the original FAIL line. Exit 92, signal
termination and timeout remain failures.

There is no context or permission workaround in this repair. If the next
retained exception identifies the system-context bootstrap as the failure,
the next fixture change must use the existing public normal-Activity/
instrumentation path. A guessed replacement is not a qualified correction.

The changed observer parses with the exact retained Grease runtime. The
changed independent runner assembles with the pinned Smali oracle. These are
local syntax/assembly results; the focused ART rerun is still pending.
