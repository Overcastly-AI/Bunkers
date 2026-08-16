# BUNKERS

A public register of hardened, buried, and continuity-of-government facilities in the United States,
where every entry is graded by **the quality of the evidence behind it** rather than asserted as fact.

Not a map of secrets. A map of *what can be established, from what, and how well*.

---

## Premise

Far more of this material is public than people assume. It is simply scattered, unindexed, and boring.
Declassified CREST holdings, DTIC technical reports, GAO audits, NEPA environmental impact statements,
FCC antenna registrations, USGS historical topographic quadrangles (which draw tunnel adits that modern
maps omit), federal property disposal records, and appropriations line items are all open records.
Correlating them is nobody's full-time job.

Evidence sorts into three categories, and the system's entire purpose is keeping them **visibly
separate**: *documented*, *inferred from open signals*, and *claimed*.

Folklore is not excluded. It is admitted to the register and then sourced **backwards to its origin**.
A claim repeated across 400 websites is not 400 sources; it is usually one source and 399 copies, and
the register is built to say so out loud. Entries shown to be empty are **retained with their
refutations attached** — a register that can demonstrate *why* a famous claim is hollow is more useful
than one that quietly omits it.

## Status

**Foundation phase.** No application yet. The grading model is being built and stress-tested before
any data is collected, because a register scored by a broken rubric is worse than no register.

| | |
|---|---|
| Sources catalogued | 158 across 5 research beats |
| Grading model | v0.1 superseded — 10 fatal defects — v0.2 in adjudication |
| Calibration suite | 32 cases and growing |
| Candidates | **0** — collection does not begin until the model survives review |

## Repository

```
docs/WORKFLOW.md          Project architecture. §1 and §2 carry correction notices.
docs/GRADING.md           The authoritative scoring model. (in progress)
docs/CALIBRATION.md       Regression suite: known facilities, expected grades. (in progress)
docs/SOURCE-REGISTRY.md   The 158 sources: access methods, formats, queries. (in progress)
docs/SCHEMA.md            Data model explained. (in progress)
docs/FOUNDATION-REPORT.md Honest assessment of what stands and what doesn't. (in progress)
supabase/schema.sql       Executable DDL. (in progress)
research/raw/             Verbatim agent output. Primary record — see its README.
```

## Method

Research is performed by agent fleets working distinct source modalities, with an adversarial
adjudication stage between discovery and publication. Every quantitative claim about a candidate must
be assignable by an agent from evidence in hand; a model requiring judgement it will never receive is
worthless at this scale.

The grading model is itself subjected to adversarial review before use. v0.1 was condemned by two
independent reviewers — an archival historian and an intelligence analyst — who found, among other
defects, that a conclusive declassified primary document scoring alone would land in the grade band
labelled *"folklore with a trace."* Those critiques are preserved in `research/raw/`, and the defect
list is recorded in `docs/WORKFLOW.md` rather than deleted.

## Operating rules

- Scraping respects `robots.txt` and rate limits. Archives are cached so they are hit once.
- Every claim carries a citation. No orphan facts.
- Nothing is deleted. Refuted entries stay, with reasons.
- Confidence is versioned. The register shows how a grade moved and what moved it.
- Corrections are published, not quietly applied.

---

*Open-source intelligence research over public archives. Built for a community, no login, no accounts.*
