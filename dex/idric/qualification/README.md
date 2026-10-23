# Retained executable compiler fixtures

These immutable DEX files are compiler/encoder acceptance artifacts, not an ICU
Android package. `checked-calls.dex` is the actual checked Idriç call fixture;
`observer.dex` is the independent ai-ci caller; `wrong-helper.dex` is the
compiled deliberately faulty source; `shared-classes.dex` exercises shared
checked/native class metadata. Source pins, hashes and execution boundaries
are in ../reconciliation-receipt.tsv.

The observer executed 43 assertions against checked-calls.dex on API 29 x86-64
ART and rejected wrong-helper.dex with status 73. The received candidate bytes
matched the built bytes. Shared native class metadata was independently
decoded on the host. No physical-device or real ICU execution follows from
these fixtures.
