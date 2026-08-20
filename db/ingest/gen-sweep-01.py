#!/usr/bin/env python3
"""Generate db/ingest/sweep-01.sql and db/ingest/sweep-01-verify.sql from
research/candidates/graded.json + resolved.json against supabase/schema.sql.

Design decisions are documented in db/ingest/README.md (written by hand).
Everything here is deterministic: fixed UUIDv5 identities, ON CONFLICT DO
NOTHING / WHERE NOT EXISTS everywhere, so chunks are re-runnable.
"""
import json, uuid, re, os, sys
from urllib.parse import urlparse

ROOT = '/home/user/Bunkers'
OUT  = os.path.join(ROOT, 'db', 'ingest')
os.makedirs(OUT, exist_ok=True)

NS = uuid.uuid5(uuid.NAMESPACE_URL, 'bunkers-sweep-01')
ACTOR = 'sweep-01-ingest'
SCORER = 'claude-opus-5'

g = json.load(open(os.path.join(ROOT,'research/candidates/graded.json')))
r = json.load(open(os.path.join(ROOT,'research/candidates/resolved.json')))

gents  = {e['entity_id']: e for e in g['entities']}
gprops = {p['proposition_id']: p for p in g['propositions']}
rcands = {c['id']: c for c in r['candidates']}

def U(key):        return str(uuid.uuid5(NS, key))
def ent_id(cid):   return U('ent:'+cid)
def prop_id(pid):  return U('prop:'+pid)
def doc_id(cid,i): return U('doc:%s:%d' % (cid,i))
def dossier_id(cid): return U('dossier:'+cid)
def rcpt_id(cid,i):  return U('rcpt:%s:%d' % (cid,i))
def geom_id(cid):    return U('geom:'+cid)
def claim_id(pid):   return U('claim:'+pid)
def obs_id(pid,kind,i): return U('obs:%s:%s:%d' % (pid,kind,i))
def xdoc_id(key):  return U('xdoc:'+key)
def xrcpt_id(key): return U('xrcpt:'+key)

def q(s):
    if s is None: return 'null'
    return "'" + str(s).replace("'", "''") + "'"

def qj(obj):
    return q(json.dumps(obj, ensure_ascii=False)) + '::jsonb'

def trunc(s, n):
    s = (s or '').strip()
    return s if len(s) <= n else s[:n-2].rstrip() + ' …'

def host_of(u):
    try:
        h = urlparse(u or '').netloc.lower()
        return h[4:] if h.startswith('www.') else h
    except Exception:
        return ''

def slugify(cid, name):
    s = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
    return (cid.lower() + '-' + s)[:70].rstrip('-')

# ---------------------------------------------------------------- payload maps
DROPPED_PROPS = {
    'RES-022-EXIST-2':  'second EXIST on a merged entity; core.proposition_one_exist admits one EXIST per entity per as-of date',
    'RES-003-IDENTITY': 'IDENTITY requires object_entity_id; the Everett WA regional office is not an entity in this sweep',
    'RES-011-IDENTITY': "IDENTITY requires object_entity_id; Raven Rock 'Site C' is not an entity in this sweep",
    'RES-012-IDENTITY': 'IDENTITY requires ONE object entity; the chain-membership claim over five member stations is expressed as core.entity_relation PARENT-OF rows instead',
    'RES-047-IDENTITY': 'IDENTITY requires object_entity_id; the specific 579th SMS site is unresolved among twelve ("WHICH ONE IS UNKNOWN TO ME") and none is registered',
}
SELF_IDENTITY = {'RES-031-IDENTITY','RES-039-IDENTITY','RES-042-IDENTITY'}

STATUS_MAP = {
 'RES-001-STATUS': ('active', 'remains in federal use as a FEMA regional operations centre'),
 'RES-006-STATUS': ('unknown', 'current disposition unknown to the sweep'),
 'RES-008-STATUS': ('converted', 'continuity function ended by early 1970s; property passed to the Smithsonian Institution'),
 'RES-009-STATUS': ('converted', 'no longer in presidential-shelter service; reported FAA use'),
 'RES-010-STATUS': ('active', 'currently a DLA site, reported listed for accelerated disposition'),
 'RES-014-STATUS': ('standby', 'non-operational or mothballed; antennas removed; AT&T ownership retained ("mothballed" has no exact value in core.status_value)'),
 'RES-015-STATUS': ('active', 'AT&T-owned and operational; troposcatter retired'),
 'RES-017-STATUS': ('converted', 'closed as a station; private ownership; storage and residential use'),
 'RES-022-STATUS': ('converted', 'in use as a library depository for the Five Colleges consortium'),
 'RES-022-STATUS-2': ('converted', 'decommissioned as a military installation; five-college library depository since ~1989'),
 'RES-036-STATUS': ('decommissioned', 'decommissioned as a military facility; non-federal ownership'),
 'RES-037-STATUS': ('active', 'operational and federally controlled (Space Force)'),
 'RES-038-STATUS': ('decommissioned', 'decommissioned; privately owned; seasonal public tours'),
 'RES-038-STATUS-2': ('decommissioned', 'RSL-1 abandoned; post-2013 owner unidentified'),
 'RES-039-STATUS': ('converted', 'converted private residence'),
 'RES-041-STATUS': ('converted', 'private residence; former public-tour operation may have ceased'),
 'RES-042-STATUS': ('decommissioned', 'decommissioned; variously flooded, sealed or abandoned; physically hazardous'),
 'RES-043-STATUS': ('sealed', 'destroyed 19 September 1980, never repaired; sealed and abandoned as a facility'),
 'RES-044-STATUS': ('converted', 'decommissioned as a military site; partially restored; monthly free public tours'),
 'RES-045-STATUS': ('converted', 'missile removed; duct filled and sealed under START I; preserved as a state historic site'),
 'RES-046-STATUS': ('demolished', 'launch facilities destroyed by controlled explosive demolition under START I'),
 'RES-048-STATUS': ('unknown', 'deactivated mid-1960s and disposed of; present condition and ownership unknown to the sweep'),
}
EXTENT_MAP = {
 'RES-004-EXTENT': ('occupant-capacity', 'several hundred people for 30 days or more', 'persons'),
 'RES-014-EXTENT': ('floor-area', 'approximately 100,000', 'sq ft'),
 'RES-018-EXTENT': ('floor-area', '86,000 to 125,000 (contested between self-published and surveyor figures)', 'sq ft'),
 'RES-028-EXTENT': ('depth', 'approximately 3,000', 'ft'),
 'RES-040-EXTENT': ('habitable-levels', 'approximately fifteen', 'levels'),
}
CONTROL_MAP = {
 'RES-007-CONTROL': 'unidentified federal component (custody passed from FEMA ~March 2019; component unnamed in reachable sources)',
 'RES-013-CONTROL': 'AT&T (with a reported federal government activity hosted since ~1963)',
 'RES-020-CONTROL': 'InfoBunker, LLC (private commercial operator; built and formerly owned by AT&T Long Lines)',
 'RES-021-CONTROL': 'American Tower Corporation (reported)',
 'RES-023-CONTROL': 'mixed: AT&T successors, private parties, tower companies, and in one case the State of Missouri (varies by site)',
 'RES-036-CONTROL': 'Bitzero Blockchain Inc. (claimed ownership or control)',
 'RES-038-CONTROL': 'private owner (Mel Sann, via 2013 GSA auction)',
 'RES-039-CONTROL': 'private owner (Alexander Michael, since 1996)',
 'RES-040-CONTROL': 'private owner (Laurence A. Hall Jr., since 2008)',
 'RES-041-CONTROL': 'private owners (Ed and Dianna Peden, since 1994)',
 'RES-042-CONTROL': 'mixed public and private ownership after federal disposal; not federally controlled today',
 'RES-043-CONTROL': 'private landowner (access controlled by locked gate)',
 'RES-044-CONTROL': 'Maryland Wing, Civil Air Patrol (lessee since 2014); State of Maryland (owner)',
 'RES-045-CONTROL': 'State Historical Society of North Dakota',
 'RES-046-CONTROL': 'private owners via GSA auction (parcel level)',
 'RES-047-CONTROL': 'private owner (Gary Baker)',
}
PROGRAM_MAP = {
 'RES-002-PROGRAM': ('OCDM/DCPA hardened Federal Regional Centers programme', 'claimed-realised-in-part'),
 'RES-006-PROGRAM': ('proposed Federal Regional Center at the former FBIS site near Healdsburg/Santa Rosa', 'claimed-proposed'),
 'RES-010-PROGRAM': ('FCDA relocation of the civil-defence headquarters to Battle Creek, 1954', 'claimed-historical'),
 'RES-012-PROGRAM': ("AT&T Long Lines 'Project Office' hardened troposcatter chain, late 1950s-1960s", 'claimed-historical'),
 'RES-024-PROGRAM': ('AFOSI disinformation operation against Paul Bennewitz, early 1980s', 'claimed-historical'),
 'RES-026-PROGRAM': ("LASL nuclear subterrene research programme ('rock-melting tunnelling machine')", 'claimed-historical'),
 'RES-034-PROGRAM': ('REX 84 federal emergency-planning exercise, 1984', 'claimed-historical'),
 'RES-046-PROGRAM': ('321st Strategic Missile Wing / Missile Group Minuteman operations, Grand Forks AFB', 'claimed-historical'),
}
IDENTITY_BASIS = {
 'RES-031-IDENTITY': "name-designation correspondence: 'Hangar 18' as the name of a specific structure at Wright-Patterson AFB (designation claim on this entity; no second register entity involved)",
 'RES-039-IDENTITY': "correspondence of three designations for one parcel: the Lewis NY residence, 'Site 5', and Atlas F launch site 556-5",
 'RES-042-IDENTITY': "correspondence between CDPHE's 'Complex 2B'/'Complex 2C' labels and Air Force 724th SMS complex designations (724-A through 724-F)",
}
# graded-F propositions and their ERP adjudication carried from graded.json
F_PROPS_NO_ERP  = {'RES-029-FUNCTION','RES-035-EXIST','RES-035-FUNCTION'}
F_PROP_X0_ONLY  = 'RES-032-FUNCTION'   # three X0 profiles apply; X>=1 denominator empty
X0_PROFILES_032 = ['nip-mip-construction','commercial-cover-any-record','crest-dtic-still-classified']

def entity_level(scope):
    s = scope.lower()
    if 'population' in s or s == 'system':
        return 'program'
    return 'site'

def predicate_args(pid, p):
    cls = p['class']
    if cls == 'STATUS':
        v, basis = STATUS_MAP[pid]
        return {'status': v, 'status_basis': basis + ' (mapped to core.status_value by the ingest; see README)'}
    if cls == 'EXTENT':
        d, v, u_ = EXTENT_MAP[pid]
        return {'dimension': d, 'claimed_value': v, 'unit': u_}
    if cls == 'TYPOLOGY':
        return {'typology': 'private-shelter'}
    if cls == 'CONTROL':
        return {'controlling_entity': CONTROL_MAP[pid]}
    if cls == 'FUNCTION':
        return {'function': trunc(p['statement'], 400)}
    if cls == 'HARDEN':
        return {'threats': ['nuclear-weapons-effects (as claimed by unresolved sources; unverified)']}
    if cls == 'FEATURE':
        return {'feature': trunc(p['statement'], 400)}
    if cls == 'PROGRAM':
        pr, st = PROGRAM_MAP[pid]
        return {'program': pr, 'program_state': st}
    if cls == 'ORIGIN':
        return {'claim_text': trunc(p['statement'], 600)}
    if cls == 'IDENTITY':
        return {'basis': IDENTITY_BASIS[pid]}
    return {}

# ------------------------------------------------------------------ alignment
aligned = {}   # pid -> resolved proposition dict
for c in r['candidates']:
    pids = gents[c['id']]['proposition_ids']
    rprops = c['propositions'] + c.get('propositions_from_second_beat', [])
    assert len(pids) == len(rprops), c['id']
    for pid, rp in zip(pids, rprops):
        aligned[pid] = rp

loaded_pids = [p['proposition_id'] for p in g['propositions']
               if p['proposition_id'] not in DROPPED_PROPS]
assert len(loaded_pids) == 195, len(loaded_pids)

# ---------------------------------------------------------------- documents
# per-candidate source documents + per-candidate dossier + 3 extra pool docs
XDOCS = {
 'dumblist-coreinsights': dict(
    title="coreinsightsintl.com, 'List of DUMBs by State' (state-by-state 'deep underground military base' listing pages)",
    url='https://coreinsightsintl.com/', tier='P5', era='POST-2022-UNATTRIBUTED',
    what="Named in the cog beat's refuted_or_hollow record: pages re-presenting publicly documented FEMA regional centres as concealed installations; unbylined; the lineage is the Sauder/Schneider deep-underground-military-base corpus."),
 'dumblist-ddumb': dict(
    title="deepundergroundmilitarybases.com (state-by-state 'DUMB' listing site)",
    url='https://deepundergroundmilitarybases.com/', tier='P5', era='POST-2022-UNATTRIBUTED',
    what="Named in the cog beat's refuted_or_hollow record and surfaced again on the silo beat; same corpus recirculating; adds no identifier, record or observation to the public material it restyles."),
 'silotips-secret-underground-bases': dict(
    title="silo.tips PDF host, 'Secret Underground Bases' (Sauder/Schneider corpus recirculating)",
    url='https://silo.tips/', tier='P5', era='UNKNOWN',
    what="Named in the silo beat's refuted_or_hollow record: the claim that decommissioned Atlas/Titan/Nike sites are entrances to a national DUMB network is 'an accretion onto a claim structure that predates it' — the Sauder/Schneider material."),
}

SELF_ATTESTING = {
 ('RES-032',0): "The lecturer is the claimant and the lecture's probative content IS the claim (BES 2.5). Schneider's death in January 1996 froze the text as canon.",
 ('RES-026',4): "Sauder is the claimant of the network-inference claim; the book's probative content on that claim IS the claim (BES 2.5). The bibliography of institutional documents it carries is separately loaded as independent documents.",
 ('RES-025',3): "Alex Christopher is the claimant; Pandora's Box II is the claimant's own publication attributing the DIA figures to Schneider (BES 2.5).",
 ('RES-025',4): "Claimant's own broadcast interview (Alex Christopher, KSEO, 26 April 1996); probative content is the claim (BES 2.5).",
 ('RES-020',1): 'Operator marketing: the facility operator is the author and the hardening/heritage claims are the content (BES 2.5).',
 ('RES-041',4): 'Brokerage marketing (20th Century Castles / missilebases.com): the party that created this market wrote its first descriptions (BES 2.5; CITOGENESIS-04 probable origin).',
 ('RES-036',3): 'Company press release: Bitzero describing its own project; authority over its own announcement only (BES 2.5; CITOGENESIS-08).',
 ('RES-018',1): "Operator's own facility page (Vital Records Incorporated); floor-area and hardening claims are the operator's content (BES 2.5).",
 ('RES-035',2): "Shaver's narrative as published; the claimant's own text is the artifact (BES 2.5: 'Shaver is the claimant').",
}

WIKI_HOSTS   = ('wikipedia.org',)
CROWD_HOSTS  = ('wikipedia.org', 'fandom.com', 'wikimapia.org', 'dbpedia.org')
GROK_HOSTS   = ('grokipedia.com',)
ADVW_HOSTS   = ('wikimapia.org',)
P22U_HOSTS   = ('grokipedia.com', 'subterraneanbases.com')

def doc_row(cid, i, s):
    """Return dict of column values for a source document."""
    url = (s.get('url') or '').strip() or None
    h = host_of(url or '')
    tier = s.get('tier')
    d = {
        'document_id': doc_id(cid, i),
        'title': trunc(s['citation'], 900),
        'url': url,
        'origin_tier': 'T5' if tier == 'P5' else 'PENDING',
        'tier_assigned_by': ("resolved.json beat consensus (legacy %s); unreviewed" % tier) if tier else None,
        'causal': 'CROWD-EDITED' if any(h.endswith(x) for x in CROWD_HOSTS) else 'UNSOLICITED',
        'channel': 'ADVERSARY-WRITABLE' if any(h.endswith(x) for x in ADVW_HOSTS) else
                   ('AGGREGATOR' if any(h.endswith(x) for x in CROWD_HOSTS+GROK_HOSTS) else 'ORIGIN-HOST'),
        'era': 'POST-2022-UNATTRIBUTED' if any(h.endswith(x) for x in P22U_HOSTS) else 'UNKNOWN',
        'self_att': SELF_ATTESTING.get((cid, i)),
        'quarantine': None,
    }
    if s.get('retrieval_state') == 'FETCHED':   # the RES-011 calibration self-reference
        d['quarantine'] = ("The register's own calibration document (docs/CALIBRATION.md case A-02), recorded by the resolver "
                           "solely to disclose that its knowledge of Raven Rock's documentary strength is internal. It must never "
                           "be treated as a source for the facility; quarantined so it can contribute zero lineages and zero conditions.")
        d['origin_tier'] = 'T5'
        d['tier_assigned_by'] = 'sweep-01-ingest: register-internal text, not evidence about the world'
    return d

# ------------------------------------------------------------- special edges
def sdoc(cid, i): return doc_id(cid, i)
EDGES = []  # (citing, cited, kind, note)
def E(a, b, kind, note): EDGES.append((a, b, kind, note))

LECTURE = sdoc('RES-032',0); SAUDER = sdoc('RES-026',4); PANDORA = sdoc('RES-025',3)
E(PANDORA, LECTURE, 'explicit-citation', "Pandora's Box II attributes the DIA figures to Schneider directly (resolved.json RES-025 lineage; claim family 1 of the Schneider pool).")
E(sdoc('RES-025',4), PANDORA, 'paraphrase', 'KSEO interview, 26 April 1996: same claimant (Christopher) restating the same material.')
E(SAUDER, LECTURE, 'quotes-testimony', "Sauder 1995 is the co-terminus supplying the bibliography while Schneider supplies the numbers (RESOLUTION-NOTES §4); one pooled origin cluster — claim family 3.")
E(sdoc('RES-032',1), LECTURE, 'explicit-citation', "Secondary sources giving 131 US / 1,477 worldwide and attributing them to the 1995 lecture — claim family 2.")
E(sdoc('RES-032',2), LECTURE, 'semantic-derivation', 'Sources disputing the lecture date are downstream of the lecture itself.')
E(xdoc_id('dumblist-coreinsights'), SAUDER, 'semantic-derivation', "cog beat: 'the lineage is the Sauder/Schneider deep-underground-military-base corpus' — claim family 4 (FEMA regional centres as covert DUMB nodes).")
E(xdoc_id('dumblist-ddumb'), SAUDER, 'semantic-derivation', 'Same corpus recirculating (cog and silo beats) — claim family 4/5.')
E(sdoc('RES-005',4), SAUDER, 'semantic-derivation', "subterraneanbases.com 'Georgia Underground Bases' page: DUMB-list cluster, Sauder/Schneider lineage — claim family 4.")
E(xdoc_id('silotips-secret-underground-bases'), SAUDER, 'semantic-derivation', "silo beat: 'an accretion onto a claim structure that predates it' — claim family 5 (decommissioned silos as DUMB entrances).")
# subterrene document programme: the UNT mirror is the SAME report as LA-5354-MS
E(sdoc('RES-026',1), sdoc('RES-026',0), 'mirror-of', 'UNT Digital Library copy of OSTI LA-5354-MS: one report, two hosts. The four institutional roots (LA-5354-MS, LA-4547, US 3,693,731, DRI/DOE U12t) carry NO collapsing edges among themselves and none into the Schneider pool — RES-026 is two lineages that must never merge.')
# grokipedia mirror-of wikipedia (CITOGENESIS-09), within-candidate
for cid, gi, wi in [('RES-012',6,2), ('RES-014',7,6), ('RES-015',3,2), ('RES-022',6,0),
                    ('RES-030',3,1), ('RES-034',5,4), ('RES-040',4,3)]:
    E(sdoc(cid,gi), sdoc(cid,wi), 'mirror-of', 'CITOGENESIS-09: Grokipedia machine-generated mirror returned in search results alongside the Wikipedia article it mirrors; one lineage presenting as two domains.')
# FAS + GlobalSecurity: one node, not two
for cid in ('RES-007','RES-033'):
    E(sdoc(cid,1), sdoc(cid,0), 'replication', 'N-FASGS: FAS and GlobalSecurity share text (one node, not two); the same unattested coinage in both titles is what shared authorship looks like.')
# CITOGENESIS-01: the WVOCCO coinage in FAS/GS titles descends from Pollock 1976
E(sdoc('RES-033',0), sdoc('RES-033',2), 'semantic-derivation', "CITOGENESIS-01: 'Western Virginia Office of Controlled Conflict Operations' appears to be a Pollock 1976 folklore coinage now carried in the FAS page title; no federal attestation found (the settling search was not run).")
E(sdoc('RES-033',1), sdoc('RES-033',2), 'semantic-derivation', 'CITOGENESIS-01: same coinage in the GlobalSecurity page title; see FAS edge.')
# CITOGENESIS-02: hedge-stripping of LaFrance
for cid, wi, li in [('RES-012',2,0), ('RES-013',7,0), ('RES-016',2,0)]:
    E(sdoc(cid,wi), sdoc(cid,li), 'semantic-derivation', "CITOGENESIS-02: Wikipedia restates LaFrance's repeatedly hedged inference ('probably', 'likely', 'may have served') with the hedges removed.")
E(sdoc('RES-012',1), sdoc('RES-012',0), 'semantic-derivation', 'CITOGENESIS-02: CLUI entry restates the LaFrance conclusion; unsigned and uncited.')
# CITOGENESIS-03: the 20-megaton figure
E(sdoc('RES-020',4), sdoc('RES-020',3), 'explicit-citation', 'CITOGENESIS-03: Hackaday (2017) carries the qsl.net transcription onward; the parent document of the transcription has never been identified.')
E(sdoc('RES-020',1), sdoc('RES-020',3), 'semantic-derivation', "CITOGENESIS-03: operator marketing attaches the 20 MT / 2.5 mi programme-level design assumption to a specific building whose hardness class is undocumented.")
E(sdoc('RES-020',6), sdoc('RES-020',3), 'semantic-derivation', 'CITOGENESIS-03: the Long Lines literature carries the same transcribed figure.')
# CITOGENESIS-04: brokerage copy
E(sdoc('RES-040',2), sdoc('RES-041',4), 'semantic-derivation', "CITOGENESIS-04: 'almost 10 feet thick / epoxy-resin concrete / rebar over three inches' travels as a unit from the 20th Century Castles brokerage copy into design/travel press; FAS gives ~2.5 ft walls. Origin held as a hypothesis by the silo beat (dated negative receipt not run).")
# CITOGENESIS-08: announcement reported as accomplishment
E(sdoc('RES-036',4), sdoc('RES-036',1), 'explicit-citation', "CITOGENESIS-08: trade press within 48 hours of the 26 July 2022 governor's-office announcement relaying the company's statement.")
E(sdoc('RES-036',7), sdoc('RES-036',1), 'semantic-derivation', 'CITOGENESIS-08: consumer gallery terminus asserting present-tense operation; the tense changes as the claim travels.')
# coldwar-ct/coldwar-ma: one project
E(sdoc('RES-004',2), sdoc('RES-004',1), 'replication', 'N-COLDWARCTMA: coldwar-ct.com and coldwar-ma.com are one project; one lineage, two domains.')

SCHNEIDER_POOL = [LECTURE, sdoc('RES-032',1), sdoc('RES-032',2), SAUDER, PANDORA,
                  sdoc('RES-025',4), sdoc('RES-005',4), xdoc_id('dumblist-coreinsights'),
                  xdoc_id('dumblist-ddumb'), xdoc_id('silotips-secret-underground-bases')]
SUBTERRENE_SET = [sdoc('RES-026',0), sdoc('RES-026',1), sdoc('RES-026',2),
                  sdoc('RES-026',3), sdoc('RES-026',5)]

# ------------------------------------------------------------- citogenesis rows
CITOG = {c['id']: c for c in r['citogenesis']}
CITO_ROWS = []  # (pid, cito_id, laundering_doc, root_doc)
def C(pid, cito, laund, root): CITO_ROWS.append((pid, cito, laund, root))
C('RES-033-ORIGIN','CITOGENESIS-01', sdoc('RES-033',0), sdoc('RES-033',2))
C('RES-033-FEATURE','CITOGENESIS-01', sdoc('RES-033',0), sdoc('RES-033',2))
C('RES-012-FUNCTION','CITOGENESIS-02', sdoc('RES-012',2), sdoc('RES-012',0))
C('RES-012-FUNCTION-2','CITOGENESIS-02', sdoc('RES-012',2), sdoc('RES-012',0))
C('RES-013-FUNCTION','CITOGENESIS-02', sdoc('RES-013',7), sdoc('RES-013',0))
C('RES-018-HARDEN','CITOGENESIS-03', sdoc('RES-018',1), sdoc('RES-020',3))
C('RES-020-HARDEN','CITOGENESIS-03', sdoc('RES-020',4), sdoc('RES-020',3))
C('RES-016-FEATURE','CITOGENESIS-05', sdoc('RES-016',3), sdoc('RES-016',2))
C('RES-004-ORIGIN','CITOGENESIS-06', xdoc_id('dumblist-coreinsights'), sdoc('RES-004',3))
C('RES-004-FUNCTION','CITOGENESIS-06', xdoc_id('dumblist-coreinsights'), sdoc('RES-004',3))
C('RES-004-EXTENT','CITOGENESIS-07', sdoc('RES-004',0), None)
C('RES-005-FUNCTION','CITOGENESIS-07', sdoc('RES-005',0), None)
C('RES-031-ORIGIN','CITOGENESIS-10', sdoc('RES-031',3), None)
C('RES-036-CONTROL','CITOGENESIS-08', sdoc('RES-036',7), sdoc('RES-036',3))
C('RES-036-FUNCTION','CITOGENESIS-08', sdoc('RES-036',7), sdoc('RES-036',3))
C('RES-036-ORIGIN','CITOGENESIS-08', sdoc('RES-036',7), sdoc('RES-036',3))
C('RES-040-HARDEN','CITOGENESIS-04', sdoc('RES-040',2), sdoc('RES-041',4))
C('RES-041-ORIGIN','CITOGENESIS-04', sdoc('RES-041',1), sdoc('RES-041',4))
# graded.json also proposed CITOGENESIS-10 on RES-031-IDENTITY, which is not loaded (see DROPPED_PROPS)

# ----------------------------------------------------------------- claims
ORIGIN_PIDS = [pid for pid in loaded_pids if gprops[pid]['class'] == 'ORIGIN']
CLAIM_DATES = {   # only dates stated verbatim in the payload; confidence 'inferred', never 'receipted'
 'RES-027-ORIGIN': '1934-01-29',
 'RES-028-ORIGIN': '1934-11-16',
 'RES-029-ORIGIN': '1997-02-21',
 'RES-036-ORIGIN': '2022-07-26',
}
CLAIM_FIRST_DOC = {
 'RES-032-ORIGIN': LECTURE,
 'RES-025-ORIGIN': PANDORA,
 'RES-036-ORIGIN': sdoc('RES-036',1),
}
CLAIM_CLUSTER = {
 'RES-025-ORIGIN': 'N-SCHNEIDER', 'RES-032-ORIGIN': 'N-SCHNEIDER',
 'RES-041-ORIGIN': 'N-20THCENT',  'RES-033-ORIGIN': 'N-POLLOCK-1976',
 'RES-035-ORIGIN': 'N-SHAVER',
}

# ------------------------------------------------------------ entity relations
REL = []  # (from, to, kind, note)
def RELROW(a, b, kind, note): REL.append((ent_id(a), ent_id(b), kind, trunc(note, 900)))
rm = r['refused_merges']
RELROW('RES-036','RES-037','DISTINCT-FROM', rm[0]['why'])
RELROW('RES-036','RES-038','DISTINCT-FROM', rm[0]['why'])
RELROW('RES-037','RES-038','DISTINCT-FROM', rm[0]['why'])
RELROW('RES-045','RES-046','PART-OF', rm[1]['why'])
RELROW('RES-001','RES-025','DISTINCT-FROM', rm[2]['why'])
RELROW('RES-003','RES-044','DISTINCT-FROM', rm[3]['why'])
for m in ('RES-013','RES-014','RES-015','RES-016','RES-017'):
    RELROW('RES-012', m, 'PARENT-OF', rm[4]['why'])
RELROW('RES-018','RES-012','DISTINCT-FROM', rm[5]['why'])
RELROW('RES-025','RES-032','DISTINCT-FROM', rm[8]['why'] + ' | LINEAGES POOLED, NOT SUMMED: same single terminus (N-SCHNEIDER); see the citation graph.')
_atlas = ['RES-039','RES-040','RES-041','RES-047']
for i in range(len(_atlas)):
    for j in range(i+1, len(_atlas)):
        RELROW(_atlas[i], _atlas[j], 'DISTINCT-FROM', rm[9]['why'])

# ------------------------------------------------------------------- leads
def find_src(cid, needle):
    for i, s in enumerate(rcands[cid]['sources']):
        if needle.lower() in (s['citation'] + ' ' + s.get('url','')).lower():
            return i
    return None
LEADS = []
def LEAD(identifier, cid, needle, host, advw, note_unused=None):
    i = find_src(cid, needle)
    LEADS.append((identifier, doc_id(cid, i) if i is not None else None, host, advw))
LEAD('AD1078617', 'RES-011', 'AD1078617', 'apps.dtic.mil', False)
LEAD('310505952', 'RES-020', 'facilityexplorer', 'facilityexplorer.iowadnr.gov', False)
LEAD('CMPT-2016-0001', 'RES-013', 'CMPT-2016-0001', 'loudoun.gov', False)
LEAD('HGTWMDQ0010', 'RES-015', 'LaFrance', 'coldwar-c4i.net', True)
LEAD('LSBGVA05', 'RES-013', 'LaFrance', 'coldwar-c4i.net', True)

# ------------------------------------------------------------------ SQL build
# Sections are ordered lists of statements; statements are later PACKED into
# chunks of at most ~70 KB so each chunk fits comfortably in one SQL-over-HTTP
# call (docs/DEPLOY-REPORT.md reports 215 KB was too large for one call).
SOFT_CAP = 70 * 1024
sections = []   # (title, [stmt, ...])  — a stmt is a self-contained SQL string
def chunk(title, body):
    """Accept a prebuilt body as a single section of one statement-blob."""
    sections.append((title, [body]))

def values_insert(table, cols, rows, conflict, prelude='', batch_bytes=60*1024):
    """Return a LIST of INSERT statements, batching rows so no single statement
    exceeds ~batch_bytes. The prelude comment rides on the first statement."""
    if not rows: return []
    stmts, cur, cur_len = [], [], 0
    head = 'insert into %s\n  (%s)\nvalues\n' % (table, ', '.join(cols))
    for row in rows:
        rtxt = '  (%s)' % ', '.join(row)
        if cur and cur_len + len(rtxt) > batch_bytes:
            stmts.append(head + ',\n'.join(cur) + '\n' + conflict + ';\n')
            cur, cur_len = [], 0
        cur.append(rtxt); cur_len += len(rtxt) + 2
    stmts.append(head + ',\n'.join(cur) + '\n' + conflict + ';\n')
    if prelude:
        stmts[0] = prelude + '\n' + stmts[0]
    return stmts

def section(title, stmts):
    if isinstance(stmts, str): stmts = [stmts]
    flat = []
    for s in stmts:
        if isinstance(s, list): flat.extend(s)
        else: flat.append(s)
    sections.append((title, [s for s in flat if s and s.strip()]))

# ---- CHUNK 1: registry prerequisites, agent runs, curation proposals
b = []
b.append("""-- Scorer identity for the W1 grading pass. registry.scorer_model is reviewed-write;
-- this is the model named by graded.json (scorer_model_id, rubric BES v0.2).
insert into registry.scorer_model (scorer_model_id, model_family, vendor, role)
values ('claude-opus-5', 'claude', 'Anthropic', 'ASSESSOR')
on conflict (scorer_model_id) do nothing;
""")
beat_counts = {}
for c in r['candidates']:
    for m in c['merged_from']:
        beat_counts.setdefault(m['beat'], set()).add(m['index'])
runs = [("beat-%s" % beat, 'W1-discovery', len(idx),
         'W1 discovery beat, searching blind to the other three. Every citation SEARCH-SNIPPET-ONLY / FETCH-BLOCKED / CITED-BY-OTHERS-NOT-SEEN; nothing resolved to bytes.')
        for beat, idx in sorted(beat_counts.items())]
runs.append(('resolver', 'W1-resolution', 48, trunc(r['standing_caveat'], 800)))
runs.append(('grader', 'W1-grading', 48, trunc(g['headline'] + ' ' + g['standing_caveat'], 900)))
for agent, wf, n, note in runs:
    b.append("""insert into ingest.agent_run (agent, scorer_model_id, workflow, finished_at, candidates_returned, notes)
select %s, 'claude-opus-5', %s, now(), %d, %s
where not exists (select 1 from ingest.agent_run where agent = %s and workflow = %s);
""" % (q(agent), q(wf), n, q(note), q(agent), q(wf)))
for key, node in r['shared_lineage_nodes'].items():
    payload = {'node_id': key, 'node': node['node'], 'kind': node['kind'],
               'tiered_by_beats': node.get('tiered_by_beats'),
               'tier_disagreement': node.get('tier_disagreement'),
               'note': trunc(node.get('note',''), 1200),
               'touches': node.get('touches')}
    b.append("""insert into ingest.curation_proposal (target_table, payload, proposed_by)
select 'corpus', %s, %s
where not exists (select 1 from ingest.curation_proposal
                   where target_table = 'corpus' and payload->>'node_id' = %s);
""" % (qj(payload), q(ACTOR), q(key)))
section('registry prerequisites: scorer model, W1 agent runs, shared-lineage-node corpus proposals (ingest.curation_proposal — the schema path for agent-proposed curated rows)', b)

# ---- CHUNK 2: entities, aliases, relations, geometry
rows = []
for e in g['entities']:
    cid = e['entity_id']; c = rcands[cid]
    beats = '/'.join(sorted({m['beat'] for m in c['merged_from']}))
    rows.append([q(ent_id(cid)), q(slugify(cid, e['name'])), q(entity_level(e['scope'])),
                 q(trunc(e['name'], 480)), "'US'", q(e['reference_class']),
                 q('W1 sweep-01 (beats: %s); scope as carried: %s' % (beats, trunc(e['scope'],120)))])
ent_stmts = values_insert('core.entity',
    ['entity_id','slug','entity_level','canonical_name','country_code','reference_class','discovered_by'],
    rows, 'on conflict (entity_id) do nothing',
    "-- 48 entities. publication_state defaults to INTERNAL; typology_cached defaults to 'unknown-anomaly'\n"
    "-- (graded.json: no TYPOLOGY proposition clears band C, so the carried typology labels stay ungraded claims).\n"
    "-- entity_level has no value for population/system/claim scopes; mapping documented in db/ingest/README.md.")
ent_stmts.append("""
-- Hierarchy carried from resolved.json: the Project Office chain is a system-scope record whose
-- extension is exactly its five member stations; Oscar-Zero/November-33 is CONTAINED IN the Grand
-- Forks population record (containment, not identity — CONTRA-06).
update core.entity set parent_entity_id = %s
 where entity_id in (%s) and parent_entity_id is null;
update core.entity set parent_entity_id = %s
 where entity_id = %s and parent_entity_id is null;
""" % (q(ent_id('RES-012')),
       ', '.join(q(ent_id(m)) for m in ('RES-013','RES-014','RES-015','RES-016','RES-017')),
       q(ent_id('RES-046')), q(ent_id('RES-045'))))
arows = []
for e in g['entities']:
    seen = set()
    for a in e['aliases']:
        a = a.strip()
        if not a or a.lower() in seen: continue
        seen.add(a.lower())
        arows.append([q(ent_id(e['entity_id'])), "'facility-name'", q(trunc(a, 300)), q(ACTOR)])
ent_stmts += values_insert('core.entity_alias', ['entity_id','alias_kind','alias_text','added_by'],
    arows, 'on conflict (entity_id, alias_kind, alias_text) do nothing',
    '-- Aliases as carried by the sweep. All loaded as facility-name kind; none adjudicated as codenames\n'
    '-- (a codename is binding-admissible only with an IDENTITY proposition at band C — none exists).')
rrows = [[q(a), q(b_), q(k), q(ACTOR), q(n)] for a,b_,k,n in REL]
ent_stmts += values_insert('core.entity_relation', ['from_entity_id','to_entity_id','kind','asserted_by','note'],
    rrows, 'on conflict (from_entity_id, to_entity_id, kind) do nothing',
    "-- Refused merges and containments from resolved.json, held apart structurally (BES §11.1:\n"
    "-- proximity and name similarity FLAG, never merge). Includes the two Denvers, the Safeguard\n"
    "-- triple, Netcong-is-not-a-Project-Office, and the four converted Atlas sites.")
grows = []
for e in g['entities']:
    cid = e['entity_id']; c = rcands[cid]; loc = c['location']
    prec = loc.get('precision','none')
    non_located = (prec == 'none')
    placename = None if non_located else trunc(c.get('jurisdiction') or loc.get('description',''), 300)
    note = 'precision as carried by resolved.json: %s. %s' % (prec, trunc(loc.get('description',''), 500))
    basis = loc.get('basis')
    if basis: note += ' | basis: ' + trunc(basis, 400)
    if 'population' in e['scope'].lower(): note += ' | SCOPE: population — must never be rendered as a pin.'
    if cid == 'RES-042': note += ' | SPLIT REQUIRED before any member is rendered (two complexes in one record).'
    if cid == 'RES-047': note += ' | Site identity unresolved among twelve 579th SMS sites; must not be pinned.'
    grows.append([q(geom_id(cid)), q(ent_id(cid)),
                  q('non_located' if non_located else 'place_name_only'),
                  q(placename), "'narrative-description'", q(ACTOR), 'true', q(trunc(note, 1400))])
ent_stmts += values_insert('core.geometry_assertion',
    ['geometry_assertion_id','entity_id','precision','claimed_place_name','derivation','asserted_by','is_preferred','note'],
    grows, 'on conflict (geometry_assertion_id) do nothing',
    "-- Geometry: the sweep holds NO coordinate for any entity (the beats declined to fabricate lat/lon),\n"
    "-- so every located record carries place_name_only (the words we hold, nothing more) and the four\n"
    "-- non-located claims carry non_located. The resolved.json precision claim is preserved in the note.\n"
    "-- Nothing here can render as a pin: LOCATE is ungraded everywhere and render_geometry gates on band C.")
section('entities, aliases, refused-merge relations, geometry (all place_name_only / non_located: no coordinate is held)', ent_stmts)

# ---- CHUNK 3: claims + propositions part 1
crows = []
for pid in ORIGIN_PIDS:
    p = gprops[pid]; cid = p['entity_id']
    fa_date = CLAIM_DATES.get(pid)
    crows.append([q(claim_id(pid)), q(trunc(p['statement'], 1200)), q(ent_id(cid)),
                  q(CLAIM_CLUSTER.get(pid)), q(CLAIM_FIRST_DOC.get(pid)),
                  q(fa_date), q('inferred' if fa_date else 'unknown')])
# defer document FK: blank it here, backfill after documents exist
for row in crows:
    row[4] = 'null'
claims_stmts = values_insert('core.claim',
    ['claim_id','claim_text','entity_id','cluster_key','first_appearance_document_id','first_appearance_date','first_appearance_confidence'],
    crows, 'on conflict (claim_id) do nothing',
    "-- One core.claim per ORIGIN proposition. first_appearance_date only where a single date is stated\n"
    "-- verbatim in the payload, and always confidence 'inferred' — never 'receipted' (nothing resolved).\n"
    "-- first_appearance_document_id is back-filled in the documents section, after those rows exist.")

def prop_rows(pids):
    rows = []
    for pid in pids:
        p = gprops[pid]
        cid = p['entity_id']
        args = predicate_args(pid, p)
        pkey = pid[len(cid)+1:].lower()
        objid = q(ent_id(cid)) if pid in SELF_IDENTITY else 'null'
        clm = q(claim_id(pid)) if p['class'] == 'ORIGIN' else 'null'
        rows.append([q(prop_id(pid)), q(ent_id(cid)), q(p['class']), objid, clm,
                     qj(args), q(pkey), q(trunc(p['statement'], 1600)),
                     q(p['null_hypothesis']), "'unknown-anomaly'", q(p.get('reference_class')),
                     q(ACTOR)])
    return rows

half = [pid for pid in loaded_pids if int(pid.split('-')[1]) <= 24]
rest = [pid for pid in loaded_pids if int(pid.split('-')[1]) > 24]
PROP_COLS = ['proposition_id','entity_id','class','object_entity_id','claim_id','predicate_args','predicate_key',
             'statement_text','null_code','typology_profile','reference_class','created_by']
prop_stmts = claims_stmts + values_insert('core.proposition', PROP_COLS,
    prop_rows(half) + prop_rows(rest), 'on conflict (proposition_id) do nothing',
    "-- Propositions. 195 of graded.json's 200 load; the five that cannot be expressed are listed in\n"
    "-- db/ingest/README.md (one duplicate EXIST on the merged Notch record, four IDENTITY propositions\n"
    "-- whose object entity is outside this register).\n"
    "-- typology_profile is 'unknown-anomaly' everywhere per graded.json; function_set stays 'n/a';\n"
    "-- rubric_version defaults to 'BES-0.2.0'. STATUS/EXTENT/PROGRAM/CONTROL predicate_args mappings\n"
    "-- are ingest judgement calls documented in README.md, marked *_basis inside the jsonb.")
section('claims (ORIGIN subjects) + 195 propositions', prop_stmts)

# ---- CHUNKS 5/6: documents (+ dossiers, pool docs, claim backfill)
DOC_COLS = ['document_id','title','url','origin_tier','tier_assigned_by','causal_provenance','channel',
            'corpus_era','self_attesting','self_attesting_rationale','register_echo_quarantined',
            'register_echo_reason','authored_by_agent','agent_model_family','is_compiler','compiler_transparent']
def doc_values(cid_lo, cid_hi):
    rows = []
    for c in r['candidates']:
        n = int(c['id'].split('-')[1])
        if not (cid_lo <= n <= cid_hi): continue
        for i, s in enumerate(c['sources']):
            d = doc_row(c['id'], i, s)
            rows.append([q(d['document_id']), q(d['title']), q(d['url']), q(d['origin_tier']),
                         q(d['tier_assigned_by']), q(d['causal']), q(d['channel']), q(d['era']),
                         'true' if d['self_att'] else 'false', q(d['self_att']),
                         'true' if d['quarantine'] else 'false', q(d['quarantine']),
                         'false', 'null', 'false', 'null'])
    return rows

doc_stmts = values_insert('core.source_document', DOC_COLS, doc_values(1, 48),
    'on conflict (document_id) do nothing',
    "-- Source documents (one row per source in resolved.json). origin_tier stays PENDING (scores as\n"
    "-- T4: supports C/D, never A/B) except beat-consensus P5 material, carried as T5, and never above.\n"
    "-- The legacy P-tier and the honest retrieval state travel on each document's retrieval receipt\n"
    "-- (later section). registry.corpus is not yet populated, so corpus_id stays null and the\n"
    "-- shared-node tier disputes are filed as ingest.curation_proposal rows (section 1).")

xrows = []
for key, x in XDOCS.items():
    xrows.append([q(xdoc_id(key)), q(x['title']), q(x['url']), "'T5'",
                  q('sweep-01-ingest: named in resolved.json refuted_or_hollow records; fringe self-published corpus'),
                  "'UNSOLICITED'", "'ORIGIN-HOST'", q(x['era']),
                  'false','null','false','null','false','null','false','null'])
drows = []
for c in r['candidates']:
    drows.append([q(dossier_id(c['id'])),
                  q('W1 sweep dossier — %s: %s (research/candidates/resolved.json)' % (c['id'], trunc(c['name'],200))),
                  'null', "'T5'",
                  q('constraint document_agent_interpretation_is_t5: agent-authored, no second-family confirmation'),
                  "'UNSOLICITED'", "'ORIGIN-HOST'", "'POST-2022-ATTRIBUTED'",
                  'false','null','false','null','true', q('claude'), 'true', 'true'])
doc_stmts += values_insert('core.source_document', DOC_COLS, xrows,
    'on conflict (document_id) do nothing',
    "-- Three carrier documents for Schneider claim families 4 and 5 (FEMA-regional-centres-as-DUMB-nodes\n"
    "-- and silos-as-DUMB-entrances), named in resolved.json refuted_or_hollow records. They exist here\n"
    "-- solely to carry the lineage collapse as citation-graph structure; no observation cites them.")
doc_stmts += values_insert('core.source_document', DOC_COLS, drows,
    'on conflict (document_id) do nothing',
    "-- 48 W1 sweep dossiers: one T5, agent-authored, TRANSPARENT-COMPILER document per candidate,\n"
    "-- representing the resolved.json record itself. Observations cite the dossier (the artifact the\n"
    "-- register actually holds) rather than guessing per-proposition attributions onto web sources the\n"
    "-- sweep never resolved; the dossier exposes its sources through compiler-exposes edges (later\n"
    "-- section), which do NOT collapse lineages — a transparent compiler is a conduit (BES §5.1.3).")
# claim first-appearance backfill
backfill = []
for pid, did in CLAIM_FIRST_DOC.items():
    backfill.append("""update core.claim set first_appearance_document_id = %s
 where claim_id = %s and first_appearance_document_id is null;""" % (q(did), q(claim_id(pid))))
doc_stmts.append('-- claim first-appearance back-links, now that the documents exist\n' + '\n'.join(backfill) + '\n')
section('source documents (257 sweep sources + 3 Schneider-family carriers + 48 W1 dossiers), claim back-links', doc_stmts)

# ---- CHUNK 7: receipts
rrows = []
for c in r['candidates']:
    for i, s in enumerate(c['sources']):
        if s.get('retrieval_state') == 'FETCHED':
            continue   # the register's own calibration text: no retrieval happened or should be implied
        url = (s.get('url') or '').strip()
        requested = url if url else ('unresolved: no URL held; citation: ' + trunc(s['citation'], 300))
        reason = '[%s | %s] %s' % (s.get('tier','P?'), s.get('retrieval_state','?'),
                                   trunc(s.get('what_it_actually_shows',''), 1800))
        rrows.append([q(rcpt_id(c['id'], i)), q(doc_id(c['id'], i)), q(requested),
                      "'UNRESOLVED'", "'code'", q(reason)])
for key, x in XDOCS.items():
    rrows.append([q(xrcpt_id(key)), q(xdoc_id(key)), q(x['url']), "'UNRESOLVED'", "'code'",
                  q('[P5 | SEARCH-SNIPPET-ONLY] ' + trunc(x['what'], 900))])
section('retrieval receipts — every source honestly UNRESOLVED (V0)',
    values_insert('core.retrieval_receipt',
    ['receipt_id','document_id','requested_url','receipt_state','verifier_kind','failure_reason'],
    rrows, 'on conflict (receipt_id) do nothing',
    "-- One retrieval receipt per source document, ALL receipt_state='UNRESOLVED': not one citation in\n"
    "-- this sweep was resolved to bytes. The specific state (SEARCH-SNIPPET-ONLY / FETCH-BLOCKED /\n"
    "-- CITED-BY-OTHERS-NOT-SEEN), the legacy P-tier, and the beat's own SAW/INFER accounting are\n"
    "-- preserved verbatim in failure_reason. No sha256, no http_status, no resolved_url: none exist.\n"
    "-- receipt_verified_requires_everything makes VERIFIED unreachable from here, which is the point.\n"
    "-- (The RES-011 self-reference to docs/CALIBRATION.md gets no receipt: nothing was retrieved.)"))

# ---- CHUNK 8: citation edges
erows = []
for c in r['candidates']:
    for i, s in enumerate(c['sources']):
        erows.append([q(dossier_id(c['id'])), q(doc_id(c['id'], i)), "'compiler-exposes'",
                      "'manual'", "'same-lineage'", q(ACTOR),
                      q('W1 dossier source list (transparent compiler passthrough; does not collapse).')])
edge_stmts = values_insert('core.document_citation',
    ['citing_document_id','cited_document_id','edge_kind','detection_method','counterfactual_verdict','asserted_by','note'],
    erows, 'on conflict (citing_document_id, cited_document_id, edge_kind) do nothing',
    "-- Dossier -> source edges: compiler-exposes, which by the generated collapses_lineage column can\n"
    "-- never merge two sources into one lineage through the dossier hub.")
srows = []
for a, b_, kind, note in EDGES:
    srows.append([q(a), q(b_), q(kind), "'manual'", "'same-lineage'", q(ACTOR), q(trunc(note, 900))])
edge_stmts += values_insert('core.document_citation',
    ['citing_document_id','cited_document_id','edge_kind','detection_method','counterfactual_verdict','asserted_by','note'],
    srows, 'on conflict (citing_document_id, cited_document_id, edge_kind) do nothing',
    "-- Lineage findings from RESOLUTION-NOTES as graph structure. The five Schneider claim families\n"
    "-- (DIA base; 129/1,477 numerology; subterrene tunnel network inference; FEMA-centres-as-DUMB-nodes;\n"
    "-- silos-as-DUMB-entrances) all reach the 1995 Preparedness Expo lecture through collapsing edges:\n"
    "-- core.lineage_components() resolves the pool to ONE component (asserted in sweep-01-verify.sql).\n"
    "-- The four institutional subterrene roots stay unconnected to the pool — finding a link LOWERS a\n"
    "-- grade (BES §5.7), and letting LA-5354-MS launder the network claim would be citogenesis by the\n"
    "-- register itself. Also encoded: Grokipedia mirror-of Wikipedia (CITOGENESIS-09), FAS+GlobalSecurity\n"
    "-- as one node, the WVOCCO coinage (CITOGENESIS-01), LaFrance hedge-stripping (CITOGENESIS-02),\n"
    "-- the qsl.net 20-megaton chain (CITOGENESIS-03), brokerage copy (CITOGENESIS-04), and the Nekoma\n"
    "-- announcement chain (CITOGENESIS-08).")
section('citation graph: dossier compiler-exposes edges + the lineage-collapse structure (Schneider pool as ONE origin)', edge_stmts)

# ---- CHUNKS 9/10: observations
def obs_rows(pids):
    rows = []
    for pid in pids:
        rp = aligned[pid]
        cid = gprops[pid]['entity_id']
        for kind, sign in (('supporting','SUPPORTS'), ('undercutting','UNDERCUTS')):
            for i, entry in enumerate(rp.get(kind) or []):
                if entry.strip().lower().startswith('none'):
                    continue
                stmt = trunc(entry, 1200)
                rows.append([q(obs_id(pid, kind, i)), q(prop_id(pid)), q(dossier_id(cid)),
                             q(stmt), q(sign), '0', "'DEFAULT'", "'CLAIM-PROPERTY'",
                             q('resolved.json W1 (beats via resolution pass)'), q(SCORER),
                             q('V0 by construction: the underlying source was never resolved to bytes; '
                               'this row records the W1 dossier assertion and is arithmetically inert (D0, unverified receipt).')])
    return rows
OBS_COLS = ['observation_id','proposition_id','document_id','statement','sign','magnitude',
            'diagnosticity_source','property_locus','asserted_by','asserted_model_id','notes']
section('observations — every row V0 by construction',
    values_insert('core.observation', OBS_COLS, obs_rows(half) + obs_rows(rest),
    'on conflict (observation_id) do nothing',
    "-- Observations. One row per supporting/undercutting entry carried by resolved.json for a\n"
    "-- loaded proposition. Every row cites the W1 dossier (the artifact actually held), at magnitude 0\n"
    "-- (DEFAULT = D0: no diagnosticity is claimed for unread text), scope CLASS, binding unadjudicated.\n"
    "-- With no receipt, the provenance-sync trigger sets prov_receipt_state='UNRESOLVED' and the\n"
    "-- GENERATED membership column lands every row in V0: retained, displayed, arithmetically inert.\n"
    "-- Six 'None found' entries in resolved.json are search notes, not observations, and are not loaded."))

# ---- CHUNK 11: ERP applicability, dispositions, citogenesis, leads, tasks
b = []
skip = sorted(F_PROPS_NO_ERP | {F_PROP_X0_ONLY})
b.append("""-- Expected-record applicability, per proposition (core.proposition_erp): the canonical class
-- mapping from registry.erp_profile.applies_to_classes, current ERP version, all UNSEARCHED —
-- egress blocked every canonical corpus, so SCI numerators are zero across the sweep and the SCI
-- floor withholds the band (X) wherever an X>=1 profile applies. Four propositions carry the
-- explicit adjudication from graded.json instead (see below) and are excluded here.
-- NOTE: the seeded ERP catalog has NO profiles for STATUS, ORIGIN, IDENTITY or TYPOLOGY, so those
-- classes get an empty X>=1 denominator, SCI = 1.000 by the denominator-zero correction, and the
-- SCI floor cannot withhold their F. That is a schema-vs-payload divergence surfaced in README.md.
insert into core.proposition_erp (proposition_id, erp_profile_id, applicable, resolved_x, resolution_note, searched)
select p.proposition_id, ep.erp_profile_id, true, ep.x_level,
       'W1 sweep-01: applicability by canonical class mapping; profile default X-level; unsearched (egress blocked, BES 2.6 -> UNSEARCHED, never NEGATIVE)',
       false
  from core.proposition p
  join core.entity e on e.entity_id = p.entity_id
  join registry.erp_profile ep
    on ep.country_code = 'US'
   and p.class = any(ep.applies_to_classes)
   and ep.erp_version_id = (select table_version_id from registry.table_version
                             where table_name = 'erp' and is_current)
 where e.slug ~ '^res-0[0-9][0-9]-'
   and p.created_by = %s
   and p.proposition_id not in (%s)
on conflict (proposition_id, erp_profile_id) do nothing;
""" % (q(ACTOR), ', '.join(q(prop_id(x)) for x in skip)))
b.append("""-- graded.json's explicit ERP adjudication for the four F-graded propositions:
-- RES-029-FUNCTION, RES-035-EXIST, RES-035-FUNCTION: "Applicable ERP profiles: none" — no record
-- class of any era or authority bears on the claim, so NO rows are created and the X>=1 denominator
-- is empty (SCI = 1.000 by the §7.2 denominator-zero correction; CAP-5 then yields F, the only
-- route to a band in this sweep). RES-032-FUNCTION: every applicable profile is X0 (covert facility
-- set) — structurally the Greenbrier-1991 / Mount Pony case:
insert into core.proposition_erp (proposition_id, erp_profile_id, applicable, resolved_x, resolution_note, searched)
select %s, ep.erp_profile_id, true, 'X0',
       'graded.json adjudication: for the FUNCTION of a claimed covert facility set, every applicable profile resolves X0 (NIP/MIP construction; any record under commercial cover; CREST/DTIC still classified). X>=1 denominator empty by design.',
       false
  from registry.erp_profile ep
 where ep.country_code = 'US'
   and ep.profile_key in (%s)
   and ep.erp_version_id = (select table_version_id from registry.table_version
                             where table_name = 'erp' and is_current)
on conflict (proposition_id, erp_profile_id) do nothing;
""" % (q(prop_id(F_PROP_X0_ONLY)), ', '.join(q(k) for k in X0_PROFILES_032)))
adrows = []
for pid in loaded_pids:
    p = gprops[pid]
    reasoning = trunc('%s | null_state as graded: %s. %s' %
                      (p['null_hypothesis_text'], p['null_state'], p['null_state_note']), 1800)
    adrows.append([q(prop_id(pid)), q(p['null_hypothesis']), 'true', "'selected-strongest'",
                   q(reasoning), q(SCORER + ' (W1 grading pass)')])
b.append(values_insert('core.alternative_disposition',
    ['proposition_id','null_code','is_selected','disposition','reasoning','assessed_by'],
    adrows, 'on conflict (proposition_id, null_code) do nothing',
    "-- The REFUTER's null selection, carried per proposition from graded.json. With a selected\n"
    "-- alternative on file, core.derive_null_state() returns SURVIVING (vacuously: the null accounts\n"
    "-- for all zero rows in V) rather than UNTESTED — exactly as graded.json derived it."))
citrows = []
for pid, cito, laund, root in CITO_ROWS:
    cinfo = CITOG[cito]
    narrative = trunc('%s [%s, severity %s] claim: %s | origin: %s | laundering path: %s | test: %s' %
                      (cito, 'proposed by W1, NOT confirmed', cinfo.get('severity','?'), cinfo.get('claim',''),
                       cinfo.get('origin',''), cinfo.get('laundering_path',''), cinfo.get('test','')), 2400)
    citrows.append((pid, cito, laund, root, narrative))
cit_sql = ["-- Citogenesis findings, attached to the PROPOSITION (the fix v0.1 lacked), state 'suspected':",
           "-- the beats proposed these and explicitly declined to confirm (the settling searches — the",
           "-- federal-record phrase check, the Wayback CDX pass — were never run). Only a CONFIRMED loop",
           "-- triggers CAP-3, so these do not move grades; they are the research queue, priced."]
for pid, cito, laund, root, narrative in citrows:
    cit_sql.append("""insert into core.citogenesis_loop
  (proposition_id, laundering_document_id, t5_root_document_id, detected_by, state, narrative)
select %s, %s, %s, %s, 'suspected', %s
where not exists (select 1 from core.citogenesis_loop
                   where proposition_id = %s and laundering_document_id = %s and detected_by = %s);""" %
        (q(prop_id(pid)), q(laund), q(root), q(ACTOR), q(narrative),
         q(prop_id(pid)), q(laund), q(ACTOR)))
b.append('\n'.join(cit_sql) + '\n')
lead_sql = ["-- Unverified identifiers stay LEADS (BES §2.7): the firewall table, never a citation.",
            "-- These are the identifiers the beats explicitly declared unresolved — including AD1078617,",
            "-- which the Raven Rock beat flagged as its own possible confabulation. identifier_class is",
            "-- null because registry.identifier_grammar is not yet seeded (documented in README.md)."]
for ident, from_doc, host, advw in LEADS:
    lead_sql.append("""insert into ingest.lead (identifier, extracted_from_document_id, extracted_from_host, is_adversary_writable_origin)
select %s, %s, %s, %s
where not exists (select 1 from ingest.lead where identifier = %s and extracted_from_host = %s);""" %
        (q(ident), q(from_doc), q(host), 'true' if advw else 'false', q(ident), q(host)))
b.append('\n'.join(lead_sql) + '\n')
task_sql = ["-- Cross-beat contradictions: recorded, not adjudicated (ingest.adjudication_task, stage REVIEW)."]
CONTRA_ENT = {'CONTRA-01':'RES-022','CONTRA-02':'RES-022','CONTRA-03':'RES-022','CONTRA-06':'RES-046'}
for ct in r['cross_beat_contradictions']:
    note = trunc('%s | subject: %s | %s' % (ct['id'], ct.get('subject',''), ct.get('resolution_note','')), 1400)
    eid = q(ent_id(CONTRA_ENT[ct['id']])) if ct['id'] in CONTRA_ENT else 'null'
    task_sql.append("""insert into ingest.adjudication_task (entity_id, stage, state, note)
select %s, 'REVIEW', 'queued', %s
where not exists (select 1 from ingest.adjudication_task where note like %s);""" %
        (eid, q(note), q(ct['id'] + ' |%')))
for eid_, stage, note in [
    ('RES-042','RESOLVER','SPLIT REQUIRED: RES-042 covers Titan I Complex 2C (Elbert County) AND Complex 2B (Deer Trail) in one record; six former Titan I complexes remain in Colorado. Must be split before any member is rendered as a pin.'),
    ('RES-047','RESOLVER',"IDENTITY UNRESOLVED: the converted Atlas F lodging site is one of twelve 579th SMS sites at Roswell — 'WHICH ONE IS UNKNOWN TO ME' preserved verbatim; must not be pinned or merged with any enthusiast page for 579-1..579-12.")]:
    task_sql.append("""insert into ingest.adjudication_task (entity_id, stage, state, note)
select %s, %s, 'queued', %s
where not exists (select 1 from ingest.adjudication_task where note like %s);""" %
        (q(ent_id(eid_)), q(stage), q(note), q(note[:40] + '%')))
b.append('\n'.join(task_sql) + '\n')
section('ERP applicability, null dispositions, suspected citogenesis, identifier leads, adjudication tasks', b)

# ---- CHUNK 12: grading through the schema's own path
grading = """-- Grade every loaded proposition THROUGH THE SCHEMA'S OWN PATH: core.apply_grade(), which calls
-- core.recompute_proposition() -> core.evaluate_proposition() and appends the immutable grade_event.
-- EXIST propositions first, so the monotone clamp never reads a missing parent.
--
-- KNOWN, DELIBERATELY SURFACED FAILURE MODE (do not "fix" by hand): a child whose own band is F
-- (empty X>=1 ERP denominator -> SCI 1.000) under an EXIST parent graded X gets clamped BY THE
-- SCHEMA to X (core.grade_min treats unranked X as dominating), and the resulting grade_event
-- violates grade_x_has_low_sci (grade='X' requires sci < 0.5, but this child's sci is 1.000).
-- graded.json reads BES §1.4 the other way ("X is unranked and does not clamp children").
-- This affects the STATUS/IDENTITY/TYPOLOGY classes (no seeded ERP coverage) and two of the four
-- graded-F propositions (RES-029-FUNCTION, RES-032-FUNCTION). For those rows we fall back to
-- core.recompute_proposition() — the rollup is cached (grade X-by-clamp, grade_pre_clamp F), no
-- grade_event exists, and the regrade-queue row is parked with attempts=3 and the error text so the
-- defect stays visible until the schema decision is made. Details: db/ingest/README.md §Findings.
-- RE-RUN BEHAVIOUR: a second run of this chunk converges cleanly — apply_grade recomputes the same
-- grades, appends no new events (a grade_event is written only when a grade MOVES), and clears the
-- 28 parked queue rows because the cached clamped rollup now equals the recomputation.
do $sweep$
declare
  rec record;
  n_ok integer := 0;
  n_fail integer := 0;
  failed uuid[] := '{}';
  msgs text := '';
begin
  for rec in
    select p.proposition_id
      from core.proposition p
      join core.entity e on e.entity_id = p.entity_id
     where e.slug ~ '^res-0[0-9][0-9]-' and p.created_by = 'sweep-01-ingest'
     order by (p.class <> 'EXIST'), p.proposition_id
  loop
    begin
      perform core.apply_grade(rec.proposition_id, 'INITIAL', 'claude-opus-5',
        'W1 sweep-01 initial grading: every observation V0-UNRESOLVED by construction; graded through the schema''s own evaluate/recompute/apply path.');
      n_ok := n_ok + 1;
    exception when others then
      n_fail := n_fail + 1;
      failed := failed || rec.proposition_id;
      msgs := msgs || rec.proposition_id::text || ': ' || sqlerrm || E'\\n';
      -- schema-path fallback: cache the rollup (no immutable event can be written for this state)
      perform core.recompute_proposition(rec.proposition_id);
    end;
  end loop;

  -- Park the queue rows of the propositions that cannot converge, visibly.
  update ingest.regrade_queue q
     set attempts = 3,
         last_error = 'sweep-01: apply_grade raised (clamp-to-X vs grade_x_has_low_sci; see db/ingest/README.md): parked pending schema decision'
   where q.proposition_id = any(failed);

  raise notice 'sweep-01 grading: apply_grade converged on % propositions (events are appended only when a grade moves; expect 167 events on first run, 0 new on re-runs), % parked (rollup cached, no grade_event): %',
    n_ok, n_fail, msgs;
end
$sweep$;

-- Final state summary (informational; the assertions live in sweep-01-verify.sql).
select pr.grade, count(*) as propositions
  from core.proposition_rollup pr
  join core.proposition p using (proposition_id)
  join core.entity e on e.entity_id = p.entity_id
 where e.slug ~ '^res-0[0-9][0-9]-' and p.created_by = 'sweep-01-ingest'
 group by pr.grade
 order by pr.grade;
"""
chunk("grade computation via the schema's own functions (apply_grade / recompute / evaluate)", grading)

# --------------------------------------------------------------- pack chunks
# Pack the ordered statements into chunks of <= SOFT_CAP bytes. Section order is
# preserved; a section may span chunks; the grading section always stands alone
# as the final chunk.
packed = []        # list of (title, body)
cur_stmts, cur_len, cur_titles = [], 0, []
def flush():
    global cur_stmts, cur_len, cur_titles
    if cur_stmts:
        packed.append((' | '.join(dict.fromkeys(cur_titles)), '\n'.join(cur_stmts)))
        cur_stmts, cur_len, cur_titles = [], 0, []
for title, stmts in sections[:-1]:
    for s in stmts:
        if cur_stmts and cur_len + len(s) > SOFT_CAP:
            flush()
        cur_stmts.append(s); cur_len += len(s) + 1
        if title not in cur_titles: cur_titles.append(title)
flush()
packed.append((sections[-1][0], '\n'.join(sections[-1][1])))
chunks = packed

# --------------------------------------------------------------- write main file
N = len(chunks)
hdr = """-- ============================================================================
-- BUNKERS register — W1 sweep-01 ingest
-- Source payload : research/candidates/graded.json (BES v0.2 adjudication, 48 entities / 200
--                  propositions, 196 X + 4 F) + research/candidates/resolved.json (lineage,
--                  merges, citogenesis) — see docs/SWEEP-01-REPORT.md and RESOLUTION-NOTES.md.
-- Target schema  : supabase/schema.sql (schema version 0.2.0, as deployed per docs/DEPLOY-REPORT.md).
-- Generated      : deterministically from the payload by db/ingest/gen-sweep-01.py; regenerate
--                  rather than hand-editing rows (UUIDs are stable, so re-applies are safe).
--
-- INVARIANTS OF THIS LOAD
--   * Nothing is published. Every entity, proposition, observation and document stays INTERNAL.
--     Nothing here can pass core.assert_publishable(): no observation has a VERIFIED receipt.
--   * Every observation lands in membership V0 (generated column): no citation in the sweep was
--     resolved to bytes. V and U are empty everywhere, exactly as graded.json states.
--   * Grades are computed by the schema's own functions in chunk %d/%d — never hand-written into
--     the rollup. Divergences between the schema's result and graded.json's proposed bands are
--     FINDINGS, enumerated in db/ingest/README.md, not forced.
--   * All rows carry deterministic UUIDs and idempotent inserts (ON CONFLICT DO NOTHING /
--     WHERE NOT EXISTS): any chunk may be re-run.
--
-- HOW TO APPLY: run each chunk as ONE SQL call, strictly in order 1..%d, chunk %d last.
-- Full instructions and caveats: db/ingest/README.md. Post-load assertions: sweep-01-verify.sql.
-- ============================================================================

""" % (N, N, N, N)
parts = [hdr]
for i, (title, body) in enumerate(chunks, 1):
    parts.append('-- CHUNK %d/%d -- %s\n\n%s\n' % (i, N, title, body))
main_sql = '\n'.join(parts)
open(os.path.join(OUT, 'sweep-01.sql'), 'w').write(main_sql)

# --------------------------------------------------------------- expected stats
n_entities = 48
n_props = len(loaded_pids)
n_obs = sum(1 for _ in obs_rows(half)) + sum(1 for _ in obs_rows(rest))
n_srcdocs = sum(len(c['sources']) for c in r['candidates'])
n_docs = n_srcdocs + len(XDOCS) + 48
n_receipts = (n_srcdocs - 1) + len(XDOCS)   # calibration self-reference has no receipt
n_edges_compiler = n_srcdocs
n_edges_special = len(EDGES)
n_aliases = len(arows)
n_rel = len(REL)
by_class = {}
for pid in loaded_pids:
    by_class[gprops[pid]['class']] = by_class.get(gprops[pid]['class'], 0) + 1
ERP_PER_CLASS = {'EXIST':4,'CONTROL':6,'PROGRAM':3,'HARDEN':9,'FUNCTION':11,'FEATURE':4,'EXTENT':3,
                 'STATUS':0,'ORIGIN':0,'IDENTITY':0,'TYPOLOGY':0}
n_erp = sum(ERP_PER_CLASS[gprops[pid]['class']] for pid in loaded_pids
            if pid not in F_PROPS_NO_ERP and pid != F_PROP_X0_ONLY) + len(X0_PROFILES_032)
n_parked = by_class['STATUS'] + by_class['IDENTITY'] + by_class['TYPOLOGY'] + 2  # + RES-029/032 FUNCTION
n_events = n_props - n_parked
n_f = by_class['ORIGIN'] + 2      # + RES-035-EXIST, RES-035-FUNCTION
n_x = n_props - n_f
n_cito = len(CITO_ROWS)

stats = dict(entities=n_entities, props=n_props, obs=n_obs, docs=n_docs, srcdocs=n_srcdocs,
             receipts=n_receipts, edges=n_edges_compiler+n_edges_special, aliases=n_aliases,
             relations=n_rel, erp=n_erp, parked=n_parked, events=n_events, F=n_f, X=n_x,
             cito=n_cito, by_class=by_class, chunks=N)
print(json.dumps(stats, indent=1))

# --------------------------------------------------------------- verify file
F4 = ['RES-029-FUNCTION','RES-032-FUNCTION','RES-035-EXIST','RES-035-FUNCTION']
pool_arr = 'array[%s]::uuid[]' % ', '.join(q(x) for x in SCHNEIDER_POOL)
sub_arr  = 'array[%s]::uuid[]' % ', '.join(q(x) for x in SUBTERRENE_SET)
sub6_arr = 'array[%s]::uuid[]' % ', '.join(q(x) for x in SUBTERRENE_SET + [LECTURE])

verify = """-- ============================================================================
-- BUNKERS register — W1 sweep-01 post-load verification
-- Run AFTER all %(chunks)d chunks of sweep-01.sql. Every assertion RAISES on failure; a clean run
-- ends with the summary SELECTs. Scoping: sweep rows only (entity slug ~ '^res-0dd-',
-- proposition.created_by = 'sweep-01-ingest'), so the pre-existing acceptance-fixture residue
-- documented in docs/DEPLOY-REPORT.md §7 is never counted. Safe to re-run; writes nothing.
-- ============================================================================

do $verify$
declare
  n bigint; n2 bigint; msg text;

  -- deterministic document ids (uuidv5 under the sweep-01 namespace)
  schneider_pool uuid[] := %(pool)s;
  subterrene_docs uuid[] := %(sub)s;
  subterrene_plus_lecture uuid[] := %(sub6)s;
begin
  ---------------------------------------------------------------- row counts
  select count(*) into n from core.entity where slug ~ '^res-0[0-9][0-9]-';
  if n <> %(entities)d then raise exception 'entities: expected %(entities)d, found %%', n; end if;

  select count(*) into n from core.proposition p join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and p.created_by = 'sweep-01-ingest';
  if n <> %(props)d then raise exception 'propositions: expected %(props)d (200 in graded.json minus 5 unrepresentable, see README), found %%', n; end if;

  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  if n <> %(obs)d then raise exception 'observations: expected %(obs)d, found %%', n; end if;

  -- documents: 257 sweep sources + 48 dossiers + 3 Schneider-family carriers
  select count(*) into n from core.source_document d
   where d.document_id in (select cited_document_id from core.document_citation
                            where asserted_by = 'sweep-01-ingest')
      or d.document_id in (select citing_document_id from core.document_citation
                            where asserted_by = 'sweep-01-ingest');
  if n <> %(docs)d then raise exception 'documents in the sweep citation graph: expected %(docs)d, found %%', n; end if;

  select count(*) into n from core.retrieval_receipt rr
   where rr.document_id in (select cited_document_id from core.document_citation
                             where asserted_by = 'sweep-01-ingest')
      or rr.document_id in (select citing_document_id from core.document_citation
                             where asserted_by = 'sweep-01-ingest');
  -- 256 source receipts (the RES-011 calibration self-reference deliberately has none) + 3 carriers
  if n <> %(receipts)d then raise exception 'retrieval receipts: expected %(receipts)d, found %%', n; end if;

  ---------------------------------------------------------------- resolve-or-die honesty
  select count(*) into n from core.retrieval_receipt rr
   where rr.document_id in (select cited_document_id from core.document_citation
                             where asserted_by = 'sweep-01-ingest')
     and rr.receipt_state <> 'UNRESOLVED';
  if n <> 0 then raise exception '%% receipt(s) not UNRESOLVED: the sweep resolved nothing to bytes', n; end if;

  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and o.membership <> 'V0';
  if n <> 0 then raise exception '%% observation(s) escaped V0; V and U must be EMPTY on every sweep proposition', n; end if;

  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and (o.signed_weight <> 0 or o.magnitude <> 0);
  if n <> 0 then raise exception '%% observation(s) carry nonzero magnitude/weight', n; end if;

  ---------------------------------------------------------------- nothing published, nothing canary
  select count(*) into n from core.entity
   where slug ~ '^res-0[0-9][0-9]-' and (publication_state <> 'INTERNAL' or published_at is not null);
  if n <> 0 then raise exception '%% entity rows are not INTERNAL', n; end if;
  select count(*) into n from core.entity where slug ~ '^res-0[0-9][0-9]-' and is_canary;
  if n <> 0 then raise exception '%% sweep entities marked canary', n; end if;
  select count(*) into n from core.proposition p join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and p.publication_state <> 'INTERNAL';
  if n <> 0 then raise exception '%% proposition rows are not INTERNAL', n; end if;
  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and o.publication_state <> 'INTERNAL';
  if n <> 0 then raise exception '%% observation rows are not INTERNAL', n; end if;
  select count(*) into n from core.grade_event ge join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and ge.is_published;
  if n <> 0 then raise exception '%% grade events are published', n; end if;
  select count(*) into n from core.entity e
   where e.slug ~ '^res-0[0-9][0-9]-' and core.entity_is_public(e.entity_id);
  if n <> 0 then raise exception 'core.entity_is_public() returns true for %% sweep entities', n; end if;
  select count(*) into n from core.publication_log pl join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-';
  if n <> 0 then raise exception '%% publication_log rows exist for sweep entities', n; end if;

  ---------------------------------------------------------------- grades came from the schema
  select count(*) into n from core.proposition p join core.entity e using (entity_id)
    left join core.proposition_rollup pr using (proposition_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and p.created_by = 'sweep-01-ingest' and pr.proposition_id is null;
  if n <> 0 then raise exception '%% propositions have no rollup (recompute did not run)', n; end if;

  -- the cached grade corresponds to the evidence currently on file (assert_publishable ground (c))
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest'
     and pr.evidence_state_hash is distinct from core.evidence_state_hash(pr.proposition_id);
  if n <> 0 then raise exception '%% rollups have a stale evidence_state_hash', n; end if;

  select count(*) into n from core.grade_event ge join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and not ge.is_blind_double_score;
  if n <> %(events)d then
    raise exception 'grade events: expected %(events)d (=%(props)d propositions minus %(parked)d parked by the clamp/grade_x_has_low_sci defect, README §Findings), found %%', n;
  end if;

  -- expected distribution from the schema's own computation (NOT graded.json's — see README):
  --   X %(X)d (151 SCI-floored + %(parked)d clamped-to-X under X parents, cached rollup only)
  --   F %(F)d  (14 ORIGIN with empty X>=1 ERP denominators + RES-035-EXIST + RES-035-FUNCTION)
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.grade = 'X';
  select count(*) into n2 from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.grade = 'F';
  if n <> %(X)d or n2 <> %(F)d then
    raise exception 'grade distribution: expected X=%(X)d / F=%(F)d, found X=%%, F=%%', n, n2;
  end if;
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.grade not in ('X','F');
  if n <> 0 then raise exception '%% propositions graded outside {X,F}: nothing verified can band higher', n; end if;

  -- the four graded-F propositions are present, and the schema found F on the evidence for each
  -- (grade_pre_clamp = F). RES-035-* also hold F post-clamp; RES-029/032-FUNCTION are clamped to X
  -- by their X parents — the divergence documented in README §Findings.
  select count(*) into n from core.proposition_rollup pr
   where pr.proposition_id in (%(f4)s) and pr.grade_pre_clamp = 'F';
  if n <> 4 then raise exception 'the four graded-F propositions: expected 4 with grade_pre_clamp=F, found %%', n; end if;
  select count(*) into n from core.proposition_rollup pr
   where pr.proposition_id in (%(f35)s) and pr.grade = 'F';
  if n <> 2 then raise exception 'RES-035 EXIST/FUNCTION: expected grade F, found %% of 2', n; end if;

  -- parked queue rows: after the FIRST run of chunk 12, exactly %(parked)d rows sit parked
  -- (attempts=3, last_error naming the clamp/grade_x_has_low_sci defect). If chunk 12 is RE-RUN,
  -- apply_grade converges on the cached clamped rollup (X = X, no event needed) and clears them,
  -- so 0 is also a valid steady state. Anything else — or an unparked row — is a failure.
  select count(*) into n from ingest.regrade_queue q join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  if n not in (%(parked)d, 0) then
    raise exception 'regrade queue: expected %(parked)d parked rows (or 0 after a chunk-12 re-run), found %%', n;
  end if;
  select count(*) into n from ingest.regrade_queue q join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and q.attempts < 3;
  if n <> 0 then raise exception '%% queue rows for sweep propositions are not parked (attempts<3)', n; end if;

  ---------------------------------------------------------------- lineage: the Schneider collapse
  -- Five separately-presented claim families, three beats searching blind, ONE 1995 terminus.
  select count(distinct component_root) into n from core.lineage_components(schneider_pool);
  if n <> 1 then
    raise exception 'Schneider pool: expected ONE lineage component across the five claim families, found %%', n;
  end if;

  -- RES-026 discipline: the four institutional subterrene roots stay separate from each other
  -- (LA-5354-MS + its UNT mirror collapse to one; LA-4547, the 1972 patent and the DRI/DOE U12t
  -- evaluation stand alone) and NONE of them shares a component with the Schneider lecture.
  select count(distinct component_root) into n from core.lineage_components(subterrene_docs);
  if n <> 4 then raise exception 'subterrene document programme: expected 4 independent roots, found %%', n; end if;
  select count(distinct component_root) into n from core.lineage_components(subterrene_plus_lecture);
  if n <> 5 then raise exception 'subterrene roots must NOT share a component with the Schneider lecture (expected 5, found %%)', n; end if;

  -- compiler-exposes edges never collapse: the dossier hub must not merge its sources
  select count(*) into n from core.document_citation
   where asserted_by = 'sweep-01-ingest' and edge_kind = 'compiler-exposes' and collapses_lineage;
  if n <> 0 then raise exception '%% compiler-exposes edges collapse lineages', n; end if;
  select count(*) into n from core.document_citation
   where asserted_by = 'sweep-01-ingest' and edge_kind = 'compiler-exposes';
  if n <> %(srcdocs)d then raise exception 'dossier compiler-exposes edges: expected %(srcdocs)d, found %%', n; end if;

  ---------------------------------------------------------------- supporting structures
  select count(*) into n from core.alternative_disposition ad join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and ad.is_selected;
  if n <> %(props)d then raise exception 'alternative dispositions: expected %(props)d, found %%', n; end if;
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.null_state = 'UNTESTED';
  if n <> 0 then raise exception '%% rollups derived null_state UNTESTED despite selected dispositions', n; end if;

  select count(*) into n from core.proposition_erp pe join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  if n <> %(erp)d then raise exception 'proposition_erp rows: expected %(erp)d, found %%', n; end if;
  select count(*) into n from core.proposition_erp pe join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pe.searched;
  if n <> 0 then raise exception '%% ERP rows claim a search happened; every canonical corpus was egress-blocked', n; end if;

  select count(*) into n from core.citogenesis_loop cl join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  select count(*) into n2 from core.citogenesis_loop cl join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and cl.state = 'confirmed';
  if n <> %(cito)d or n2 <> 0 then
    raise exception 'citogenesis: expected %(cito)d suspected / 0 confirmed, found %% / %%', n, n2;
  end if;
  -- and therefore CAP-3 never fired:
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.citogenesis;
  if n <> 0 then raise exception '%% rollups show confirmed citogenesis; the sweep only PROPOSED loops', n; end if;

  select count(*) into n from ingest.lead
   where identifier in ('AD1078617','310505952','CMPT-2016-0001','HGTWMDQ0010','LSBGVA05')
     and state = 'new' and promoted_document_id is null;
  if n <> 5 then raise exception 'identifier leads: expected 5 unpromoted, found %%', n; end if;

  select count(*) into n from core.entity_alias a join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-';
  if n <> %(aliases)d then raise exception 'aliases: expected %(aliases)d, found %%', n; end if;
  select count(*) into n from core.entity_relation rel
   where rel.asserted_by = 'sweep-01-ingest';
  if n <> %(relations)d then raise exception 'entity relations: expected %(relations)d, found %%', n; end if;
  select count(*) into n from core.geometry_assertion ga join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and ga.superseded_at is null;
  if n <> %(entities)d then raise exception 'geometry assertions: expected %(entities)d, found %%', n; end if;
  -- no coordinate exists anywhere in the sweep — nothing may ever have become a pin
  select count(*) into n from core.geometry_assertion ga join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and (ga.point_geom is not null or ga.region_geom is not null);
  if n <> 0 then raise exception '%% geometry assertions carry a shape; the sweep holds none', n; end if;

  raise notice 'sweep-01-verify: all assertions passed';
end
$verify$;

-- ---------------------------------------------------------------------------
-- Anonymous-visibility check: as anon, ZERO sweep rows are readable anywhere.
-- The BEGIN makes 'set local' valid when the executor runs statements in
-- autocommit; under an executor that already wraps the call in a transaction
-- it is a harmless no-op warning. Role is restored by RESET ROLE either way.
-- ---------------------------------------------------------------------------
begin;
set local role anon;
do $anon$
declare n bigint;
begin
  select count(*) into n from core.entity where slug ~ '^res-0[0-9][0-9]-';
  if n <> 0 then raise exception 'anon can see %% sweep entities', n; end if;
  select count(*) into n from core.proposition where created_by = 'sweep-01-ingest';
  if n <> 0 then raise exception 'anon can see %% sweep propositions', n; end if;
  select count(*) into n from core.observation where asserted_by like 'resolved.json W1%%';
  if n <> 0 then raise exception 'anon can see %% sweep observations', n; end if;
  select count(*) into n from core.document_citation where asserted_by = 'sweep-01-ingest';
  if n <> 0 then raise exception 'anon can see %% sweep citation edges', n; end if;
  raise notice 'sweep-01-verify: anon sees zero sweep rows';
end
$anon$;
commit;
reset role;

-- ---------------------------------------------------------------------------
-- Summary (informational)
-- ---------------------------------------------------------------------------
select 'entities' as what, count(*)::text as n from core.entity where slug ~ '^res-0[0-9][0-9]-'
union all
select 'propositions', count(*)::text from core.proposition where created_by = 'sweep-01-ingest'
union all
select 'observations (all V0)', count(*)::text
  from core.observation o join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest'
union all
select 'grade ' || pr.grade, count(*)::text
  from core.proposition_rollup pr join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest' group by pr.grade
union all
select 'grade events', count(*)::text
  from core.grade_event ge join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest'
union all
select 'parked (clamp/X-SCI defect)', count(*)::text
  from ingest.regrade_queue q join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest'
union all
select 'Schneider pool components (must be 1)', count(distinct component_root)::text
  from core.lineage_components(%(pool)s)
order by 1;
""" % dict(stats, pool=pool_arr, sub=sub_arr, sub6=sub6_arr,
           f4=', '.join(q(prop_id(x)) for x in F4),
           f35=', '.join(q(prop_id(x)) for x in ('RES-035-EXIST','RES-035-FUNCTION')))
open(os.path.join(OUT, 'sweep-01-verify.sql'), 'w').write(verify)

sizes = {name: os.path.getsize(os.path.join(OUT, name)) for name in ('sweep-01.sql','sweep-01-verify.sql')}
print(json.dumps(sizes, indent=1))
for i,(t,body) in enumerate(chunks,1):
    print('chunk', i, len(body), t[:60])
