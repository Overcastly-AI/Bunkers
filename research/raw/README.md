# research/raw — verbatim agent output

Structured JSON returned by research agents, **unedited**. This is the primary record. The documents in
`docs/` are consolidations *derived* from these files; where the two disagree, these win.

Preserved verbatim for three reasons: the consolidation step is lossy, a register that grades its
sources on provenance must be able to show its own, and the run that produced these was interrupted —
recovering them from an ephemeral container's journal was only possible because the raw returns existed.

## Contents

### Source registry — 158 sources across five beats

| File | Sources | Beat |
|---|---|---|
| `registry-federal-declassification-and-technical-archives.json` | 24 | CREST, DTIC, NARA, GovInfo, GAO, DOE OpenNet |
| `registry-geospatial-cartographic-and-geological-sources-*.json` | 26 | USGS historical topo, TNM, LiDAR, mine registries, FAA airspace |
| `registry-money-property-procurement-and-environmental-filings-*.json` | 37 | FPDS, USAspending, GSA, MILCON, NEPA/EIS, land records |
| `registry-infrastructure-communications-power-water-and-fuel-*.json` | 31 | FCC ASR, AT&T Long Lines, HIFLD, grid, water rights, generator permits |
| `registry-local-record-oral-history-and-the-fringe-corpus.json` | 40 | Newspaper archives, oral history, obituaries, and the fringe citation ecosystem |

Each source records holdings, provenance tier (P1–P5), access method, format, rate limits,
robots/ToS posture, which evidence axes it serves, and the specific query techniques that surface
relevant material. Each beat also records its **gaps** — what that beat cannot see. Those matter as
much as the holdings.

The fringe registry is deliberately not a catalogue of claims. It maps which communities, books, and
individuals are **origin points** versus pure aggregators — the terrain needed before any claim can be
traced backwards.

### Adversarial critiques of the grading model

| File | Verdict |
|---|---|
| `critique-archival-historian-*.json` | **Restructure, not patch.** 14 failures, 6 fatal, 15 calibration cases |
| `critique-intelligence-analyst-*.json` | **Restructure, not patch.** 10 failures, 4 fatal, 17 calibration cases |

Two reviewers, working independently and blind to each other, converged on the same core defects —
including that the rubric graded *places* while evidence attaches to *propositions*, and that it could
not encode disconfirmation at all.

Each critique carries a `calibration_set`: real named facilities and claims paired with the grade they
*should* receive. Merged and deduplicated, these become the regression suite in `docs/CALIBRATION.md` —
the mechanism for detecting rubric drift as the model evolves.

## Reading these

```bash
jq '.sources[] | select(.value=="critical") | {name, access_method, url}' registry-*.json
jq -r '.failures[] | select(.severity=="fatal") | "\(.problem)\n  FIX: \(.proposed_fix)\n"' critique-*.json
jq -r '.calibration_set[] | "\(.expected_grade)\t\(.name)"' critique-*.json | sort
```

## Provenance

Produced by workflow `bunkers-w0-foundation` (run `wf_6eb124f9-3fe`, 675k tokens, 328 tool calls).
Seven of twelve agents completed; five were killed mid-run by a session usage limit, including the
synthesis agent that was to write `docs/`. These seven returns were recovered from the run journal
before the container was reclaimed. The consolidation was completed by a later workflow.
