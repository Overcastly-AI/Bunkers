# Ratified decisions

Decisions the project owner has made, with the reasoning and the consequence. Recorded here because
several of them change what a grade *means*, and a register that cannot show what it decided and when
has no standing to grade anyone else's sources.

---

## D-001 · Geographic scope: US-first

CONUS first. Archive access is strongest there — CREST, DTIC, NARA, FPDS, USGS quads are all
US-centric — and it is where the rubric can be validated against ground truth we can actually check.

**Consequence:** the schema is country-agnostic from day one so expansion is additive rather than a
migration. The FOREIGN discovery beat is designed but dormant.

---

## D-002 · Stack: Next.js on Vercel + Supabase (Postgres/PostGIS) + MapLibre GL

**Consequence:** a dedicated Supabase project (`fsszjobpykbpmctlzxiv`) rather than a schema inside an
existing project. This app is public with no login, so the anon key ships in client-side code; a
separate project means one misconfigured RLS policy cannot reach unrelated data.

---

## D-003 · W1 is continuous and broad, not a themed one-shot

The register is an accumulating database, never a finished report. Coverage deepens over successive
cycles; the COMPLETENESS CRITIC sets each next cycle's targets.

**Consequence:** every candidate is provisional and versioned from the start. Grades move as evidence
lands, and the database records the movement rather than the current value alone.

---

## D-004 · v0.1 grading rubric superseded by BES v0.2

Three adversarial reviews — archival historian, intelligence analyst, disinformation skeptic — returned
*restructure, not patch*. Sixteen fatal defects. The decisive one was arithmetic: under v0.1 a
conclusive declassified primary document, scoring alone, landed at 28 — grade E, *"folklore with a
trace."* The grade bands described evidence **kinds** while the formula measured evidence **breadth**.

**Consequence:** grading moved from places to propositions, evidence acquired a sign, and diagnosticity
replaced presence-scoring. The v0.1 text is retained in `WORKFLOW.md` under a supersession notice
rather than deleted. Full defect list and resolutions in `GRADING.md`; the eight points where reviewers
disagreed with each other are recorded with the decision taken.

---

## D-005 · Corroboration is a graph property, not a count of agents

The original fleet claimed that discovery agents being blind to each other created the independence the
corroboration axis measured. That is a category error, and it was load-bearing: **agent independence is
not source independence.** N agents searching the same indexed web surface the same single source and
score it as N-fold corroboration. The fleet was manufacturing the exact false corroboration the register
exists to expose.

This survived into the schema proposals. One implemented "a graph property, not a `COUNT(*)`" as,
literally, a `COUNT(DISTINCT)` over an agent-writable column — four copies of one document, written with
four lineage ids, would have counted as four independent lineages and opened grade band B. It was
rejected for this.

**Consequence:** blind fan-out is retained for **recall only** and contributes nothing to corroboration.
Independence is computed as connected components over citation edges, downstream of discovery.

---

## D-006 · Single model family, with the limitation published

*Decided 2026-08-17.*

The register runs W1 with one model family. Two families would make entailment checking genuinely
adversarial, make the two-family agreement requirement real, and make double-scoring a measurement
rather than a self-check. One family collapses all of that.

**This decision cannot be retrofitted.** A grade produced under single-family verification and one
produced under two-family verification are not the same object, and there is no honest way to
distinguish them after the register is populated. It is therefore made before the first grade is
written.

**Consequence — and this is a publication obligation, not a footnote:** the register must state on its
methodology page that its second line of defence is **self-verification, not independent verification**.
That claim is *absent*, not merely weaker. The mechanisms that do not depend on model family —
resolve-or-die, subject binding, the diagnosticity catalog, the caps — remain fully in force.

---

## D-007 · Network egress must be widened before W1 can publish

*Decided 2026-08-17.*

Outbound egress is currently denied in full: the proxy answers `403` to `CONNECT` for every host, and
`WebFetch` returns `EGRESS_BLOCKED` for `catalog.archives.gov` and `ngmdb.usgs.gov`. Only `WebSearch`
functions, returning snippets — never the source document.

The verification tier therefore cannot resolve a single citation to bytes. The project's own integrity
rule was found to be a test for the *presence of a citation string*, which a confabulating LLM satisfies
100% of the time; resolve-or-die is the fix, and resolve-or-die requires egress.

**Consequence:** the 158-source registry was built entirely from search snippets and has never been
tested against a live endpoint. By the register's own standard the whole of W0 is **V0-UNRESOLVED**.
The owner is widening the network policy; `EGRESS-ALLOWLIST.md` carries the 122 hosts. Until that
lands, W1 can build and exercise the pipeline but cannot publish a graded candidate.

---

## Standing rule

Nothing is deleted. Refuted and F-grade entries are retained with their refutations attached, and
corrections are published rather than quietly applied — including corrections to this project's own
reasoning.
