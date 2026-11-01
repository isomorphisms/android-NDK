# Retained attempts to isolate the real reader's trailing World closure

These five checked source attempts emitted and decoded successfully, but the
frontend retained the full direct World parameter in each tested export. They
therefore do not isolate the undersaturated export reached by the actual IB
reader. They are retained as attempts, not promoted as proof of that repair.

The variants add signed SDK branching, a checked Text/Either request, noinline
boundaries, a stored IO action, and a tail PrimIO Unit assignment. All keep the
same external SDK counter domain and checked IO/foreign boundary. Original
positive source bytes were recovered from the source-bound compiled-mutant
inputs by reversing the one documented amount-to-1 mutation, then checked
against each positive source SHA-256 recorded by that exact host run. Every
recovered source digest matched. Their module names remain ExportAliases; the
descriptive snapshot filenames are not the active producer entrypoint.

The maintained IB Activity is the concrete undersaturated consumer: its public
reader_follow_link takes Activity/Text, its checked prefix returns a closed
World action, and the new bridge applies that final token through the shared
dispatcher. Host emission/decode passed without rewriting the aliases. Actual
ART/link-event acceptance of that consumer is still required; successful fully
saturated SDK-counter fixtures alone cannot provide it.
