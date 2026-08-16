-- =====================================================================
-- BUNKERS REGISTER — PART 8: seed data for the four curated tables
-- Every row here is a REVIEWED WRITE, versioned, and pinned on grade rows.
-- =====================================================================

insert into table_version (table_name, version, derivation_note) values
 ('rubric','BES-0.2.0','Tiered Sufficiency with Signed Evidence, ratified W0'),
 ('tier','TIER-0.2.0','One ladder replacing the three incompatible W0 P-tier ladders'),
 ('diagnosticity','DIAG-0.2.0','Anchors from both critiques; NOT yet back-fitted to outcomes'),
 ('erp','ERP-0.2.0','Seeded from the five W0 registry gaps sections'),
 ('candidate_set','CS-0.2.0','Seeded from PEF / Federal Relocation Arc'),
 ('rubric','BR-0.2.0','Base-rate readings, §6.5 — published, never arithmetic');

insert into tier_definition (tier, definition, max_band_supported) values
 ('T1','Originating record office or its official machine interface; a record created by a party with direct authority or direct physical access, for its own purposes','A'),
 ('T2','Faithful mirror of a T1 record, or professional curation over primaries that exposes them','A'),
 ('T3','Independent rigorous secondary: FOIA-requester archives, peer-reviewed work, investigative journalism with named sourcing, disciplined enthusiast survey with cited sources','B'),
 ('T4','Loose secondary: aggregator synthesis, unsourced enthusiast site, unsourced press, wiki, self-published DOI, crowd-map annotation','C'),
 ('T5','Uncorroborated claim: forum post, video, anonymous testimony, machine-generated text, an LLM''s own interpretation of a primary artifact','D'),
 ('PENDING','Uncatalogued source awaiting reviewed write. Treated as T4 for all conditions (§3.2)','C');

-- §4.5 the enumerated null set. REFUTER selects the STRONGEST SURVIVING one.
insert into null_hypothesis (code, label, is_fabrication_null) values
 ('A01','No constructed object here', false),
 ('A02','Commercial or industrial mine, quarry, or cavern warehouse', false),
 ('A03','Highway, rail or transit tunnel', false),
 ('A04','Water, sewer or flood-control works', false),
 ('A05','Utility vault, substation enclosure or pipeline works', false),
 ('A06','Agricultural, cold or general storage', false),
 ('A07','Commercial data centre or telecom exchange (unhardened)', false),
 ('A08','Ordinary above-ground government building', false),
 ('A09','Duplicate of an already-registered entity', false),
 ('A10','Civil-defence shelter designation only', false),
 ('A11','Claim fabricated, misattributed or transposed', true),
 ('A12','Decommissioned facility of a different, already-known typology', false);

insert into typology_profile (code,label,default_reference_class,refuter_prior) values
 ('unknown-anomaly','Unknown anomaly (default for every new candidate)','RC6','default_refute'),
 ('buried-rural','Buried / rural / mountain hardened facility','RC2','default_open'),
 ('urban-in-building','Urban or in-building hardened facility','RC5','default_refute'),
 ('silo','Missile silo / launch facility','RC1','default_refute'),
 ('relay-comms','Communications relay / hardened carrier station','RC4','default_open'),
 ('archive-storage','Records storage and archive','RC3','default_refute'),
 ('civil-defense-shelter','Civil-defence shelter','RC5','default_refute'),
 ('mine-conversion','Converted mine','RC3','default_refute'),
 ('cog-coop','Continuity of government / COOP','RC1','default_open');

-- §4.4 the E/A fallback matrix, materialised. Ceiling D3 is arithmetic here,
-- not a bolted-on cap: no cell emits 4.
insert into ea_matrix (expected_under_h, expected_under_alt, diagnosticity, sign) values
 (3,3,0,'NEUTRAL'), (3,2,0,'NEUTRAL'), (3,1,1,'SUPPORTS'), (3,0,3,'SUPPORTS'),
 (2,3,0,'NEUTRAL'), (2,2,0,'NEUTRAL'), (2,1,1,'SUPPORTS'), (2,0,3,'SUPPORTS'),
 (1,3,1,'UNDERCUTS'),(1,2,1,'UNDERCUTS'),(1,1,0,'NEUTRAL'), (1,0,2,'SUPPORTS'),
 (0,3,3,'UNDERCUTS'),(0,2,3,'UNDERCUTS'),(0,1,2,'UNDERCUTS'),(0,0,0,'NEUTRAL');

-- §4.3 UNIVERSAL D0 — permanently, for every typology. Two hundred of these
-- satisfy zero conditions above band D. This list is the anti-quarry firewall.
insert into diagnosticity_catalog
  (version, typology_code, observation_key, observation_label, diagnosticity, anchor_note)
select 'DIAG-0.2.0', null, k, l, 0,
       'UNIVERSAL D0: shared by limestone mines, highway tunnels, sewer works, '
       'cold-storage caverns, data centres and large airports'
from (values
 ('adit_portal','Adit or portal existence'),
 ('spoil_pile','Spoil or muck pile'),
 ('ventilation_shaft','Ventilation shaft'),
 ('anomalous_road_grade','Anomalous road grade into terrain'),
 ('deep_well','Deep well'),
 ('rail_spur','Rail spur'),
 ('fenced_perimeter','Fenced perimeter'),
 ('large_excavation_volume','Large excavation volume'),
 ('generator','Generator'),
 ('fuel_tank','Fuel tank'),
 ('guard_shack','Guard shack'),
 ('cameras','Cameras'),
 ('controlled_access','Controlled access'),
 ('local_lore','"The locals say there is something under there"'),
 ('a_hill','A hill'),
 ('windowless_wall','A windowless wall'),
 ('basement','A basement')
) as t(k,l);

insert into diagnosticity_catalog
 (version,typology_code,observation_key,observation_label,diagnosticity,null_excluding_for,gate_eligible,anchor_note)
values
 -- BURIED-RURAL / MOUNTAIN
 ('DIAG-0.2.0','buried-rural','substation_oversized','Dedicated substation >3x visible built footprint',1,'{}',false,'E3/A2'),
 ('DIAG-0.2.0','buried-rural','thermal_signature','Continuous thermal/lighting signature at an unoccupied-looking site',1,'{}',false,null),
 ('DIAG-0.2.0','buried-rural','redundant_utility_feeds','Multiple redundant utility feeds',1,'{}',false,null),
 ('DIAG-0.2.0','buried-rural','unjustified_helipad','Helipad with no medical or airfield justification',1,'{}',false,null),
 ('DIAG-0.2.0','buried-rural','continuous_restricted_airspace','Continuous restricted airspace <3NM, surface to <5000ft AGL, non-flying using agency',2,'{A01,A02,A03,A04,A06}',false,'E3/A0 on the matrix; catalogued at D2 pending back-fit'),
 ('DIAG-0.2.0','buried-rural','htmc_editorial_blanking','HTMC editorial blanking: feature on edition N, absent on N+1, no demolition record',2,'{A01}',false,null),
 ('DIAG-0.2.0','buried-rural','heat_rejection_disproportionate','Heat-rejection capacity grossly disproportionate to occupancy',2,'{A06,A08}',false,null),
 ('DIAG-0.2.0','buried-rural','frpp_withheld_asset_gap','FRPP asset count materially below installation acreage (the withheld-asset gap)',2,'{A08}',false,'A citable ABSENCE'),
 ('DIAG-0.2.0','buried-rural','msha_federal_controller','MSHA controller identity = federal entity or records-storage/data-centre operator',2,'{A02}',false,null),
 ('DIAG-0.2.0','buried-rural','fuel_storage_excess','Fuel storage far exceeding generator run-time norms for the building class',2,'{A06,A08}',false,null),
 ('DIAG-0.2.0','buried-rural','ntia_gmf_assignment','NTIA GMF assignment at the coordinate',2,'{A01,A02,A06}',false,null),
 ('DIAG-0.2.0','buried-rural','long_lines_lineage','AT&T Long Lines hardened-site lineage in corporate route/plant engineering records',3,'{A01,A02,A03,A04,A06,A07}',false,null),
 ('DIAG-0.2.0','buried-rural','afhra_unit_history','AFHRA unit history (IRIS number) describing the facility',3,'{A01,A02,A03,A04,A06}',false,null),
 ('DIAG-0.2.0','buried-rural','catcode_ecm_cp','Earth-covered-magazine or command-post CATCODE in a real-property record for the parcel',3,'{A01,A02,A06,A08}',false,null),
 ('DIAG-0.2.0','buried-rural','nepa_blast_spec','NEPA document specifying blast doors, blast valves, shielding or CBR filtration',3,'{A01,A02,A03,A04,A06,A07,A08}',true,null),
 ('DIAG-0.2.0','buried-rural','psc_c1xx_ae_award','PSC C1xx A-E design award for a hardened facility type at the coordinate, no subsequent public construction award',3,'{A01,A08}',false,null),
 ('DIAG-0.2.0','buried-rural','unit_cost_3x_ufc','Project unit cost >3x the UFC 3-701-01 pricing factor for its CATCODE',3,'{A08}',false,null),
 ('DIAG-0.2.0','buried-rural','resolvable_named_witness','A resolvable named witness (§5.4) describing the facility',3,'{A01}',false,null),
 ('DIAG-0.2.0','buried-rural','milstd_188_125','MIL-STD-188-125-1/-2 (HEMP) cited in a design or procurement document naming the site',4,'{A01,A02,A03,A04,A05,A06,A07,A08,A10,A12}',true,null),
 ('DIAG-0.2.0','buried-rural','ufc_3_340_blast','UFC 3-340-01/-02 blast design for the named project',4,'{A01,A02,A03,A04,A05,A06,A07,A08,A10,A12}',true,null),
 ('DIAG-0.2.0','buried-rural','dd1391_hardening','DD Form 1391 for the named installation with hardening scope',4,'{A01,A02,A06,A08}',true,null),
 ('DIAG-0.2.0','buried-rural','declassified_named_record','Declassified record naming facility + location + function',4,'{A01,A02,A03,A04,A05,A06,A07,A08,A09,A10,A11,A12}',true,null),
 ('DIAG-0.2.0','buried-rural','as_built_drawing','As-built or engineering drawing',4,'{A01,A11}',true,null),
 ('DIAG-0.2.0','buried-rural','gsa_disposal_hardened','GSA disposal record describing a hardened special facility',4,'{A01,A02,A06,A08}',true,null),
 ('DIAG-0.2.0','buried-rural','deed_recites_structure','Deed or court record reciting the structure',4,'{A01,A11}',true,null),
 ('DIAG-0.2.0','buried-rural','milcon_line_item','MILCON line item naming it',4,'{A01,A02,A08}',true,null),
 -- URBAN / IN-BUILDING (the axis-inapplicability defect dissolves: no axes,
 -- a different catalog — historian fatal #4, 33 Thomas Street)
 ('DIAG-0.2.0','urban-in-building','windowless_envelope','Windowless envelope',0,'{}',false,null),
 ('DIAG-0.2.0','urban-in-building','setback','Setback',0,'{}',false,null),
 ('DIAG-0.2.0','urban-in-building','bollards','Bollards',0,'{}',false,null),
 ('DIAG-0.2.0','urban-in-building','rooftop_generators','Rooftop generators',0,'{}',false,null),
 ('DIAG-0.2.0','urban-in-building','no_leasable_plate','No leasable floor plate, no tenant directory, no retail frontage on commercially zoned parcel',1,'{}',false,null),
 ('DIAG-0.2.0','urban-in-building','benchmarking_above_class','Municipal benchmarking consumption above class norm',1,'{}',false,null),
 ('DIAG-0.2.0','urban-in-building','floor_loading_200psf','Structural floor loading >200 psf on multiple floors in building-department filings',2,'{A08}',false,null),
 ('DIAG-0.2.0','urban-in-building','vent_stack_array','Roof vent-stack array disproportionate to stated occupancy',2,'{A08}',false,null),
 ('DIAG-0.2.0','urban-in-building','meet_me_room_power','Carrier-hotel meet-me room with emergency power disproportionate to tenants',2,'{A07}',false,null),
 ('DIAG-0.2.0','urban-in-building','architect_hardening_record','The architect''s own record describing a hardening programme',3,'{A08}',false,null),
 ('DIAG-0.2.0','urban-in-building','corporate_survivability_lit','Corporate engineering literature naming the building as hardened or survivable',3,'{A07,A08}',false,null),
 ('DIAG-0.2.0','urban-in-building','dedicated_feeder_agreement','Dedicated-feeder utility interconnection agreement',3,'{A08}',false,null),
 ('DIAG-0.2.0','urban-in-building','permit_valuation_outlier','Permit valuation unit cost far above class norm',3,'{A08}',false,null),
 -- Published anchors that COUNT AGAINST (§4.4 negative cells)
 ('DIAG-0.2.0',null,'published_tenant_lease_list','Published tenant lease list',3,'{}',false,'E0/A3 -> UNDERCUTS at D3'),
 ('DIAG-0.2.0',null,'public_ticketed_tours','Operator-run public ticketed tours',3,'{}',false,'E0/A3 -> UNDERCUTS at D3'),
 ('DIAG-0.2.0',null,'msha_regulated_permit','MSHA regulated-mine permit',1,'{}',false,'E1/A3 -> UNDERCUTS at D1');

update diagnosticity_catalog set sign='UNDERCUTS'
 where version='DIAG-0.2.0'
   and observation_key in ('published_tenant_lease_list','public_ticketed_tours','msha_regulated_permit');

-- §6.3 EXPECTED-RECORD TABLE v0.2.0. The highest-value artifact W0 produced:
-- ~30 rows seeded directly from the five registries' `gaps` sections.
insert into erp_profile (version, code, label, country, x, x0_reason, destroying_event, note) values
 ('ERP-0.2.0','MILCON_JBOOK','MILCON J-book line, appropriated agency, 1950-1990, unclassified','US',3,null,null,null),
 ('ERP-0.2.0','MILCON_CLASSIFIED_LINE','MILCON line marked "Classified Project"/"Classified Location" (existence of a line)','US',3,null,null,null),
 ('ERP-0.2.0','MILCON_CLASSIFIED_SCOPE','Same, for scope and location','US',0,'WITHHELD',null,null),
 ('ERP-0.2.0','MILCON_NON_APPROPRIATED','MILCON/appropriations, non-appropriated entity (Federal Reserve, USPS, TVA, FDIC, Farm Credit)','US',0,'STRUCTURALLY_ABSENT',null,'Mount Pony, Culpeper is the calibration case'),
 ('ERP-0.2.0','NIP_MIP_CONSTRUCTION','NIP/MIP-funded construction, any era','US',0,'WITHHELD',null,null),
 ('ERP-0.2.0','FRPP_EXEC','FRPP entry, executive-agency facility, post-1998','US',2,null,null,null),
 ('ERP-0.2.0','FRPP_NATSEC_WITHHELD','FRPP entry, national-security-withheld asset class','US',0,'WITHHELD',null,null),
 ('ERP-0.2.0','DOD_BSR','DoD Base Structure Report entry, acknowledged installation','US',2,null,null,null),
 ('ERP-0.2.0','FPDS_AWARD','FPDS/USAspending award naming the site, post-2008','US',1,null,null,'Descriptions sanitised and miscoded; place of performance is frequently the contracting office'),
 ('ERP-0.2.0','NEPA_EIS','NEPA EIS filed with EPA, major federal action','US',2,null,null,null),
 ('ERP-0.2.0','NEPA_EA','NEPA EA for facility-scale construction','US',1,null,null,'No central index; most defence actions categorically excluded'),
 ('ERP-0.2.0','NEPA_CLASSIFIED','NEPA, classified action or categorical exclusion','US',0,'STRUCTURALLY_ABSENT',null,null),
 ('ERP-0.2.0','LOCAL_PERMIT_FEDERAL','Local building permit, federal construction on federal land','US',0,'NEVER_EXISTED',null,'Federal construction is exempt from local permitting'),
 ('ERP-0.2.0','COUNTY_DEED','County deed / assessor parcel record, any CONUS parcel, any era','US',3,null,null,'THE UNIVERSAL FLOOR'),
 ('ERP-0.2.0','COUNTY_DEED_FED_FED','County deed, federal-to-federal transfer or land withdrawal','US',0,'NEVER_EXISTED',null,'Federal-to-federal transfers generate no deed'),
 ('ERP-0.2.0','COUNTY_DEED_PRE1975','County deed, pre-1975 in a county digitised only to the 1990s','US',0,'STRUCTURALLY_ABSENT',null,null),
 ('ERP-0.2.0','GSA_DISPOSAL','GSA disposal record, executive-agency real property','US',2,null,null,null),
 ('ERP-0.2.0','FCC_COMMERCIAL','FCC ASR/ULS registration, commercial emitter','US',3,null,null,null),
 ('ERP-0.2.0','FCC_FEDERAL','FCC ASR/ULS registration, federal or covert emitter','US',0,'STRUCTURALLY_ABSENT',null,'Federal spectrum is NTIA/IRAC; GMF withheld. Availability ANTI-correlates with the property being detected'),
 ('ERP-0.2.0','NPRC_PERSONNEL','NPRC personnel file, Army 1912-1960 or USAF 1947-1964','US',0,'RECORD_DESTROYED','NPRC fire, 12 July 1973; ~16-18M files; no duplicates, no index',null),
 ('ERP-0.2.0','USGS_HTMC','USGS HTMC quadrangle coverage, any CONUS coordinate','US',3,null,null,'186,061 sheets, so a temporal-stack absence IS informative'),
 ('ERP-0.2.0','USGS_SUPPRESSED','USGS quad depiction where cartographic suppression is plausible','US',1,null,null,null),
 ('ERP-0.2.0','NRHP_SENSITIVE','NRHP listing, restricted or sensitive feature','US',0,'WITHHELD',null,null),
 ('ERP-0.2.0','LIDAR_3DEP','3DEP lidar coverage, remote federal land','US',1,null,null,'Acquisitions cost-shared with states; remote federal land systematically under-flown'),
 ('ERP-0.2.0','CHRONAM_POST1963','Chronicling America coverage, local press after 1963','US',0,'STRUCTURALLY_ABSENT',null,'Free corpus is copyright-bounded'),
 ('ERP-0.2.0','GOVINFO_PRE1994','Pre-1994 congressional material in GovInfo','US',1,null,null,'ARCHIVE-GAP: born-digital text starts ~103rd Congress'),
 ('ERP-0.2.0','NARA_RG77_374_397','NARA textual holdings, RG 77 / 374 / 397','US',1,null,null,'ARCHIVE-GAP: ~96% undigitised'),
 ('ERP-0.2.0','STATE_WELL_FEDERAL','State well-driller report, well on federal land','US',0,'NEVER_EXISTED',null,'Federal-land wells exempt from state permitting'),
 ('ERP-0.2.0','EPCRA_TIER2_FEDERAL','EPCRA Tier II, federal facility','US',0,'STRUCTURALLY_ABSENT',null,null),
 ('ERP-0.2.0','MSHA_POST1970','MSHA record, underground mine post-1970','US',3,null,null,null),
 ('ERP-0.2.0','MSHA_PRE1970','MSHA record, underground mine pre-1970','US',0,'NEVER_EXISTED',null,null),
 ('ERP-0.2.0','CREST_DTIC_CLASSIFIED','CREST/DTIC record, facility still classified or <25 years','US',0,'WITHHELD',null,null),
 ('ERP-0.2.0','CREST_DTIC_DECLASS','CREST/DTIC record, facility declassified >25 years','US',2,null,null,null),
 ('ERP-0.2.0','ANY_ACTIVE_COMMERCIAL_COVER','Any documentary record, active facility under commercial cover','US',0,'WITHHELD',null,'The Greenbrier-1991 case'),
 ('ERP-0.2.0','SPOIL_VOLUME_IMAGERY','Spoil-volume signature in imagery, excavation >1e5 m3','US',3,null,null,null),
 ('ERP-0.2.0','PROCUREMENT_50M','Procurement trace for construction >$50M, appropriated agency','US',3,null,null,null);

-- DTIC ADB: a POSITIVE state, not an absence. Auto-generates a FOIA worklist.
insert into erp_profile (version, code, label, country, x, known_to_exist_not_released, note)
values ('ERP-0.2.0','DTIC_ADB','DTIC ADB-prefix accession','US',0,true,
        'KNOWN-TO-EXIST-NOT-RELEASED. Metadata public, document is not.');

-- §6.5 base-rate readings. Published beside the grade; NEVER arithmetic.
insert into base_rate_table (version, reference_class, class, function_set, reading) values
 ('BR-0.2.0','RC1','EXIST','na','COMMON'),   ('BR-0.2.0','RC2','EXIST','na','UNCOMMON'),
 ('BR-0.2.0','RC3','EXIST','na','COMMON'),   ('BR-0.2.0','RC4','EXIST','na','COMMON'),
 ('BR-0.2.0','RC5','EXIST','na','UNCOMMON'), ('BR-0.2.0','RC6','EXIST','na','RARE'),
 ('BR-0.2.0','RC1','HARDEN','na','UNCOMMON'),('BR-0.2.0','RC2','HARDEN','na','RARE'),
 ('BR-0.2.0','RC3','HARDEN','na','VERY_RARE'),('BR-0.2.0','RC4','HARDEN','na','UNCOMMON'),
 ('BR-0.2.0','RC5','HARDEN','na','VERY_RARE'),('BR-0.2.0','RC6','HARDEN','na','VERY_RARE'),
 ('BR-0.2.0','RC1','CONTROL','na','COMMON'), ('BR-0.2.0','RC2','CONTROL','na','UNCOMMON'),
 ('BR-0.2.0','RC3','CONTROL','na','VERY_RARE'),('BR-0.2.0','RC4','CONTROL','na','RARE'),
 ('BR-0.2.0','RC5','CONTROL','na','VERY_RARE'),('BR-0.2.0','RC6','CONTROL','na','RARE'),
 ('BR-0.2.0','RC1','FUNCTION','sensitive','RARE'),('BR-0.2.0','RC2','FUNCTION','sensitive','VERY_RARE'),
 ('BR-0.2.0','RC3','FUNCTION','sensitive','VERY_RARE'),('BR-0.2.0','RC4','FUNCTION','sensitive','VERY_RARE'),
 ('BR-0.2.0','RC5','FUNCTION','sensitive','VERY_RARE'),('BR-0.2.0','RC6','FUNCTION','sensitive','VERY_RARE'),
 ('BR-0.2.0','RC1','FUNCTION','mundane','UNCOMMON'),('BR-0.2.0','RC2','FUNCTION','mundane','UNCOMMON'),
 ('BR-0.2.0','RC3','FUNCTION','mundane','UNCOMMON'),('BR-0.2.0','RC4','FUNCTION','mundane','UNCOMMON'),
 ('BR-0.2.0','RC5','FUNCTION','mundane','RARE'),('BR-0.2.0','RC6','FUNCTION','mundane','RARE');

update base_rate_table set published_note =
 'On the order of a few hundred genuinely hardened federal facilities in CONUS '
 'against tens of thousands of anthropogenic underground structures.'
where reading = 'VERY_RARE';

-- The frozen 32-entry regression suite (§12.7). Load-bearing PAIRS must
-- reproduce exactly; any rubric returning one number per site fails them
-- by construction.
insert into ops.calibration_case (case_id, lens, label, class, expected_grade, is_load_bearing_pair) values
 ('H1','historian','Cheyenne Mountain — EXIST','EXIST','A',true),
 ('H2','historian','Cheyenne Mountain — "current NORAD HQ"','STATUS','R',true),
 ('H3','historian','33 Thomas St — EXIST & HARDEN','HARDEN','A',false),
 ('H4','historian','Greenbrier 1991 — EXIST','EXIST','B',true),
 ('H4b','historian','Greenbrier 1991 — FUNCTION(COG)','FUNCTION','E',true),
 ('H5','historian','Greenbrier post-1992','EXIST','A',true),
 ('H6','historian','PEF Cartwheel, Fort Reno','EXIST','A',false),
 ('H7','historian','Iron Mountain / Boyers','FUNCTION','A',false),
 ('H8','historian','SubTropolis as hardened/COG','HARDEN','R',true),
 ('H9','historian','Camp Hero — EXIST & radar','EXIST','A',true),
 ('H10','historian','"The Montauk Project"','FUNCTION','F',true),
 ('H10o','historian','"The Montauk Project" — ORIGIN','ORIGIN','A',true),
 ('H11','historian','Dulce Base — FUNCTION','FUNCTION','R',true),
 ('H11o','historian','Dulce Base — ORIGIN','ORIGIN','A',true),
 ('H12','historian','DUCC — PROGRAM','PROGRAM','A',true),
 ('H12e','historian','DUCC — EXIST','EXIST','R',true),
 ('H13','historian','Mount Weather — EXIST','EXIST','A',true),
 ('H14','historian','Mount Weather "underground city"','FEATURE','E',true),
 ('H15','historian','DIA bunker claim','FUNCTION','E',false),
 ('I1','intelligence_analyst','Raven Rock','EXIST','A',false),
 ('I2','intelligence_analyst','Sauder/Schneider 129 DUMBs','EXIST','F',false),
 ('I6','intelligence_analyst','Titan II 571-7','EXIST','A',false),
 ('I8','intelligence_analyst','KUMMSC — EXIST','EXIST','A',false),
 ('I8x','intelligence_analyst','KUMMSC — EXTENT','EXTENT','D',false),
 ('I9','intelligence_analyst','Fairview KS — HARDEN','HARDEN','B',true),
 ('I15','intelligence_analyst','Telos, Mount Shasta','EXIST','F',false),
 ('I16','intelligence_analyst','Federal Relocation Arc instance','EXIST','C',false),
 ('I17','intelligence_analyst','Unrestored Nike Hercules magazine','EXIST','A',false),
 ('B1','bes','Mount Pony, Culpeper (non-appropriated)','EXIST','A',false),
 ('B2','bes','Site CARDINAL (canary)','EXIST','F',false),
 ('B3','bes','Louisville Mega Cavern — shelter','FUNCTION','A',true),
 ('B4','bes','Louisville Mega Cavern — COG','FUNCTION','R',true);

update ops.calibration_case set pair_with='H2' where case_id='H1';
update ops.calibration_case set pair_with='H1' where case_id='H2';
update ops.calibration_case set pair_with='H10' where case_id='H9';
update ops.calibration_case set pair_with='H12e' where case_id='H12';
update ops.calibration_case set pair_with='H11o' where case_id='H11';
update ops.calibration_case set pair_with='B4' where case_id='B3';
