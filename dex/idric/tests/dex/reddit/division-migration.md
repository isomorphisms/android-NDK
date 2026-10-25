# JNI arithmetic compiler

The query-size overflow guard in `reddit_cli.c` uses literal binary `÷`.
The C frontend is ICK `c61e448251744a2f40ad743ebef1a027bdcd2f9d`, with
the same unsigned division semantics as `/`. JNI descriptors, URL strings
and slash character literals retain their bytes.

The workflow builds each of the three maintained JNI ABI frontends through
`ai-ci/ick-android@903b2cb27ea572c9c6cb2ffa9f39e0fbf06ec9f8`, using the
existing NDK `26.3.11579264`. ICK emits assembly; that declared NDK assembles
and links the API24 shared libraries. Compiler builtin headers precede Bionic
headers and both Android API macros have the same value. No NDK C fallback
is permitted. Stage archives preserve executable bits and qualification
receipts, and restoration checks the compiler target.

The shared C-stage contract is required before the workflow continues. It
governs the JNI C producer only: direct Idriç DEX emission and ART execution
retain their independent implementation and acceptance paths. The existing
DEX-to-JNI emulator checks and phone/tablet package identity checks remain.
No ARM backend or QEMU path is introduced into direct DEX lowering.

Local supplemental evidence: the changed full AArch64/API24 JNI library
compiles with warnings as errors, assembles and links using available NDK
r27c; its exported JNI entry point passes inspection. Branch separation
passes. Exact r26d compilation is required in the hosted workflow and is not
claimed from that r27c result. Compilation and emulator acceptance do not
establish physical-device execution or a new Reddit network/account result.
