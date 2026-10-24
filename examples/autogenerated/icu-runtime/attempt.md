# Execute checked ICU on ART

The input is ART's actual argument array. `System.getArgs` must retain its
checked library implementation, including its synthetic executable name,
64-bit indices, range construction, traversal and ordered IO. The output is
ICU's actual response bytes and process status, through the existing JNI
transport. The application must not be replaced with a handwritten client.

## Types and runtime representation

Checked ANF functions retain all their live arguments, including erased values
and the World token. Internal managed values cross internal method boundaries
as Object. Text remains String. Whole numbers and machine integers use
BigInteger storage; every fixed-width arithmetic/cast operation must restore
its declared signed or unsigned width. Constructors retain their checked name
and fields in a managed node; partial applications retain the checked target
and captured arguments. Applying a closure copies its captures, so reuse cannot
mutate an earlier closure. World is an erased token; evaluation order comes
from the checked ANF bindings, not from treating IO as a pure expression.

Source functions, constructor matches and closure dispatch are lowered to the
existing typed FilePlan/MethodPlan and canonical Backend.DEX.Encode. Platform
collections and BigInteger provide storage and arithmetic, not application
semantics. No second DEX serializer or source-generator fallback is permitted.

Foreign services are admitted by checked declaration and signature. Argument
count/access reuse Backend.DEX.RuntimeArgs. JNI transport retains ICU's native
HTTP/TLS implementation. Unsupported primitives or foreign declarations must
produce a nonzero compiler exit and no candidate DEX.

## Initial reproduction

Backend source: d555a95215e3ed533800ba2824a6fbbb9cf73d4c.
Frontend: 740bbf2b1d9e811fd00c719c3473eede17ceea3b.
Initial reproduction used ICU's default branch at
468355b780d17f9b0838c8ac975962596811c484 and Idric-Net at
d74a163962c4a73bf4dee527823f49126cf2ae99. The maintained JNI/capture continuation
is ICU b1c19dc281e5e7d3d326c9275093fb379bafd4bd with Idric-Net
b21801b72acb8ab835c297bbe298af8599550134. Qualification must use those retained
integration sources, including their unchanged src/Main.idric.

`icu-jni.tsv` explicitly links the checked C foreign declarations to the
maintained JNI symbols and their platform descriptors. The compiler checks
argument/result compatibility, keeps World ordered, rejects ambiguous mappings,
and checks 64-bit source integers before narrowing to JNI's signed 32-bit ABI.
The library path is supplied through the `icu.library` property and loaded by
ART; a missing library fails without selecting a replacement.

The real checked application exits 1 at `System.prim__getArgCount` without a
DEX. Its ANF also exercises runtime constructors, closures, recursive list
functions, strings, finite-width casts, output, exit and native transport.

Host generation, independently decoded DEX, ART execution, HTTP/TLS behavior,
packaging and each physical device remain separate acceptance results.
