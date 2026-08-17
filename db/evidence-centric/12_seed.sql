-- =====================================================================
-- SECTION 12 — SEED: the four curated tables, populated.
--
-- These are the versioned lookups that hold all the judgement. They are
-- asserted, not derived, and they are the new attack surface (tradeoff #3).
-- Every row is versioned so a bad version is identifiable and rollback-able,
-- and BES §12.5 re-derives them against resolved cases after the first 25
-- adjudications and every 50 A/R propositions thereafter.
-- =====================================================================

insert into registry.rubric_version (rubric_version, notes) values
  ('BES-0.2.0','Tiered Sufficiency with Signed Evidence. Supersedes WORKFLOW.md §1 (v0.1).');

insert into registry.table_version (table_name, version, issued_by, is_current) values
  ('tier','0.2.0','CURATOR',true),
  ('diagnosticity','0.2.0','CURATOR',true),
  ('erp','0.2.0','CURATOR',true),
  ('candidate_set','0.2.0','CURATOR',true),
  ('rubric','0.2.0','CURATOR',true);

insert into registry.country (country_code, name, register_scope) values
  ('US','United States','active'),
  ('GB','United Kingdom','planned'),
  ('DE','Germany','planned'),
  ('CH','Switzerland','planned'),
  ('RU','Russian Federation','planned');

-- ---------------------------------------------------------------------
-- The enumerated null set (BES §4.5). REFUTER selects the STRONGEST
-- SURVIVING alternative and states why the others are weaker.
-- ---------------------------------------------------------------------
insert into registry.null_hypothesis (null_code, label, description, is_fabrication_null, base_rate_note) values
 ('A01','no constructed object','There is no constructed object at this location',false,null),
 ('A02','commercial or industrial mine','Commercial or industrial mine, quarry, or cavern warehouse',false,
   'Tens of thousands of anthropogenic underground structures in CONUS; this is the dominant alternative for buried-rural candidates'),
 ('A03','transport tunnel','Highway, rail or transit tunnel',false,null),
 ('A04','water or sewer works','Water, sewer or flood-control works',false,null),
 ('A05','utility works','Utility vault, substation enclosure or pipeline works',false,null),
 ('A06','storage','Agricultural, cold or general storage',false,null),
 ('A07','data centre or exchange','Commercial data centre or telecom exchange, unhardened',false,null),
 ('A08','ordinary government building','Ordinary above-ground government building',false,null),
 ('A09','duplicate entity','Duplicate of an already-registered entity',false,null),
 ('A10','civil-defence designation only','Civil-defence shelter designation only',false,null),
 ('A11','fabricated or misattributed','Claim fabricated, misattributed or transposed',true,
   'MANDATORY co-null on any proposition whose positive support includes a T5 lineage; both scorings run and the LOWER grade publishes'),
 ('A12','other decommissioned typology','Decommissioned facility of a different, already-known typology',false,null);

-- ---------------------------------------------------------------------
-- Identifier grammars — VERIFIER's validators (fleet demand #1).
-- Patterns are anchored; "do not construct identifiers, enumerate them"
-- becomes a schema constraint rather than an instruction an agent may skip.
-- ---------------------------------------------------------------------
insert into registry.identifier_grammar
 (identifier_class, country_code, description, pattern, issuing_authority_host,
  resolver_url_template, faithful_mirror_hosts, issuer_metadata_fields, is_known_not_released) values
 ('CREST_ESDN','US','CIA CREST document number (ESDN)',
  '^CIA-RDP[0-9]{2}[A-Z]?-?[0-9]{5}[A-Z]?[0-9]{9}-[0-9]$','www.cia.gov',
  'https://www.cia.gov/readingroom/document/%s',
  '{archive.org}', '{title,release_date,document_number}', false),
 ('DTIC_AD','US','DTIC accession number','^AD[A-D]?[0-9]{6,7}$','apps.dtic.mil',
  'https://apps.dtic.mil/sti/citations/%s','{archive.org}','{title,report_date,performing_org}', false),
 ('DTIC_ADB','US','DTIC limited-distribution accession: KNOWN-TO-EXIST-NOT-RELEASED',
  '^ADB[0-9]{6,7}$','apps.dtic.mil','https://apps.dtic.mil/sti/citations/%s','{}','{title}', true),
 ('NARA_NAID','US','NARA National Archives Identifier','^[0-9]{1,9}$','catalog.archives.gov',
  'https://catalog.archives.gov/api/v2/records/search?naId=%s','{}','{title,recordGroup,levelOfDescription}', false),
 ('GAO_REPORT','US','GAO report number','^(GAO|NSIAD|B)-[0-9]{2,3}-[0-9]{1,5}[A-Z]*$','www.gao.gov',
  'https://www.gao.gov/products/%s','{}','{title,release_date}', false),
 ('FR_CITATION','US','Federal Register document number','^[0-9]{4}-[0-9]{5}$','www.federalregister.gov',
  'https://www.federalregister.gov/api/v1/documents/%s.json','{}','{title,publication_date,agencies}', false),
 ('GOVINFO_PKG','US','GovInfo package identifier','^[A-Z]{2,10}-[0-9]{4}(-[A-Za-z0-9\-]+)*$','api.govinfo.gov',
  'https://api.govinfo.gov/packages/%s/summary','{}','{title,dateIssued,collectionCode}', false),
 ('FCC_ASR','US','FCC Antenna Structure Registration number','^[0-9]{7}$','wireless2.fcc.gov',
  'https://wireless2.fcc.gov/UlsApp/AsrSearch/asrRegistration.jsp?regKey=%s','{}','{owner,latitude,longitude,height}', false),
 ('FCC_ULS','US','FCC ULS call sign','^[A-Z]{1,3}[0-9]{1,5}$','wireless2.fcc.gov',
  'https://wireless2.fcc.gov/UlsApp/UlsSearch/license.jsp?licKey=%s','{}','{licensee,radio_service,grant_date}', false),
 ('FPDS_PIID','US','FPDS procurement instrument identifier','^[A-Z0-9]{6,30}$','api.usaspending.gov',
  'https://api.usaspending.gov/api/v2/awards/%s/','{}','{recipient,awarding_agency,action_date}', false),
 ('FRUS_DOC','US','FRUS volume and document number','^frus[0-9]{4}-[0-9]{2}v[0-9]+d[0-9]+$','history.state.gov',
  'https://history.state.gov/historicaldocuments/%s','{github.com}','{volume,document_number,date}', false),
 ('USGS_QUAD','US','USGS HTMC quadrangle name plus year','^[A-Za-z .''\-]+_[A-Z]{2}_[0-9]{4}(_[0-9]+)?$',
  'prd-tnm.s3.amazonaws.com','https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/HistoricalTopo/PDF/%s.pdf',
  '{ngmdb.usgs.gov}','{map_name,state,date_on_map,scale}', false),
 ('COUNTY_PARCEL','US','County assessor parcel identifier (APN); grammar is per-county',
  '^[A-Za-z0-9\-\. ]{4,40}$','varies','%s','{}','{owner,legal_description,recorded_date}', false),
 ('MSHA_MINE_ID','US','MSHA mine identification number','^[0-9]{7}$','www.msha.gov',
  'https://www.msha.gov/data-and-reports/mine-data-retrieval-system?mineid=%s','{}','{operator,controller,mine_status}', false),
 ('AFHRA_IRIS','US','Air Force Historical Research Agency IRIS number','^[0-9]{5,7}$','airforcehistoryindex.org',
  'https://airforcehistoryindex.org/data/%s.html','{archive.org}','{title,unit,date_range}', false),
 ('DOI','US','Digital Object Identifier','^10\.[0-9]{4,9}/[-._;()/:A-Za-z0-9]+$','doi.org',
  'https://doi.org/%s','{}','{title,publisher,published}', false),
 ('IA_IDENTIFIER','US','Internet Archive item identifier','^[A-Za-z0-9._\-]{2,100}$','archive.org',
  'https://archive.org/metadata/%s','{}','{title,uploader,addeddate}', false);

-- ---------------------------------------------------------------------
-- EXPECTED-RECORD TABLE v0.2.0 (BES §6.3), seeded from the five W0 `gaps`
-- sections. Absence of a record is evidence ONLY where the presence of that
-- record would have been expected. For a classified facility, absent
-- records are the expected condition.
-- ---------------------------------------------------------------------
insert into registry.erp_profile
 (profile_key, country_code, description, x_level, authority_note, silence_override,
  destroying_event, counts_toward_sci, erp_version_id, reviewed_by)
select v.k, 'US', v.d, v.x::core.x_level, v.a, v.so::core.silence_reading, v.de,
       (v.x <> 'X0'), tv.table_version_id, 'CURATOR'
from (values
 ('milcon-jbook-appropriated','MILCON J-book line, appropriated agency, 1950-1990, unclassified','X3',null,null,null),
 ('milcon-classified-line','MILCON line marked Classified Project / Classified Location: existence of a line','X3',null,null,null),
 ('milcon-classified-scope','Same line, for scope and location','X0','the line establishes that money was appropriated somewhere and nothing else',null,null),
 ('milcon-nonappropriated','MILCON / appropriations, non-appropriated entity','X0','Federal Reserve, USPS, TVA, FDIC, Farm Credit',null,null),
 ('nip-mip-construction','NIP/MIP-funded construction, any era','X0','published only as topline aggregates; SAP construction invisible by design',null,null),
 ('frpp-executive','FRPP entry, executive-agency facility, post-1998','X2',null,null,null),
 ('frpp-nsec-withheld','FRPP entry, national-security-withheld asset class','X0','the best government-wide inventory is guaranteed to be missing exactly this class',null,null),
 ('dod-bsr','DoD Base Structure Report entry, acknowledged installation','X2',null,null,null),
 ('fpds-award','FPDS/USAspending award naming the site, post-2008','X1','descriptions sanitised and miscoded; place of performance is frequently the contracting office',null,null),
 ('nepa-eis','NEPA EIS filed with EPA, major federal action','X2',null,null,null),
 ('nepa-ea','NEPA EA for facility-scale construction','X1','no central index; most defence actions categorically excluded',null,null),
 ('nepa-classified','NEPA, classified action or categorical exclusion','X0',null,null,null),
 ('local-permit-federal','Local building permit, federal construction on federal land','X0','federal construction is exempt from local permitting',null,null),
 ('county-deed-any','County deed / assessor parcel record, any CONUS parcel, any era','X3','THE UNIVERSAL FLOOR',null,null),
 ('county-deed-fed-to-fed','County deed, federal-to-federal transfer or land withdrawal','X0','property moving between federal agencies typically generates no recorded deed',null,null),
 ('county-deed-predigital','County deed, pre-1975 in a county digitised only to the 1990s','X0',null,null,null),
 ('gsa-disposal','GSA disposal record, executive-agency real property','X2',null,null,null),
 ('fcc-commercial','FCC ASR/ULS registration, commercial emitter','X3',null,null,null),
 ('fcc-federal','FCC ASR/ULS registration, federal or covert emitter','X0','federal spectrum is NTIA/IRAC; GMF withheld — availability ANTI-correlates with the property being detected',null,null),
 ('nprc-personnel','NPRC personnel file, Army 1912-1960 or USAF 1947-1964','X0',null,'RECORD-DESTROYED','NPRC fire, 12 July 1973, 22 hours, ~16-18M Official Military Personnel Files, no duplicates, no microfilm, no index'),
 ('usgs-htmc','USGS HTMC quadrangle coverage, any CONUS coordinate','X3','186,061 sheets — a temporal-stack absence IS informative',null,null),
 ('usgs-suppression','USGS quad depiction where cartographic suppression is plausible','X1','the policy record of which sites were suppressed does not exist publicly',null,null),
 ('nrhp-sensitive','NRHP listing, restricted or sensitive feature','X0',null,null,null),
 ('3dep-remote-federal','3DEP lidar coverage, remote federal land','X1','acquisitions cost-shared with states; remote federal land systematically under-flown',null,null),
 ('chronam-post1963','Chronicling America coverage, local press after 1963','X0','free corpus is copyright-bounded at roughly 1963',null,null),
 ('govinfo-pre1994','Pre-1994 congressional material in GovInfo','X1','born-digital text starts ~103rd Congress; ARCHIVE-GAP',null,null),
 ('nara-textual','NARA textual holdings, RG 77 / 374 / 397','X1','~96% undigitised; the Catalog API can identify the boxes, it cannot deliver them; ARCHIVE-GAP',null,null),
 ('state-well-federal','State well-driller report, well on federal land','X0','wells on federal land are exempt from state permitting',null,null),
 ('epcra-tier2-federal','EPCRA Tier II, federal facility','X0',null,null,null),
 ('msha-post1970','MSHA record, underground mine post-1970','X3',null,null,null),
 ('msha-pre1970','MSHA record, underground mine pre-1970','X0',null,null,null),
 ('crest-still-classified','CREST/DTIC record, facility still classified or <25 years','X0','the 25-year rule makes this beat retrospective by construction',null,null),
 ('crest-declassified','CREST/DTIC record, facility declassified >25 years','X2',null,null,null),
 ('dtic-adb','DTIC ADB-prefix accession','KNOWN-NOT-RELEASED','a POSITIVE state, not an absence; auto-generates a FOIA worklist item',null,null),
 ('commercial-cover','Any documentary record, active facility under commercial cover','X0','this is what a good cover story is',null,null),
 ('spoil-volume','Spoil-volume signature in imagery, excavation >1e5 m3','X3',null,null,null),
 ('procurement-50m','Procurement trace for construction >$50M, appropriated agency','X3',null,null,null)
) as v(k,d,x,a,so,de)
cross join registry.table_version tv
where tv.table_name='erp' and tv.is_current;

-- ---------------------------------------------------------------------
-- DIAGNOSTICITY CATALOG v0.2.0 (BES §4.3).
-- The UNIVERSAL D0 list first: these are the signals shared by limestone
-- mines, highway tunnels, sewer works, cold-storage caverns, data centres
-- and large airports. Two hundred of them satisfy zero conditions above
-- band D. This list is the single thing that stops the register filling
-- with C-grade quarries (historian #5, IC #1).
-- ---------------------------------------------------------------------
insert into registry.diagnosticity_catalog
 (typology_profile, observation_key, observation_label, sign, magnitude,
  universal_d0, null_excluding, rationale, diag_version_id, reviewed_by)
select t.tp::core.typology, v.k, v.l, 'NEUTRAL'::core.evidence_sign, 0, true, false,
       'UNIVERSAL D0: the named null predicts this just as strongly. Contributes to no condition at any volume.',
       tv.table_version_id, 'CURATOR'
from (values
 ('adit-or-portal','Adit or portal existence'),
 ('spoil-pile','Spoil or muck pile'),
 ('ventilation-shaft','Ventilation shaft'),
 ('anomalous-road-grade','Anomalous road grade into terrain'),
 ('deep-well','Deep well'),
 ('rail-spur','Rail spur'),
 ('fenced-perimeter','Fenced perimeter'),
 ('large-excavation-volume','Large excavation volume'),
 ('generator','Generator'),
 ('fuel-tank','Fuel tank'),
 ('guard-shack','Guard shack'),
 ('cameras','Cameras'),
 ('controlled-access','Controlled access'),
 ('local-lore-something-under-there','"The locals say there is something under there"'),
 ('a-hill','A hill'),
 ('windowless-wall','A windowless wall'),
 ('basement','A basement')
) as v(k,l)
cross join (select unnest(enum_range(null::core.typology))::text as tp) t
cross join registry.table_version tv
where tv.table_name='diagnosticity' and tv.is_current;

-- BURIED-RURAL / MOUNTAIN: the discriminating rows.
insert into registry.diagnosticity_catalog
 (typology_profile, observation_key, observation_label, sign, magnitude,
  null_excluding, property_locus_default, rationale, diag_version_id, reviewed_by)
select 'military-hardened'::core.typology, v.k, v.l, v.s::core.evidence_sign, v.m,
       v.nx, v.pl::core.property_locus, coalesce(v.r,'catalog anchor, BES §4.3'), tv.table_version_id, 'CURATOR'
from (values
 ('substation-oversized','Dedicated substation whose capacity exceeds visible built footprint by >3x','SUPPORTS',1,false,'PLACE-PROPERTY','Mine and data-centre nulls can produce this, but less comfortably'),
 ('thermal-signature-unoccupied','Continuous thermal/lighting signature at an unoccupied-looking site','SUPPORTS',1,false,'PLACE-PROPERTY',null),
 ('redundant-utility-feeds','Multiple redundant utility feeds','SUPPORTS',1,false,'PLACE-PROPERTY',null),
 ('unjustified-helipad','Helipad with no medical or airfield justification','SUPPORTS',1,false,'PLACE-PROPERTY',null),
 ('continuous-restricted-airspace','Continuous restricted/prohibited airspace <3NM, surface to <5000ft AGL, non-flying using agency','SUPPORTS',2,true,'CLAIM-PROPERTY','Scheduled airspace is routine; CONTINUOUS airspace with a non-flying using agency is not producible by any mundane null'),
 ('htmc-editorial-blanking','HTMC editorial blanking: feature on edition N, absent on N+1, no demolition record','SUPPORTS',2,true,'CLAIM-PROPERTY',null),
 ('heat-rejection-disproportionate','Heat-rejection capacity grossly disproportionate to occupancy','SUPPORTS',2,false,'PLACE-PROPERTY',null),
 ('frpp-withheld-asset-gap','FRPP asset count materially below installation acreage','SUPPORTS',2,false,'CLAIM-PROPERTY','The withheld-asset gap, itself a citable absence'),
 ('msha-federal-controller','MSHA controller identity = federal entity or records-storage/data-centre operator','SUPPORTS',2,false,'CLAIM-PROPERTY',null),
 ('fuel-exceeds-runtime-norms','Fuel storage far exceeding generator run-time norms for the building class','SUPPORTS',2,false,'PLACE-PROPERTY',null),
 ('ntia-gmf-assignment','NTIA GMF assignment at the coordinate','SUPPORTS',2,true,'CLAIM-PROPERTY',null),
 ('longlines-corporate-lineage','AT&T Long Lines hardened-site lineage in corporate route/plant engineering records','SUPPORTS',3,true,'CLAIM-PROPERTY','Corporate engineering records, not enthusiast compilation'),
 ('afhra-unit-history','AFHRA unit history (IRIS number) describing the facility','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('catcode-in-real-property','Earth-covered-magazine or command-post CATCODE in a real-property record for the parcel','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('nepa-blast-specification','NEPA document specifying blast doors, blast valves, shielding or CBR filtration','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('psc-c1xx-ae-award','PSC C1xx architect-engineer design award for a hardened facility type at the coordinate with no subsequent public construction award','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('unit-cost-3x-ufc','Project unit cost >3x the UFC 3-701-01 pricing factor for its CATCODE','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('resolvable-named-witness','A resolvable named witness describing the facility','SUPPORTS',3,true,'CLAIM-PROPERTY','Resolvability gate AND attestation custody both required'),
 ('milstd-188-125-cited','MIL-STD-188-125-1/-2 (HEMP) cited in a design or procurement document naming the site','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('ufc-3-340-blast-design','UFC 3-340-01/-02 blast design for the named project','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('dd1391-hardening-scope','DD Form 1391 for the named installation with hardening scope','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('declassified-names-all-three','A declassified record naming facility + location + function','SUPPORTS',4,true,'CLAIM-PROPERTY','Documentary sufficiency: one conclusive primary record reaches A'),
 ('as-built-drawing','An as-built or engineering drawing','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('gsa-disposal-hardened','A GSA disposal record describing a hardened special facility','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('deed-recites-structure','A deed or court record reciting the structure','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('milcon-line-names-it','A MILCON line item naming it','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 -- the negative cells: what makes a lease list COUNT AGAINST rather than merely fail to count for
 ('published-tenant-lease-list','Published tenant lease list','UNDERCUTS',3,false,'CLAIM-PROPERTY','E0/A3 — improbable under the hardened-federal hypothesis'),
 ('public-ticketed-tours','Operator-run public ticketed tours','UNDERCUTS',3,false,'CLAIM-PROPERTY','E0/A3'),
 ('msha-regulated-mine-permit','MSHA regulated-mine permit','UNDERCUTS',1,false,'PLACE-PROPERTY','E1/A3'),
 ('public-tenant-directory','Public tenant directory','UNDERCUTS',2,false,'CLAIM-PROPERTY',null),
 ('continuous-documented-commercial-occupancy','Continuous documented commercial occupancy','UNDERCUTS',3,false,'CLAIM-PROPERTY',null)
) as v(k,l,s,m,nx,pl,r)
cross join registry.table_version tv
where tv.table_name='diagnosticity' and tv.is_current;

-- URBAN / IN-BUILDING. The axis-inapplicability defect dissolves: no axes,
-- a different catalog. 33 Thomas Street's geospatial signature is setback,
-- structural loading, vent-stack morphology and floor-plate depth, not spoil.
insert into registry.diagnosticity_catalog
 (typology_profile, observation_key, observation_label, sign, magnitude,
  universal_d0, null_excluding, property_locus_default, rationale, diag_version_id, reviewed_by)
select 'urban-in-building'::core.typology, v.k, v.l, v.s::core.evidence_sign, v.m, v.d0, v.nx,
       v.pl::core.property_locus, coalesce(v.r,'catalog anchor, BES §4.3'), tv.table_version_id, 'CURATOR'
from (values
 ('windowless-envelope','Windowless envelope','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('setback','Setback','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('bollards','Bollards','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('rooftop-generators','Rooftop generators','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('no-leasable-floorplate','No leasable floor plate, no tenant directory, no retail frontage on a commercially zoned parcel','SUPPORTS',1,false,false,'PLACE-PROPERTY',null),
 ('benchmarking-above-class','Municipal benchmarking consumption above class norm','SUPPORTS',1,false,false,'PLACE-PROPERTY',null),
 ('floor-loading-200psf','Structural floor loading >200 psf on multiple floors in building-department filings','SUPPORTS',2,false,true,'CLAIM-PROPERTY',null),
 ('vent-stack-array','Roof vent-stack array disproportionate to stated occupancy','SUPPORTS',2,false,false,'PLACE-PROPERTY',null),
 ('meetme-room-emergency-power','Carrier-hotel meet-me room with emergency power disproportionate to tenants','SUPPORTS',2,false,false,'PLACE-PROPERTY',null),
 ('architect-record-hardening','The architect''s own record describing a hardening programme','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null),
 ('corporate-literature-survivable','Corporate engineering literature naming the building as hardened or survivable','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null),
 ('dedicated-feeder-agreement','Dedicated-feeder utility interconnection agreement','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null),
 ('permit-valuation-anomaly','Permit valuation unit cost far above class norm','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null)
) as v(k,l,s,m,d0,nx,pl,r)
cross join registry.table_version tv
where tv.table_name='diagnosticity' and tv.is_current;

-- ---------------------------------------------------------------------
-- Base-rate readings (BES §6.5). PUBLISHED beside the grade, NEVER in the
-- arithmetic. This is the historian's second number, in a form the register
-- can actually stand behind.
-- ---------------------------------------------------------------------
insert into registry.base_rate (proposition_class, reference_class, function_set, reading, published_note) values
 ('EXIST','RC1','n/a','COMMON',null),('EXIST','RC2','n/a','UNCOMMON',null),
 ('EXIST','RC3','n/a','COMMON',null),('EXIST','RC4','n/a','COMMON',null),
 ('EXIST','RC5','n/a','UNCOMMON',null),('EXIST','RC6','n/a','RARE',null),
 ('HARDEN','RC1','n/a','UNCOMMON',null),('HARDEN','RC2','n/a','RARE',null),
 ('HARDEN','RC3','n/a','VERY-RARE',null),('HARDEN','RC4','n/a','UNCOMMON',null),
 ('HARDEN','RC5','n/a','VERY-RARE',null),('HARDEN','RC6','n/a','VERY-RARE',null),
 ('CONTROL','RC1','n/a','COMMON',null),('CONTROL','RC2','n/a','UNCOMMON',null),
 ('CONTROL','RC3','n/a','VERY-RARE',null),('CONTROL','RC4','n/a','RARE',null),
 ('CONTROL','RC5','n/a','VERY-RARE',null),('CONTROL','RC6','n/a','RARE',null),
 ('FUNCTION','RC1','sensitive','RARE',
   'On the order of a few hundred genuinely hardened federal facilities in CONUS against tens of thousands of anthropogenic underground structures.'),
 ('FUNCTION','RC2','sensitive','VERY-RARE',null),('FUNCTION','RC3','sensitive','VERY-RARE',null),
 ('FUNCTION','RC4','sensitive','VERY-RARE',null),('FUNCTION','RC5','sensitive','VERY-RARE',null),
 ('FUNCTION','RC6','sensitive','VERY-RARE',null),
 ('FUNCTION','RC1','mundane','UNCOMMON',null),('FUNCTION','RC2','mundane','UNCOMMON',null),
 ('FUNCTION','RC3','mundane','UNCOMMON',null),('FUNCTION','RC4','mundane','UNCOMMON',null),
 ('FUNCTION','RC5','mundane','RARE',null),('FUNCTION','RC6','mundane','RARE',null);

-- ---------------------------------------------------------------------
-- Corpus registry. Seeded with the tier-collision rulings that the W0
-- output forced (BES §3.1). The full 158 rows load from the five registry
-- JSON files with a straight column mapping.
-- ---------------------------------------------------------------------
insert into registry.corpus
 (slug, name, beat, url, host, country_code, legacy_p_tier, host_tier, content_tier,
  default_channel, default_causal, adversary_writable, transparent_compiler, tier_trap,
  machine_generated_blocklist, value, tier_version_id, reviewed_by, notes)
select v.slug, v.name, v.beat, v.url, v.host, 'US', v.p, v.ht::core.origin_tier, v.ct::core.origin_tier,
       v.ch::core.channel, v.cp::core.causal_provenance, v.aw, v.tc, v.tt, v.bl, v.val,
       tv.table_version_id, 'CURATOR', v.note
from (values
 ('cia-crest','CIA CREST / FOIA Electronic Reading Room','federal-declassification','https://www.cia.gov/readingroom/','www.cia.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('cia-crest-ia','CIA Reading Room mirror, Internet Archive','federal-declassification','https://archive.org/details/cia-readingroom','archive.org','P2','T2','T1','FAITHFUL-MIRROR','UNSOLICITED',false,false,false,false,'critical','IA is a CHANNEL, not a tier: mirrored CREST is T1 content via FAITHFUL-MIRROR'),
 ('dtic','DTIC public technical reports','federal-declassification','https://apps.dtic.mil/sti/','apps.dtic.mil','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('nara-catalog','NARA National Archives Catalog API v2','federal-declassification','https://catalog.archives.gov/api/v2/','catalog.archives.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('govinfo','GovInfo API and Bulk Data Repository','money-property-procurement','https://api.govinfo.gov/','api.govinfo.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('frus','Foreign Relations of the United States, TEI XML','federal-declassification','https://github.com/HistoryAtState/frus','github.com','P1','T2','T1','FAITHFUL-MIRROR','UNSOLICITED',false,false,false,false,'high',null),
 ('nsarchive','National Security Archive, GWU','federal-declassification','https://nsarchive.gwu.edu/','nsarchive.gwu.edu','P2','T2','T2','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'critical','Transparent compiler: exposes its primaries such that they can be independently pulled'),
 ('blackvault','The Black Vault','federal-declassification','https://www.theblackvault.com/documentarchive/','www.theblackvault.com','P3','T3','T1','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'moderate','RATIFIED COLLISION RULING: T3 host delivering T1 content. Record both.'),
 ('governmentattic','governmentattic.org','federal-declassification','https://www.governmentattic.org/','www.governmentattic.org','P3','T3','T1','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'high','RATIFIED COLLISION RULING: T3 host delivering T1 content.'),
 ('globalsecurity','GlobalSecurity.org','local-record-and-fringe','https://www.globalsecurity.org/wmd/facility/','www.globalsecurity.org','P3','T4','T4','AGGREGATOR','UNSOLICITED',false,false,true,false,'critical','RATIFIED: T4, registered as a TIER TRAP and a HOP, never a terminus'),
 ('usgs-htmc','USGS Historical Topographic Map Collection','geospatial','https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/HistoricalTopo/','prd-tnm.s3.amazonaws.com','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('msha','MSHA Mine Data Retrieval System','geospatial','https://www.msha.gov/','www.msha.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'high',null),
 ('fcc-asr','FCC Antenna Structure Registration bulk','infrastructure','https://data.fcc.gov/download/pub/uls/complete/r_tower.zip','data.fcc.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('long-lines-net','long-lines.net AT&T Long Lines Places and Routes','infrastructure','https://www.long-lines.net/places-routes/','www.long-lines.net','P4','T4','T4','AGGREGATOR','UNSOLICITED',false,false,false,false,'critical',null),
 ('usaspending','USAspending.gov REST API v2','money-property-procurement','https://api.usaspending.gov/api/v2/','api.usaspending.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('frpp','GSA Federal Real Property Profile Public Data Set','money-property-procurement','https://www.gsa.gov/','www.gsa.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('epa-eis','EPA Environmental Impact Statement Database','money-property-procurement','https://cdxapps.epa.gov/cdx-enepa-II/public/action/eis/search','cdxapps.epa.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('chronam','Chronicling America','local-record-and-fringe','https://www.loc.gov/collections/chronicling-america/','www.loc.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('afhra-index','Air Force History Index / AFHRA','local-record-and-fringe','https://airforcehistoryindex.org/','airforcehistoryindex.org','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical','An INDEX, not a corpus: indexes existence, not content'),
 ('subbrit','Subterranea Britannica','local-record-and-fringe','https://www.subbrit.org.uk/','www.subbrit.org.uk','P3','T3','T3','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'high','The methodological model'),
 ('ed-thelen','Ed Thelen Nike Missile Site','local-record-and-fringe','https://ed-thelen.org/','ed-thelen.org','P3','T3','T3','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'critical',null),
 ('progressive-1976','Richard Pollock, The Mysterious Mountain, The Progressive, March 1976','local-record-and-fringe','https://www.progressive.org/','www.progressive.org','P3','T3','T3','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical','T3 publication resting on unnamed off-the-record officials: the canonical citogenesis case'),
 ('wapo-gup-1992','Ted Gup, The Ultimate Congressional Hideaway, Washington Post, 31 May 1992','local-record-and-fringe','https://www.washingtonpost.com/','www.washingtonpost.com','P2','T2','T2','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical','The Greenbrier disclosure. Grade movement here is NEW-DISCLOSURE, not NEW-VERIFICATION.'),
 ('afu-newsletters','Archives for the Unexplained, digitised newsletter runs','local-record-and-fringe','https://archive.org/details/ufonewsletters','archive.org','P3','T2','T5','CURATED-ARCHIVE','UNSOLICITED',false,false,false,false,'high','A faithfully scanned T5 mimeographed newsletter in a T2 archive is a T5 DOCUMENT WITH HIGH RETRIEVAL INTEGRITY. Record both — this is what makes AFU usable for ORIGIN grading.'),
 ('wikimapia','Wikimapia crowd map','geospatial','http://wikimapia.org/api/','wikimapia.org','P4','T4','T4','ADVERSARY-WRITABLE','CROWD-EDITED',true,false,false,false,'moderate','Documented ingestion path into an adversary-writable free-text field. Leads only, never evidence.'),
 ('openstreetmap','OpenStreetMap','geospatial','https://openinframap.org/','openstreetmap.org','P4','T4','T4','ADVERSARY-WRITABLE','CROWD-EDITED',true,false,false,false,'high',null),
 ('abovetopsecret','AboveTopSecret forum','local-record-and-fringe','https://www.abovetopsecret.com/','www.abovetopsecret.com','P5','T5','T5','ADVERSARY-WRITABLE','SELF-PUBLISHED',true,false,false,false,'moderate',null),
 ('bibliotecapleyades','bibliotecapleyades.net aggregator','local-record-and-fringe','https://www.bibliotecapleyades.net/','www.bibliotecapleyades.net','P5','T5','T5','AGGREGATOR','SELF-PUBLISHED',false,false,false,false,'high','Pure aggregator node: opaque compiler, one terminus'),
 ('grokipedia','Grokipedia','local-record-and-fringe','https://grokipedia.com/','grokipedia.com','P5','T5','T5','AGGREGATOR','SELF-PUBLISHED',false,false,false,true,'low','Versioned public blocklist: T5 + POST-2022-UNATTRIBUTED by construction'),
 ('uapedia','uapedia.ai','local-record-and-fringe','https://uapedia.ai/','uapedia.ai','P5','T5','T5','AGGREGATOR','SELF-PUBLISHED',false,false,false,true,'low','Machine-generated corpus blocklist')
) as v(slug,name,beat,url,host,p,ht,ct,ch,cp,aw,tc,tt,bl,val,note)
cross join registry.table_version tv
where tv.table_name='tier' and tv.is_current;

-- Canonical search sets: which ERP profiles the SCI denominator counts,
-- per proposition class (BES §7.1).
insert into registry.canonical_search_set (proposition_class, country_code, erp_profile_id, required)
select c.cls::core.proposition_class, 'US', ep.erp_profile_id, true
from registry.erp_profile ep
join (values
  ('EXIST','usgs-htmc'),('EXIST','county-deed-any'),('EXIST','msha-post1970'),
  ('EXIST','3dep-remote-federal'),('EXIST','spoil-volume'),('EXIST','frpp-executive'),
  ('LOCATE','usgs-htmc'),('LOCATE','county-deed-any'),('LOCATE','usgs-suppression'),
  ('EXTENT','usgs-htmc'),('EXTENT','spoil-volume'),('EXTENT','nepa-eis'),
  ('CONTROL','frpp-executive'),('CONTROL','dod-bsr'),('CONTROL','gsa-disposal'),
  ('CONTROL','county-deed-any'),('CONTROL','fpds-award'),
  ('HARDEN','crest-declassified'),('HARDEN','nepa-eis'),('HARDEN','nepa-ea'),
  ('HARDEN','milcon-jbook-appropriated'),('HARDEN','procurement-50m'),
  ('FUNCTION','crest-declassified'),('FUNCTION','nepa-eis'),('FUNCTION','govinfo-pre1994'),
  ('FUNCTION','nara-textual'),('FUNCTION','milcon-jbook-appropriated'),
  ('FEATURE','nepa-eis'),('FEATURE','crest-declassified'),
  ('PROGRAM','govinfo-pre1994'),('PROGRAM','milcon-jbook-appropriated'),('PROGRAM','nara-textual'),
  ('ORIGIN','chronam-post1963'),('ORIGIN','usgs-htmc')
) as c(cls, key) on c.key = ep.profile_key;

insert into registry.scorer_model (scorer_model_id, model_family, vendor, role) values
 ('scorer-family-a-v1','family-a','vendor-a','ASSESSOR'),
 ('verifier-code-v1','deterministic-code','n/a','VERIFIER'),
 ('scorer-family-b-v1','family-b','vendor-b','REVIEWER');
