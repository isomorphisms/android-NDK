# DEX runtime #33 / managed-export + ICU #30 integration checkpoint

Integration branch: `dex/integrate-runtime-icu-33-30` (draft only, not a release or a merge to `main`).

| Input | Exact commit | Evidence |
| --- | --- | --- |
| Qualified runtime PR #33 | `51fb9d795bc68cf39a3c33c0a171f4a509d6755b` | Independent host, source and ART on API 29/34; see PR #33 and runs 40537215013, 40537214945, 40537214799 |
| Managed exports / ICU PR #30 | `88c74366c664f696e3128ce1331bb7980e416a60` | Local emission evidence. Exact-head canonical workflow 40433507164 **failed before backend compilation**, after cache restore: `Module IdrisPaths not found` |
| Actual merge base | `973c24bc0b4eab6f3c88699102f7cb0e7fd8951f` | Changes compared to the same ancestor, not independently to `main` |

## Tree comparison

From the actual merge base: **80 runtime-only** differing paths, **29 ICU-only**
differing paths, and **6 paths independently edited on both branches**.
Shared PR paths inherited from common history, including committed generated
DEX bytes and qualification receipts, are not competing changes in this merge.

Independently edited paths:
- `.github/workflows/dex-reconcile.yml`
- `dex/idric/README.md`
- `dex/idric/RECONCILIATION.md`
- `dex/idric/backend.ipkg`
- `dex/idric/src/Backend/DEX/Codegen.idr`
- `dex/idric/src/Backend/DEX/Heap.idr`

## Semantic resolutions

- **Codegen:** preserve #33's checked, capability-selected managed command,
  native-service/closure pruning, direct tail groups, JNI contracts and
  stale-candidate invalidation. Extend managed-method lowering with #30's
  explicitly checked foreign bridges. Preserve `managed-exports` and the
  automatically selected pure Text export without restoring the obsolete
  `getArgCount` name heuristic.
- **Heap:** retain #33's checked constructor layouts, partial applications,
  simultaneous tail transfers, high arity and native boundary contracts.
  Add #30's Unicode-aware reverse/tail/cons and pure Text wrapper. No duplicate
  alternate heap runtime.
- **Package:** include `ManagedBoundary` with #33's `Capabilities`,
  `NativeContract` and `ValueLayout`.
- **Workflow:** preserve #30's independent managed-export, pure Text,
  new-Intent and ICU stages. Use #33's source-pinned Grease build,
  qualified ICK cache and frontend path-metadata repair in canonical CI.
  The separate `dex-runtime-repair.yml` stays untouched and remains
  independent of ICU/OpenSSL; canonical DEX/ICU checks must pass separately.
- **Generated outputs:** preserve existing blob identities from runtime
  head, graft ICU-only inputs and observers by original blob identity.
  No old DEX digest is adopted as merged-head acceptance evidence.

## Exact-head acceptance obligations

- [ ] Pinned Idriç builds integrated `backend.ipkg`.
- [ ] Standalone runtime/JNI/ART API 29 and API 34 and compiled mutants PASS.
- [ ] Canonical host/source and API 29 ART PASS for checked core, managed
      exports, pure Text, new Intent, framework behavior and mutants.
- [ ] ICU/JNI preparation and API 29 transport ART PASS.
- [ ] Receipts identify the integration commit; neither parent's PASS is
      silently inherited.
- [ ] PR #33 and PR #30 branches and historical acceptance records unchanged.

Physical A1/C67 APK installation is not inferred from hosted emulators.
No automatic merge or release.
