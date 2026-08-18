# RESOLUTION NOTES — first discovery sweep

**Input:** `beat-cog.json`, `beat-comms.json`, `beat-folklore.json`, `beat-silo.json` — four discovery
agents, four distinct beats, searching **blind to one another**.
**Output:** `resolved.json`.

**49 candidates in → 48 candidates out.** One cross-beat entity merge. One refutation record folded
into a candidate. 19 candidates carry more than one genuinely independent origin. 28 rest on exactly
one. One rests on none that was actually retrieved.

---

## 0. The standing caveat, restated because it governs everything below

Not one citation in any of the four beat files was resolved to bytes. Every source is
`SEARCH-SNIPPET-ONLY`, `FETCH-BLOCKED`, or `CITED-BY-OTHERS-NOT-SEEN`. By this register's own
standard every claim carried forward is **V0-UNRESOLVED**.

This pass adds **no evidence of any kind**. It rearranges what four agents already reported. It can
therefore only ever *lower* confidence, never raise it — and in several places below it does exactly
that, which is the point. Where I say a lineage collapses, I am not reporting a new fact about the
world; I am reporting that what looked like several sources was already, on the beats' own
descriptions, one.

I have invented no identifier, no coordinate, no accession number and no date. Where a beat declared
an identifier unverified (the CLLI code `HGTWMDQ0010`, the DTIC accession on Raven Rock, the Iowa DNR
facility ID, the Loudoun permit numbers), that declaration is carried forward verbatim and the
identifier remains marked as a lead.

---

## 1. What I merged

### The one cross-beat entity merge

**RES-022 — the Notch, Bare Mountain, Hadley, Massachusetts.**
`beat-cog[10]` and `beat-comms[10]` are the same site. Same mountain, same town, same 1957
construction start, same 2 June 1958 operational date, same 8th Air Force Combat Operations Center
designation, same Westover Communications Annex alias, same ~40,000 sq ft over two levels, same Five
College Library Depository occupant. Merged without hesitation.

**And that merge is worth nothing evidentially.** The cog beat reached this site through the
continuity-of-government beat; the comms beat reached it through the hardened-communications beat.
They found the same Wikipedia article and the same regional Cold War survey pages. Two agents
searching the same indexed web found one source twice. The merged record's independent-origin count
is **2**, exactly what the better-sourced of the two beats said on its own, and not 4.

I have kept both beats' propositions, both mundane-alternative statements and the union of both
source lists inside the merged record, because they differ in useful ways (see §3, CONTRA-01 to -03).

### The one refutation folded into a candidate

**RES-033 — Mount Weather.** `beat-folklore[9]` carries it as a candidate. `beat-cog` carries the
"underground city" story in `refuted_or_hollow`. Same site, same claim, same origin: Richard Pollock,
*The Mysterious Mountain*, The Progressive, March 1976.

Both beats traced it to Pollock independently. **That is recall, not corroboration.** Two agents
following the same claim backwards through the same index arrive at the same 1976 article; the
article does not become better attested because two of my colleagues found it. The origin count
stays at **1**, with several hundred copies downstream — cog counted eight in a single result set.

### What I did *not* do

I did not merge candidates simply because they appeared in more than one beat's search space. The
only cross-beat duplicate in the whole set was the Notch. The four beats were well separated; the
duplication problem in this sweep is not between beats, it is *inside* the citation graph, and that
is §2.

---

## 2. What I refused to merge, and why

Ten refused merges are recorded in `resolved.json` under `refused_merges`. The ones that matter:

**The Safeguard triple (RES-036 / RES-037 / RES-038).** The Nekoma Missile Site Radar "pyramid",
Cavalier Space Force Station (PARCS), and Remote Sprint Launch Site 3 are three elements of one
programme in two adjacent North Dakota counties, sharing an era, a squadron lineage and a popular
name. They are distinct structures on distinct parcels with completely divergent present status: the
MSR was deactivated in 1976 and sold twice, PARCS is a currently operating Space Force installation,
RSL-3 is privately owned and toured. A merged record would be simultaneously abandoned, operational
and a tourist attraction. This is precisely the "two genuinely distinct sites in the same complex"
case, and it is the easiest error in the set to make.

**Oscar-Zero / November-33 inside the Grand Forks population (RES-045 ⊂ RES-046).** Containment, not
identity. Merging them would erase the only fact that makes RES-045 interesting — that these two
parcels were preserved while the population around them was demolished under treaty. Recorded as a
containment edge, and the resulting tension logged as CONTRA-06 rather than smoothed away.

**The two Denvers (RES-001 vs RES-025).** Building 710 at the Denver Federal Center — a real
earth-covered federal structure with a reported NRHP listing — and the claimed base under the Denver
International Airport terminal, which does not exist, twenty-five miles apart. Both arrived from
beats that never saw each other's work, one under the alias "Denver Federal Regional Center" and the
other as "the Denver airport bunker". Named explicitly in the file because an automated
name-similarity merge would join them and produce the single most damaging record this register could
publish.

**The Project Office chain and its five members (RES-012 vs RES-013…RES-017).** RES-012 is a
**system-scope** record whose extension is exactly the five stations. It is not a sixth site, and its
sources are literally the same source objects as its members'. I kept it, because the chain-level
claim — that these five form one programme — is itself a proposition worth grading. But it is flagged
so that no downstream process counts six candidates here with independent evidence at each. That
would multiply one researcher's website by six.

**Netcong is not a Project Office.** The comms beat caught its *own* search-tool conflation here and
recorded it as a finding against its process rather than against a source: a query naming several
candidate sites returned the Netcong CLUI entry among Project Office material and the summary
presented them as one set. Netcong is AT&T's underground network operations centre in northern New
Jersey with no troposcatter role reported. The exclusion is upheld. This is the best piece of
self-auditing in the four files and it deserves to be said plainly: an erroneously admitted sixth
member would have inflated the chain's membership and diluted every genuine member's grade.

**Buckingham / Spears Mountain vs the Cryptome "White Rock Road" facility.** Road-name proximity
only. The comms beat could not establish subject identity and flagged rather than merged. Upheld.
Proximity flags; it never merges.

**The four converted Atlas sites (RES-039 / RES-040 / RES-041 / RES-047).** Four states, four
squadrons, four owners. They share a typology, a conversion narrative and much of a marketing
vocabulary — but the shared vocabulary is a *lineage* fact about the descriptions, not an *entity*
fact about the places. Keeping the distinction clean is what lets §5 say something useful about where
that vocabulary came from.

**DIA and the Schneider numerology (RES-025 / RES-032) are NOT merged as entities but ARE pooled as
lineages.** One is a site claim, the other a non-located enumeration. Different objects. Same single
terminus. Their origin counts are pooled, not summed — the record carries an explicit `pooling_rule`
field. This is the sharpest illustration in the file of why entity resolution and lineage resolution
have to be separate passes: getting the entities right and the lineages wrong still double-counts.

### Records that should be split and were not

Three candidates arrived already collapsing distinct objects, and I have flagged rather than silently
kept them:

- **RES-042** covers Titan I Complex 2C (near Elizabeth, Elbert County) *and* Complex 2B (near Deer
  Trail) in one record; six former Titan I complexes remain in Colorado. Must be split before any is
  rendered as a pin.
- **RES-023** covers seven Missouri Long Lines repeater sites; **RES-046** covers 150 launch
  facilities and 15 alert facilities; **RES-048** covers nine launchers per squadron across three
  complexes. All marked `scope: population`. **A population must never be rendered as a pin.**
- **RES-047** is a converted Atlas F site the silo beat could not identify among the twelve 579th SMS
  sites at Roswell. The beat said so plainly — "WHICH ONE IS UNKNOWN TO ME" — and I have preserved
  that rather than picking one. It must not be pinned, and must not be silently merged with any
  enthusiast page for 579-1 through 579-12.

---

## 3. Cross-beat contradictions — recorded, not adjudicated

Eleven are logged in `resolved.json`. The three that change how the file should be read:

**CONTRA-01 — the Notch, lineage independence.** cog says: the wiki family is one lineage, six of its
members appeared in a single result set, and the currency claim rides entirely inside it. comms says:
"genuinely multiple and genuinely independent — USAF/AFHRA records, the college consortium's
institutional record, county land records for the 1989 sale, and regional survey work. This is what a
well-sourced entry looks like."

comms lists **three sources** on that candidate: Wikipedia, coldwar-ct/ma, and Grokipedia. None of
the four independent roots it names appears among them. Those roots are real and available in
principle; neither beat retrieved any of them. I carried cog's count and recorded comms's claim
verbatim beside it.

This is the most instructive disagreement in the sweep, and it is not really about Hadley,
Massachusetts. Two competent agents looked at one site and differed by a factor of two on
independence — purely by counting sources they *expected to exist* versus sources they *held*. Under
egress blockade those two quantities diverge enormously, and any register that lets the first stand in
for the second will systematically overstate its own footing.

**CONTRA-04 and CONTRA-05 — the same source tiered differently by beats that never met.** CLUI is P3
in cog and silo, P4 in comms, where comms states the ground: its entries are unsigned and carry no
citations. coldwar-c4i.net is P3 in cog and P4 in comms. These are not small discrepancies. CLUI
touches fifteen of the forty-eight merged candidates and coldwar-c4i.net touches eight. I have not
averaged them; I have recorded both and noted that only one of the two readings states a reason.

**CONTRA-06 — were all 150 Grand Forks launch facilities destroyed?** RES-046 says START I required
elimination of all of them by controlled explosive demolition, last on 24 August 2001. RES-045 says
November-33, in the same wing, was preserved under an arrangement permitting museum retention. Both
from the *same* beat, which is why it is a tension and not a dispute — and the beat named the record
that resolves it (the START implementation record, which nobody in the popular corpus consults). A
preservation exemption is very likely. "Very likely" is not a receipt, and it stays open.

The remainder: the Notch's typology (military-hardened vs storage-archive — both correct at different
times, which shows a single typology field cannot carry this site); the Notch's currency claim
(graded and refuted by cog, unmentioned by comms — a coverage gap that a naive merge taking the
shorter record would have silently dropped); Thomasville's region number (RG 397 says Region 4, the
enumeration says Region 3); whether a hardened Federal Regional Center exists at Kansas City (CLUI's
list says yes, the eight-member enumeration and targeted searching say nothing) — held
**provisionally hollow and explicitly not refuted**; Netcong's floor area (125,000 sq ft
self-published vs 86,000 from the independent surveyor); Maynard's construction date (a four-way
spread across nearly two decades); and Atlas silo wall thickness (10 feet in the tourism corpus, 2.5
feet in FAS).

---

## 4. Lineage collapses — the shared-node finding

This is the part that only becomes visible at this layer, because each beat could only see its own
dependence.

Twelve shared nodes are catalogued in `resolved.json` under `shared_lineage_nodes`. The fan-out:

| node | candidates touched (of 48) |
|---|---|
| Wikipedia + its mirror/derivative family | **20** |
| Center for Land Use Interpretation | **15** |
| Grokipedia (zero contribution by rule) | 11 |
| Wikimapia (zero lineages by rule) | 8 |
| Albert LaFrance / coldwar-c4i.net | **8** |
| Schneider 1995 + Sauder 1995 | 5 |
| FAS + GlobalSecurity (one node, not two) | 4 |
| Ed Peden / 20th Century Castles brokerage | 4 |
| long-lines.net corpus | 3 |
| coldwar-ct.com / coldwar-ma.com (one project) | 3 |
| atlasmissilesilo.com + squadron veterans' sites | 3 |
| qsl.net "Nuclear Design of AT&T Equipment" | 2 |

**Four beats, searching blind, on four unrelated topics, produced a source graph in which two nodes
carry more than two-thirds of the candidates.** Neither node is a primary record. Wikipedia is a
mid-tier aggregator whose derivative family reliably presents one lineage as six. CLUI is an unsigned,
uncited curatorial survey that, on both beats' own reading of its method, works from public property
records — which makes it a *derivative* of the historic-preservation and land-records layer rather
than an independent terminus.

This is a fact about *this register*, not about the world, and it is the correct thing to publish
about a first sweep. The remedy is not more searching. Every beat independently reported the same
shape: the reachable sources collapse to a few nodes, and the genuinely independent termini — NARA,
DTIC, AFHRA, GovInfo, county recorders, the National Register nominations, the START implementation
record, the FCC antenna registry, the Albemarle and Loudoun permit files — are precisely the ones
egress blocked. The cog beat put it best and it applies to the whole sweep: *the reachable sources
collapse to one lineage while the unreachable ones are the independent ones.*

### The single largest collapse to one terminus

**Phil Schneider's Preparedness Expo lecture, 1995.**

Five separately-presented claim families, arriving from **three beats that could not see each other**,
all terminate in one lecture by one man, with Richard Sauder's self-published *Underground Bases and
Tunnels* (1995) as the co-terminus supplying the bibliography while Schneider supplies the numbers:

1. **The Denver International Airport underground base** (folklore) — Alex Christopher's *Pandora's
   Box II* (1996) attributes the figures to Schneider directly.
2. **"129 (or 131) DUMBs, 1,477 worldwide"** (folklore) — the lecture itself.
3. **The transcontinental subterrene tunnel network** (folklore) — Sauder's inferential leap, with
   Schneider's numbers attached.
4. **"FEMA regional centres are regional nodes of a covert deep-underground network"** (cog) — traced
   by that beat to the Sauder/Schneider corpus.
5. **"Decommissioned Atlas/Titan/Nike sites are entrances to a national DUMB network"** (silo) —
   traced by that beat to the same corpus, and noted there as "an accretion onto a claim structure
   that predates it."

Schneider died in January 1996, which froze the lecture as canon: a fixed text that could not be
revised, defended or withdrawn. Thirty years later there is still no list, no coordinate for any of
the 129, no procurement record, no spoil accounting.

**Any register treating any two of these five as mutually corroborating is counting one 1995 lecture
twice.** Under BES 5.7 this is the non-monotone case where *finding a link lowers a grade* — the
merge is a downgrade, and it should be. The five claim families are more, not less, suspect for being
relatives.

Three usable by-products:

- **A lineage fingerprint.** Any page carrying "1,477" or "129 underground bases" is in this lineage
  regardless of what else it says, and that test survives paraphrase and machine regeneration, which
  shingle-matching does not.
- **A discipline that must hold.** This is F, not R. The expected-record negatives are deep and real,
  and converting them into refutation is forbidden — a model that refutes on negatives alone would
  also have refuted the Greenbrier in 1991. Recorded because the temptation here is strong.
- **An open upstream question.** Whether the 1990s DUMB corpus descends from Shaver (RES-035) *by
  citation* or merely resembles him by genre convergence is untested, and the reported LeVesque
  bridge between the Shaver material and the Dulce cluster is a concrete, checkable link. Answering it
  would materially change how this node is described.

### The one that must not be laundered

**RES-026 is two lineages and they must never merge.** The nuclear subterrene *documents* are real
and institutionally independent — OSTI LA-5354-MS, OSTI LA-4547, US Patent 3,693,731, the DRI/DOE
U12t tunnel evaluation: four roots, each agency recording its own programme for its own purposes. The
*network* is one 1990s fringe-book cluster. A register that lets the first launder the second has
performed citogenesis on itself. The same split applies to REX 84 (RES-034): the 1987 Chardy
reporting and the Brooks–North congressional exchange are real and independent and attest **planning**;
the underground-camps literature is a separate derivative cluster and attests nothing. Fusing them
lets a genuine congressional exchange launder an unevidenced construction claim.

For this reason the counts in `resolved.json` list sub-claim origin counts **separately and do not add
them in**. RES-026 shows `independent_origins: 1` with `origins_for_document_programme: 4`. RES-027
shows `1` with `origins_for_episode: 3`. RES-034 shows `1` with `origins_for_planning_kernel: 2`.
Rolling those up would be the exact failure the register exists to catch.

---

## 5. Citogenesis findings

Ten are logged. Ranked by how much damage they do to *this* register:

**CITOGENESIS-01 — the folklore coinage now inside our own source list.** "Western Virginia Office of
Controlled Conflict Operations" appears to be a coinage of the Mount Weather folklore layer,
originating with Pollock 1976, with no documentary attestation found. It now appears as an **alternate
official name in the page titles** of both the Federation of American Scientists' Nuclear Information
Project and GlobalSecurity.org — a P3 source and a P4 source *in this project's own registry*. The
laundering loop runs through our own bibliography, which means it must be flagged at the **source**
level and not only at the proposition level. It is also independent support for the finding that FAS
and GlobalSecurity share text: the same unattested coinage in both titles is what shared authorship
looks like. The test is binary and cheap — does the phrase appear in any federal record — and if it
does, the finding collapses and should be struck. The folklore beat was explicit that it did not run
that search.

**CITOGENESIS-02 — hedge-stripping, the purest form.** LaFrance states the Project Offices'
continuity-of-government mission as inference and hedges it repeatedly and honestly: "probably not the
station's primary mission", "likely", "may have served". Wikipedia, CLUI, a Grokipedia mirror and
every downstream retelling restate the conclusion **with the hedges removed**. Nobody lied and nobody
invented. The apparent convergence of many sources is one named researcher's honestly-marked
conjecture reflected in many mirrors. The corrective is to restore the hedges and grade the conjecture
as a conjecture by a named researcher — which is a real, if modest, thing to have, and considerably
better than the unhedged version deserves.

**CITOGENESIS-03 — a programme specification worn as an instance measurement.** "Designed to
withstand a 20-megaton detonation at 2.5 miles" is a genuine AT&T *design assumption* for one hardness
class, transcribed at qsl.net from a parent document nobody in the chain has ever identified. It runs
qsl.net → Hackaday (2017) → the Long Lines literature → operators' marketing → data-centre trade press
→ hundreds of pages, and lands attached to individual buildings whose hardness class is undocumented.
The same corpus states many L-3I facilities were designed for about 2 psi — two orders of magnitude
from the 50 psi "extremely hard" class being borrowed. Thirty pages state it of InfoBunker alone;
they are one lineage.

**CITOGENESIS-04 — brokerage copy laundered into state tourism material.** "Almost 10 feet thick",
"epoxy-resin concrete", "rebar over three inches" travels as a *unit* through a Kansas state tourism
blog, travel blogs, a UK property listicle and regional features. FAS gives the wall as about 2.5
feet, with nine feet of concrete at the **surface** — so this is a transposition of a real figure onto
the wrong structural element, which is why it survives casual checking. "Epoxy-resin concrete" is the
distinctive-error tell. The silo beat named 20th Century Castles as the probable origin and then
**declined to grade it**, because the dated negative receipt was not run. That restraint is correct
and is preserved.

**CITOGENESIS-08 — an announcement reported as an accomplishment.** A North Dakota governor's press
release of 26 July 2022, relaying a company's statement about the Nekoma pyramid, replicated within 48
hours across nine outlets and terminating in a consumer gallery headline asserting *present-tense*
operation, syndicated onward through Yahoo. The tense changes as it travels. The state press office
looks like a P1 source, which is what gives the chain its authority — but a governor's office has
authority over its own announcement, not over whether a company will build what it said it would. As
of November 2024: little evidence of progress and state funds unused; the only source asserting
present operation is a company release describing 2.5MW at a site announced for 300MW.

**CITOGENESIS-09 — the one all four beats caught.** Grokipedia mirrors returned in search results
*alongside* the Wikipedia articles they mirror, creating the appearance of two sources where there is
one, and the one is already a mid-tier aggregator. All four beats met it, all four excluded it. It
touches eleven merged candidates. Logged not because any beat was fooled but because **an automated
ingest counting distinct domains would score every one of those candidates as having one more source
than it has.**

Also logged: **CITOGENESIS-05**, the $61M Peters Mountain figure attributed by a wiki to Albemarle
County building permits with no permit number, date or applicant — the exact profile of a fact that
propagates, and cheaply checkable against a public permit viewer that apparently nobody has queried;
**CITOGENESIS-06**, a 2015 Before It's News post as the dated, visible moment an ordinary FEMA
regional office at Maynard is restyled a "deep underground military base" — a fact about the *claim*,
gradeable, and saying nothing whatever about the building; **CITOGENESIS-07**, one CLUI class-level
sentence returned verbatim for Maynard, Denton and Thomasville and read at each as instance evidence;
and **CITOGENESIS-10**, the untested hypothesis that the name "Hangar 18" was cemented by a 1980
feature film and propagated back into the nomenclature of a real installation.

---

## 6. What the shape of the result says

Of the 19 candidates with more than one genuinely independent origin, **nine are on the missile-silo
beat** — and one of those, RES-046, is the strongest independence structure anywhere in the sweep, at
five roots, because START I made an *adversary government* verify by satellite that each launcher had
been destroyed and the excavation left open for ninety days.

The best-attested things in this register are the ones nobody finds mysterious: a Battle Creek office
building with no underground at all (four origins), a Western Union microwave terminal in
Tenleytown (three), a Titan I contamination plume under state regulatory oversight (three), a 1980
missile accident with a National Register nomination (three), a state historic site (three), a
destroyed missile field verified by treaty (five).

The candidates that rest on exactly one source are, with few exceptions, the interesting ones:
Raven Rock, the Presidential Emergency Facility at Lambs Knoll, the Hagerstown Project Office, Dulce,
DIA, Mel's Hole, Iron Mountain, the Survival Condo, Subterra Castle. That is not a coincidence and it
is not evidence of concealment. It is what a first sweep of the *indexed web* looks like when the
archives are unreachable: interest and documentation are inversely correlated in the reachable corpus,
because the reachable corpus is written by enthusiasts and marketers, and the record classes that
would settle things sit behind egress blocks.

The next cycle's highest-value work is almost entirely acquisition, not search. In rough order of
cheapness against diagnosticity: the Albemarle County permit viewer (settles CITOGENESIS-05); the
Loudoun County file CMPT-2016-0001; the Hampshire County deed for the 1989 Notch sale; the Arkansas
NRHP nomination for Launch Complex 374-7; the FRASER finding aid at RG 82 Boston Box 2644 Folder 1
(settles the Notch currency claim); the FCC antenna registry for the seven Missouri sites (converts a
compiler into federal primaries, or produces confabulation events to record); a Wayback CDX pass over
missilebases.com for "epoxy resin"; and a search of federal records for "Western Virginia Office of
Controlled Conflict Operations", which either collapses CITOGENESIS-01 entirely or confirms that a
1976 magazine coinage has been sitting in two reference sites' titles for decades.

None of it requires finding anything new. All of it requires opening documents this sweep could only
see described.
