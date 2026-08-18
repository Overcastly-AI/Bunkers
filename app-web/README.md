# app-web

The BUNKERS register interface. Implements `docs/DESIGN.md` v1.0.

Kept out of the repository root so `docs/`, `db/`, `supabase/` and `research/` stay clean.

```
npm run build       # production build; every route prerenders as static
npm run dev         # development server
npm run typecheck   # tsc --noEmit
npm run seed:check  # the seed's own acceptance suite (see below)
```

**TypeScript is pinned to 5.x.** Next 15.5 cannot load a TypeScript config under
the TS 7 native compiler — `next build` fails with
`Cannot read properties of undefined (reading 'fileExists')`. Do not bump it
without re-running `npm run build`.

---

## What is here

```
src/app/
  tokens.css              §2 voices · §3 type scale · §4 colour · §5 spacing/grid · §11 plate
  globals.css             the base layer: materials clause, document grid, running head,
                          standing foot, tables, print
  layout.tsx              running head · contents line · standing foot (carries D-006)
  page.tsx                `/` — the register: masthead, state-of-the-register, status line,
                          the empty-state block

src/lib/types/
  enums.ts                every core.* enum, transcribed from supabase/schema.sql §2
  api.ts                  a type per api.* view, column for column
  grade.ts                band words, grade_rank, the scope-and-content composer

src/lib/seed/
  types.ts                the authoring spec — deliberately NOT the api shape
  membership.ts           the GENERATED columns, recomputed (membership, exclusion_reason,
                          signed_weight, the §3.4 gate)
  dsl.ts                  `ev()` and the receipt constructors
  build.ts                spec -> api rows, including a transcription of core.render_geometry()
  entities/*.ts           30 specimen entities
  cases.ts                49 case ids + the 8 suite-level assertions + the known-wrong table
  index.ts                assembly, containment, REGISTER_STATE
  verify.ts               the seed's acceptance suite

src/lib/repository/
  types.ts                the Repository interface — the single seam the UI reads through
  seed-repository.ts      backed by the local seed. The default.
  supabase-repository.ts  stubbed. No client, no key, no network call.
  curated.ts              the corpus subset and the ERP table
  index.ts                getRepository()
```

---

## The two rules that hold this together

**Rule Zero, in the data layer.** A specimen author declares observations; the
builder counts them. `v_count`, `u_count`, `v0_count`, `inert_count`,
`v_claim_count`, `place_derived_weight` and `claim_derived_weight` are
`filter().length` and `reduce()` over the same array the page renders
underneath. There is no field to write a count in, so no mark can exist without
a row. Grades, ceilings, caps and limiting conditions ARE declared, because they
are the calibration suite's expected values — a fixture that graded itself would
assert nothing.

**Containment is structural, not conventional.** The register surface and the
specimen surface are different methods on the repository returning different
types. `getEntry()` returns `null` for every specimen slug and there is no
fallback; `listCalibration()` returns sheets that carry their containment block
— namespace, robots directive, header rule, hatched margin, aria prefix — already
filled in. `verify.ts` asserts the leak is closed on every build.

---

## Switching to Supabase

Two independent conditions, both required:

```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
BUNKERS_DATA_SOURCE=supabase
```

A stray variable in a preview deployment must not silently point a register with
zero candidates at a live database whose RLS posture has not been verified
(D-008). The header comment in `supabase-repository.ts` carries the six things to
check before wiring it.
