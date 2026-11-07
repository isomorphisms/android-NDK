# Exact package rounding at the DEX runtime boundary

## Type sketch, written before source

Input is an Int32 observation boundary: nonnegative grams needed; negative input
is rejected with -1. Internally the computation uses Number, exact division by
the positive whole package amount 300, and a ceiling. Output fits Int32 because
the package count cannot exceed the nonnegative Int32 input. No floating point,
generated C, source recognizer or retailer fixture supplies the result.

`packages : Int32 → Int32` is exported as a scalar DEX method. This small program
reduces Green Grocer's actual `RecipeShopping.package_count` rejection to the
recursive `Data.Nat.div'` helper reached through `divNatNZ`. It preserves the
Number arithmetic that the application needs rather than moving rounding to C.

Required examples: -1 → -1, 0 → 0, 1 → 1, 300 → 1, 301 → 2, 500 → 2,
600 → 2, 601 → 3. Host execution controls source meaning. A separately assembled
ART caller must observe those same values in source-produced DEX. Candidate
DEX emission, source checking and host execution are distinct evidence.

## Result

The reduced source checks and executes on the host with exactly
`-1, 0, 1, 1, 2, 2, 2, 3`. Its actual direct-DEX invocation rejects
`Data.Nat.div'` with exit 1 and no candidate DEX using frontend
740bbf2b1d9e811fd00c719c3473eede17ceea3b and backend
de29100e9b24b5bbc85aca7f77cd3b08c0934917 plus a parser-only rename of two
reserved `prefix` bindings in Placement.idr. Exact file hashes and logs belong
to the consumer receipt and the local `evidence/` directory. Run
`check-emission.grease` with absolute repository, frontend, current driver and
fresh output paths to reproduce the still-failing emission obligation. The
independent `PackageRoundingObserver.smali` has not been assembled or executed
in this environment; no Android acceptance or APK is established.

The parser-only fixes also repair the layout of the existing RuntimeArgsTest
mutation expression. After that repair its host encoder/refusal suite executes
successfully. These are host checks, not fresh ART runtime qualification.

The next capability is checked runtime lowering of the exact recursive numeric
helper and its Number operations. Preserving Number's full meaning is required;
silently narrowing it to Int32 is not a repair. This test remains a failing
acceptance obligation until actual source-produced DEX passes the ART observer.
