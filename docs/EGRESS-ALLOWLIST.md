# Egress allowlist

The network policy for this environment currently denies **all** outbound egress: the proxy answers
`403` to `CONNECT` for every host, and `WebFetch` returns `EGRESS_BLOCKED` for `catalog.archives.gov`
and `ngmdb.usgs.gov`. Only `WebSearch` functions, and it returns snippets and summaries — never the
source document.

**Consequence:** the verification tier cannot resolve a single citation to bytes. Under the register's
own resolve-or-die rule, nothing discovered in this state is publishable. The 158-source registry in
`docs/SOURCE-REGISTRY.md` was itself built entirely from search snippets and has never been tested
against a live endpoint — by our own standard it is V0-UNRESOLVED.

These are the 122 distinct hosts referenced by that registry, ranked by the value the cataloguing
agents assigned them. Configure at **claude.ai/code → environment → network access**.

---

## CRITICAL (40 hosts)

*Without these the register cannot function.*

```
airforcehistoryindex.org
api.govinfo.gov
api.sam.gov
api.usaspending.gov
apps.dtic.mil
archive.org
catalog.archives.gov
cdxapps.epa.gov
comptroller.war.gov
data.fcc.gov
echo.epa.gov
ed-thelen.org
en.wikipedia.org
erdc-library.erdc.dren.mil
files.usaspending.gov
geospatial-usace.opendata.arcgis.com
github.com
m2m.cr.usgs.gov
maps.nccs.nasa.gov
mrdata.usgs.gov
nsarchive.gwu.edu
open.gsa.gov
prd-tnm.s3.amazonaws.com
source.coop
usgs-lidar-public.s3.amazonaws.com
web.archive.org
wireless2.fcc.gov
www.acquisition.gov
www.afmissileers.org
www.cdc.gov
www.cia.gov
www.esd.whs.mil
www.fcc.gov
www.federalregister.gov
www.globalsecurity.org
www.gsa.gov
www.loc.gov
www.long-lines.net
www.usgs.gov
www.washingtonpost.com
```

<details><summary>What each is</summary>

- `airforcehistoryindex.org` — Air Force History Index (airforcehistoryindex.org) +
- `api.govinfo.gov` — GovInfo API and Bulk Data Repository
- `api.sam.gov` — SAM.gov Entity Management API
- `api.usaspending.gov` — USAspending.gov REST API v2
- `apps.dtic.mil` — DTIC public technical reports (apps.dtic.mil)
- `archive.org` — Archives for the Unexplained (AFU) — digitized newsl
- `catalog.archives.gov` — NARA National Archives Catalog API v2
- `cdxapps.epa.gov` — EPA Environmental Impact Statement Database (CDX e-N
- `comptroller.war.gov` — DoD Comptroller budget justification archive (MILCON
- `data.fcc.gov` — FCC Antenna Structure Registration (ASR) — bulk r_to
- `echo.epa.gov` — EPA ECHO — ICIS-Air bulk downloads and REST services
- `ed-thelen.org` — Ed Thelen's Nike Missile Site and the Nike/air-defen
- `en.wikipedia.org` — Richard Pollock, 'The Mysterious Mountain,' The Prog
- `erdc-library.erdc.dren.mil` — ERDC Knowledge Core (Army Corps of Engineers researc
- `files.usaspending.gov` — USAspending bulk data — full PostgreSQL snapshot, Aw
- `geospatial-usace.opendata.arcgis.com` — USACE Formerly Used Defense Sites (FUDS) GIS
- `github.com` — Foreign Relations of the United States (FRUS), TEI X
- `m2m.cr.usgs.gov` — USGS EarthExplorer + M2M machine-to-machine API — de
- `maps.nccs.nasa.gov` — HIFLD Open — NASA NCCS live ArcGIS mirror
- `mrdata.usgs.gov` — USGS Mineral Resources Data System (MRDS) and Minera
- `nsarchive.gwu.edu` — Documented COG scholarship — the P2 anchor for gradi
- `open.gsa.gov` — SAM.gov Contract Data API (FPDS successor)
- `prd-tnm.s3.amazonaws.com` — GNIS Domestic Names (Geographic Names Information Sy
- `source.coop` — HIFLD Archive on Source Cooperative (SeerAI) — Parqu
- `usgs-lidar-public.s3.amazonaws.com` — USGS 3DEP lidar on AWS as Entwine Point Tiles (usgs-
- `web.archive.org` — Claim-dating infrastructure: Wayback CDX, textfiles.
- `wireless2.fcc.gov` — FCC ULS / ASR interactive licence app — deep-link UR
- `www.acquisition.gov` — Product and Service Code (PSC) Manual — the hardened
- `www.afmissileers.org` — Association of Air Force Missileers newsletter archi
- `www.cdc.gov` — NIOSH OCAS Special Exposure Cohort petitions, Site P
- `www.cia.gov` — CIA CREST / FOIA Electronic Reading Room
- `www.esd.whs.mil` — DoD / Washington Headquarters Services Executive Ser
- `www.fcc.gov` — FCC Broadband Data Collection (BDC) / National Broad
- `www.federalregister.gov` — Federal Register API
- `www.globalsecurity.org` — GlobalSecurity.org — the P3 aggregator the ecosystem
- `www.gsa.gov` — GSA Federal Real Property Profile (FRPP) Public Data
- `www.loc.gov` — Chronicling America — Library of Congress (post-2025
- `www.long-lines.net` — long-lines.net — AT&T Long Lines Places and Routes
- `www.usgs.gov` — USGS EROS Aerial Photo Single Frames
- `www.washingtonpost.com` — Ted Gup, 'The Ultimate Congressional Hideaway,' Wash

</details>

## HIGH (51 hosts)

*Substantial coverage loss without these.*

```
adds-faa.opendata.arcgis.com
aec.army.mil
api.congress.gov
apportionment-public.max.gov
atlas.eia.gov
cdnc.ucr.edu
crsreports.congress.gov
data-ndwr.hub.arcgis.com
data.epa.gov
dwr.state.co.us
elibrary.ferc.gov
huggingface.co
ntrl.ntis.gov
openinframap.org
openomb.org
opentopography.org
realestatesales.gov
regrid.com
reports.blm.gov
special.library.unlv.edu
texashistory.unt.edu
tnmaccess.nationalmap.gov
usace.contentdm.oclc.org
waterservices.usgs.gov
webapi.legistar.com
www.acq.osd.mil
www.archives.gov
www.bibliotecapleyades.net
www.civicplus.com
www.denix.osd.mil
www.deq.virginia.gov
www.dreamlandresort.com
www.eia.gov
www.energy.gov
www.epa.gov
www.faa.gov
www.fpds.gov
www.gao.gov
www.governmentattic.org
www.hathitrust.org
www.missilebases.com
www.msha.gov
www.osti.gov
www.pa.gov
www.peeringdb.com
www.publications.usace.army.mil
www.splcenter.org
www.subbrit.org.uk
www.theblackvault.com
www.twdb.texas.gov
www.wbdg.org
```

<details><summary>What each is</summary>

- `adds-faa.opendata.arcgis.com` — FAA Special Use Airspace and aeronautical geospatial
- `aec.army.mil` — Service NEPA repositories — Army NEPA Online, AFCEC 
- `api.congress.gov` — Congress.gov API v3
- `apportionment-public.max.gov` — OMB public apportionment files
- `atlas.eia.gov` — EIA U.S. Energy Atlas
- `cdnc.ucr.edu` — Veridian-platform state newspaper collections (CDNC 
- `crsreports.congress.gov` — Congressional Research Service reports
- `data-ndwr.hub.arcgis.com` — Nevada Division of Water Resources — Well Driller Re
- `data.epa.gov` — EPA Envirofacts Data Service API (SEMS, RCRAInfo, FR
- `dwr.state.co.us` — Colorado Division of Water Resources — CDSS HydroBas
- `elibrary.ferc.gov` — FERC eLibrary
- `huggingface.co` — NEPATEC1.0 — AI-ready NEPA document corpus
- `ntrl.ntis.gov` — National Technical Reports Library (NTRL / NTIS)
- `openinframap.org` — OpenStreetMap power/telecom layer via Overpass API a
- `openomb.org` — OpenOMB
- `opentopography.org` — OpenTopography REST API (3DEP and global DEM croppin
- `realestatesales.gov` — GSA Real Property Disposal and realestatesales.gov
- `regrid.com` — County recorder and assessor land records, and state
- `reports.blm.gov` — BLM Mineral & Land Records System (MLRS) and General
- `special.library.unlv.edu` — Nevada Test Site Oral History Project (UNLV)
- `texashistory.unt.edu` — The Portal to Texas History / Gateway to Oklahoma Hi
- `tnmaccess.nationalmap.gov` — TNM Access API (The National Map product search)
- `usace.contentdm.oclc.org` — USACE Digital Library, district history offices, and
- `waterservices.usgs.gov` — USGS National Water Information System (NWIS) — Site
- `webapi.legistar.com` — Granicus Legistar Web API — municipal and county leg
- `www.acq.osd.mil` — DoD Real Property inventory reporting — Base Structu
- `www.archives.gov` — NARA Record Group 373 — Records of the Defense Intel
- `www.bibliotecapleyades.net` — Pure aggregator nodes: bibliotecapleyades.net, whale
- `www.civicplus.com` — CivicPlus AgendaCenter / CivicClerk / PrimeGov / Boa
- `www.denix.osd.mil` — DENIX — Defense Environmental Programs Annual Report
- `www.deq.virginia.gov` — Virginia DEQ — Issued Air Permits for Data Centers
- `www.dreamlandresort.com` — Glenn Campbell's Groom Lake corpus, Dreamland Resort
- `www.eia.gov` — EIA Form EIA-860 / EIA-860M / EIA-923 and the EIA AP
- `www.energy.gov` — DOE NEPA document library and Office of Environmenta
- `www.epa.gov` — EPA National Emissions Inventory (NEI) — point sourc
- `www.faa.gov` — FAA Digital Obstacle File (DOF) and Daily DOF (DDOF)
- `www.fpds.gov` — FPDS-NG ATOM feed (legacy, sunsetting)
- `www.gao.gov` — GAO reports and DoD Inspector General reports
- `www.governmentattic.org` — governmentattic.org
- `www.hathitrust.org` — HathiTrust — county histories, installation historie
- `www.missilebases.com` — missilebases.com / 20th Century Castles (Ed and Dian
- `www.msha.gov` — MSHA Mine Data Retrieval System — open flat files
- `www.osti.gov` — DOE OpenNet / OSTI declassified document index
- `www.pa.gov` — State geological survey and state mining agency mine
- `www.peeringdb.com` — BGP and IP registry infrastructure: RIPE RIS, RouteV
- `www.publications.usace.army.mil` — USACE Publications portal (Engineer Manuals, Regulat
- `www.splcenter.org` — The FEMA-camps / COG-detention corpus and its tracer
- `www.subbrit.org.uk` — Subterranea Britannica — the methodological model
- `www.theblackvault.com` — The Black Vault
- `www.twdb.texas.gov` — Texas Water Development Board — Submitted Driller's 
- `www.wbdg.org` — Unified Facilities Criteria and design-standard cita

</details>

## MODERATE (29 hosts)

*Useful; degrades gracefully.*

```
catalog.data.gov
coldwar-c4i.net
fiscal.treasury.gov
govfiles.dev
new.azwater.gov
ngmdb.usgs.gov
pubs.usgs.gov
reuther.wayne.edu
rrs.usace.army.mil
thor-f5.er.usgs.gov
waterrights.utah.gov
wikimapia.org
www.abovetopsecret.com
www.dodig.mil
www.ferc.gov
www.fsa.usda.gov
www.library.ucsb.edu
www.ncpc.gov
www.newsbank.com
www.newspapers.com
www.nps.gov
www.nsa.gov
www.osmre.gov
www.pbrb.gov
www.permits.performance.gov
www.statearchivists.org
www.uer.ca
www.vlm.cem.va.gov
www.wapa.gov
```

<details><summary>What each is</summary>

- `catalog.data.gov` — Municipal and state building energy benchmarking dis
- `coldwar-c4i.net` — Cold War C4I / FAS Nuclear Information Project / Glo
- `fiscal.treasury.gov` — Treasury FAST Book (Federal Account Symbols and Titl
- `govfiles.dev` — State business entity registries and shell-entity tr
- `new.azwater.gov` — Arizona Department of Water Resources — Wells55 regi
- `ngmdb.usgs.gov` — topoView (NGMDB) — human-facing HTMC browser
- `pubs.usgs.gov` — USGS Topographic Map Symbols reference and the Kentu
- `reuther.wayne.edu` — Labor archives and building-trades periodicals
- `rrs.usace.army.mil` — USACE Regulatory — Section 404/Section 10 permits (O
- `thor-f5.er.usgs.gov` — HTMC per-sheet FGDC metadata web-accessible folder (
- `waterrights.utah.gov` — Utah Division of Water Rights — well logs and water 
- `wikimapia.org` — Enthusiast and crowd mapping layers: Wikimapia, Open
- `www.abovetopsecret.com` — Forum aggregation nodes: AboveTopSecret and Godlike 
- `www.dodig.mil` — DoD Office of Inspector General FOIA Reading Room
- `www.ferc.gov` — FERC Electric Quarterly Reports (EQR) bulk database
- `www.fsa.usda.gov` — USDA Aerial Photography Field Office (APFO)
- `www.library.ucsb.edu` — UCSB Library FrameFinder and comparable academic air
- `www.ncpc.gov` — National Capital Planning Commission project review 
- `www.newsbank.com` — NewsBank 'America's News' / Access World News
- `www.newspapers.com` — Newspapers.com (Ancestry) and GenealogyBank (NewsBan
- `www.nps.gov` — National Register of Historic Places spatial data (N
- `www.nsa.gov` — NSA, DIA and DTRA FOIA electronic reading rooms
- `www.osmre.gov` — OSMRE e-AMLIS — Abandoned Mine Land Inventory System
- `www.pbrb.gov` — Public Buildings Reform Board
- `www.permits.performance.gov` — Federal Permitting Dashboard
- `www.statearchivists.org` — State historical societies, county historical societ
- `www.uer.ca` — Urban exploration communities: UER.ca, 28dayslater, 
- `www.vlm.cem.va.gov` — Veterans Legacy Memorial, Nationwide Gravesite Locat
- `www.wapa.gov` — Western Area Power Administration and the federal Po

</details>

## LOW (2 hosts)

*Marginal.*

```
www.historicaerials.com
www.ntia.gov
```

<details><summary>What each is</summary>

- `www.historicaerials.com` — NETR HistoricAerials (historicaerials.com)
- `www.ntia.gov` — NTIA Government Master File (GMF) of federal frequen

</details>

---

## Notes

- `web.archive.org` and `archive.org` matter more than their rank suggests: many primary documents are
  reachable only through captures, and archived copies carry a retrieval timestamp the custody model uses.
- `github.com` and `huggingface.co` appear because agents found existing open-source harvesters for CIA
  CREST and USGS EarthExplorer rather than assuming we would write our own.
- Several hosts are P4/P5 fringe sources (`bibliotecapleyades.net`, `abovetopsecret.com`,
  `dreamlandresort.com`). They are required precisely because claims must be traced **backwards to their
  origin**. Reaching them is how a claim gets graded F with its origin documented, rather than left
  circulating unchallenged.
- `m2m.cr.usgs.gov` needs a registered EROS M2M account, and `api.govinfo.gov` / `api.sam.gov` /
  `api.congress.gov` need an `api.data.gov` key. Allowlisting is necessary but not sufficient for these.

---

## How to actually turn this on

### Step 1 — Network access level

On claude.ai/code, open the environment (cloud icon, or hover an environment and select the settings
icon). In the dialog, change **Network access** from `Trusted` to **`Custom`**, then paste the domains
above into **Allowed domains**, one per line.

**Tick "Also include default list of common package managers."** Custom *replaces* the Trusted list
rather than extending it. Without that box checked, npm and the package registries stop resolving and
the application build breaks.

`*.` matches every subdomain, so `*.usgs.gov` covers `ngmdb`, `mrdata` and `waterservices` in one line.

### Step 2 — Start a new session

Running sessions do not re-read environment configuration; each session copies it once at startup. A
session that was already running when the policy changed stays blocked. This is not a propagation
delay — it never picks it up.

### Step 3 — API keys, which egress does not provide

Several critical sources reject unauthenticated requests, so allowlisting is necessary but not
sufficient.

| Source | How | Speed |
|---|---|---|
| **NARA Catalog API** | Email `Catalog_API@nara.gov` with your name and the email address to associate. Returns a key for the `x-api-key` header. | Human turnaround |
| **api.data.gov** | Self-service signup. One key covers govinfo, congress.gov and SAM. | Instant |
| **USGS EROS M2M** | Register an EROS account, then request Machine-to-Machine access. Needed for bulk imagery. | Days |

```bash
curl -H "x-api-key: $NARA_KEY" \
  "https://catalog.archives.gov/api/v2/records/search?q=underground+facility&limit=10"
```

Keys belong in the environment's **Environment variables** field — but note the documentation's warning
that cloud environments have no secrets store and anyone using the environment can read those values.
For a project whose output is public anyway, that is an acceptable trade for these particular keys, all
of which are free and rate-limited rather than billable.

### What this does NOT affect

MCP connector traffic does not travel through this allowlist — it goes via Anthropic's servers instead.
That is why the Supabase MCP tools worked throughout while `WebFetch` to `archives.gov` was refused. If
a source is reachable only through an MCP connector, the network policy is irrelevant to it.

### How to confirm it worked

From a **new** session:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" "https://catalog.archives.gov/api/v2/records/search?q=test&limit=1"
```

`403` means the CONNECT was refused — the policy did not take. `401`/`403` *from NARA itself* with a
JSON body means egress works and the API key is what is missing. `200` means both are in place, and the
verification tier can run for the first time.
