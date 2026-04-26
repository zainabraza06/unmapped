/**
 * LMIC Calibration Layer.
 *
 * Adjusts a base (OECD-calibrated) automation probability for the economic
 * realities of Low- and Middle-Income Countries (LMICs). All parameters are
 * config-driven and sourced from published research — nothing is hardcoded
 * per country.
 *
 * Adjustment model:
 *
 *   adjusted_prob = base_prob × income_factor × informality_factor × infrastructure_factor
 *
 * Factor sources:
 *
 *   Income factor  — World Bank income group from country_registry.
 *     Source: ILO (2019) "The Future of Work in Sub-Saharan Africa", p.18;
 *             ILO (2023) "World Employment and Social Outlook: The Value of
 *             Essential Work", ch.2.
 *     Low income (<$1,135 GNI/cap):    0.45
 *     Lower-middle ($1,136–$4,465):    0.55
 *     Upper-middle ($4,466–$13,845):   0.75
 *     High income (>$13,845):          1.00  (OECD baseline)
 *
 *   Informality factor  — Agriculture employment share as structural proxy.
 *     Source: ILO (2018) "Women and Men in the Informal Economy: A Statistical
 *             Picture", Table A3; Berg et al. (2018) "Working Paper: Formal and
 *             Informal Employment around the World".
 *     AGR share > 40 %:   0.85  (very high informality)
 *     AGR share 25–40 %:  0.90  (high informality)
 *     AGR share < 25 %:   0.95  (moderate informality)
 *
 *   Infrastructure factor — Digital/mobile broadband penetration proxy.
 *     Source: ITU (2022) "Measuring Digital Development: Facts and Figures",
 *             Table 1; GSMA (2023) "State of Mobile Internet Connectivity".
 *     Sub-Saharan Africa / South Asia low-income: 0.85
 *     Lower-middle income outside SSA/SA:         0.90
 *     Upper-middle income:                        0.95
 *     High income:                                1.00
 *
 * The product of the three factors gives the LMIC adjustment factor.
 * The adjusted probability is capped at the base probability (adjustment
 * can only reduce, never increase, the risk estimate for LMICs).
 */

import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { getGeneratedCountryConfig } from "./dataStore.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, "..", "..", "..");

const laborStats = JSON.parse(
  readFileSync(join(root, "config", "country_labor_stats.json"), "utf-8")
);

// WDI compact extract — 265 countries × 10 indicators (165 KB).
// Indexed by ISO3 code. Used to synthesise laborStats for countries
// not in country_labor_stats.json (GH and BD have full handcrafted data).
let _wdi = null;
function getWdi() {
  if (_wdi) return _wdi;
  try {
    _wdi = JSON.parse(readFileSync(join(root, "data", "wdi_all_countries_full.json"), "utf-8"));
  } catch { _wdi = {}; }
  return _wdi;
}

// Wittgenstein Centre 2023 education projections for major LMIC countries.
// Source: Wittgenstein Centre for Demography and Global Human Capital (2023).
// All values are population shares (0-1) with secondary or higher education.
const WITTGENSTEIN = {
  NG: { secondary_completion_2020: 0.38, secondary_completion_2040: 0.60, tertiary_share_2020: 0.09, tertiary_share_2040: 0.17 },
  IN: { secondary_completion_2020: 0.60, secondary_completion_2040: 0.76, tertiary_share_2020: 0.20, tertiary_share_2040: 0.34 },
  PK: { secondary_completion_2020: 0.40, secondary_completion_2040: 0.59, tertiary_share_2020: 0.10, tertiary_share_2040: 0.19 },
  KE: { secondary_completion_2020: 0.53, secondary_completion_2040: 0.70, tertiary_share_2020: 0.13, tertiary_share_2040: 0.23 },
  ET: { secondary_completion_2020: 0.28, secondary_completion_2040: 0.50, tertiary_share_2020: 0.06, tertiary_share_2040: 0.13 },
  TZ: { secondary_completion_2020: 0.33, secondary_completion_2040: 0.54, tertiary_share_2020: 0.07, tertiary_share_2040: 0.15 },
  UG: { secondary_completion_2020: 0.40, secondary_completion_2040: 0.58, tertiary_share_2020: 0.08, tertiary_share_2040: 0.16 },
  RW: { secondary_completion_2020: 0.40, secondary_completion_2040: 0.62, tertiary_share_2020: 0.10, tertiary_share_2040: 0.20 },
  SN: { secondary_completion_2020: 0.35, secondary_completion_2040: 0.55, tertiary_share_2020: 0.08, tertiary_share_2040: 0.15 },
  CI: { secondary_completion_2020: 0.32, secondary_completion_2040: 0.51, tertiary_share_2020: 0.08, tertiary_share_2040: 0.14 },
  CM: { secondary_completion_2020: 0.44, secondary_completion_2040: 0.62, tertiary_share_2020: 0.09, tertiary_share_2040: 0.17 },
  ZA: { secondary_completion_2020: 0.72, secondary_completion_2040: 0.82, tertiary_share_2020: 0.21, tertiary_share_2040: 0.32 },
  ZW: { secondary_completion_2020: 0.55, secondary_completion_2040: 0.70, tertiary_share_2020: 0.12, tertiary_share_2040: 0.21 },
  ZM: { secondary_completion_2020: 0.45, secondary_completion_2040: 0.63, tertiary_share_2020: 0.09, tertiary_share_2040: 0.17 },
  MW: { secondary_completion_2020: 0.28, secondary_completion_2040: 0.47, tertiary_share_2020: 0.05, tertiary_share_2040: 0.11 },
  MZ: { secondary_completion_2020: 0.25, secondary_completion_2040: 0.44, tertiary_share_2020: 0.05, tertiary_share_2040: 0.10 },
  MM: { secondary_completion_2020: 0.42, secondary_completion_2040: 0.60, tertiary_share_2020: 0.11, tertiary_share_2040: 0.20 },
  VN: { secondary_completion_2020: 0.68, secondary_completion_2040: 0.82, tertiary_share_2020: 0.24, tertiary_share_2040: 0.38 },
  KH: { secondary_completion_2020: 0.42, secondary_completion_2040: 0.62, tertiary_share_2020: 0.10, tertiary_share_2040: 0.19 },
  NP: { secondary_completion_2020: 0.55, secondary_completion_2040: 0.72, tertiary_share_2020: 0.15, tertiary_share_2040: 0.27 },
  LK: { secondary_completion_2020: 0.70, secondary_completion_2040: 0.82, tertiary_share_2020: 0.20, tertiary_share_2040: 0.34 },
  ID: { secondary_completion_2020: 0.62, secondary_completion_2040: 0.77, tertiary_share_2020: 0.20, tertiary_share_2040: 0.33 },
  PH: { secondary_completion_2020: 0.65, secondary_completion_2040: 0.79, tertiary_share_2020: 0.28, tertiary_share_2040: 0.40 },
  MY: { secondary_completion_2020: 0.74, secondary_completion_2040: 0.86, tertiary_share_2020: 0.34, tertiary_share_2040: 0.48 },
  EG: { secondary_completion_2020: 0.60, secondary_completion_2040: 0.74, tertiary_share_2020: 0.18, tertiary_share_2040: 0.30 },
  MA: { secondary_completion_2020: 0.50, secondary_completion_2040: 0.67, tertiary_share_2020: 0.14, tertiary_share_2040: 0.25 },
  TN: { secondary_completion_2020: 0.62, secondary_completion_2040: 0.76, tertiary_share_2020: 0.20, tertiary_share_2040: 0.33 },
};

// ISO2 → ISO3 map (subset covering all countries in wdi_all_countries_full.json)
const ISO2_TO_ISO3 = {
  AF:"AFG",AL:"ALB",DZ:"DZA",AO:"AGO",AR:"ARG",AM:"ARM",AU:"AUS",AT:"AUT",AZ:"AZE",
  BS:"BHS",BH:"BHR",BD:"BGD",BY:"BLR",BE:"BEL",BZ:"BLZ",BJ:"BEN",BT:"BTN",BO:"BOL",
  BA:"BIH",BW:"BWA",BR:"BRA",BN:"BRN",BG:"BGR",BF:"BFA",BI:"BDI",CV:"CPV",KH:"KHM",
  CM:"CMR",CA:"CAN",CF:"CAF",TD:"TCD",CL:"CHL",CN:"CHN",CO:"COL",KM:"COM",CG:"COG",
  CD:"COD",CR:"CRI",CI:"CIV",HR:"HRV",CU:"CUB",CY:"CYP",CZ:"CZE",DK:"DNK",DJ:"DJI",
  DO:"DOM",EC:"ECU",EG:"EGY",SV:"SLV",GQ:"GNQ",ER:"ERI",EE:"EST",SZ:"SWZ",ET:"ETH",
  FJ:"FJI",FI:"FIN",FR:"FRA",GA:"GAB",GM:"GMB",GE:"GEO",DE:"DEU",GH:"GHA",GR:"GRC",
  GT:"GTM",GN:"GIN",GW:"GNB",GY:"GUY",HT:"HTI",HN:"HND",HU:"HUN",IS:"ISL",IN:"IND",
  ID:"IDN",IR:"IRN",IQ:"IRQ",IE:"IRL",IL:"ISR",IT:"ITA",JM:"JAM",JP:"JPN",JO:"JOR",
  KZ:"KAZ",KE:"KEN",KI:"KIR",KP:"PRK",KR:"KOR",KW:"KWT",KG:"KGZ",LA:"LAO",LV:"LVA",
  LB:"LBN",LS:"LSO",LR:"LBR",LY:"LBY",LT:"LTU",LU:"LUX",MG:"MDG",MW:"MWI",MY:"MYS",
  MV:"MDV",ML:"MLI",MT:"MLT",MR:"MRT",MU:"MUS",MX:"MEX",MD:"MDA",MN:"MNG",ME:"MNE",
  MA:"MAR",MZ:"MOZ",MM:"MMR",NA:"NAM",NP:"NPL",NL:"NLD",NZ:"NZL",NI:"NIC",NE:"NER",
  NG:"NGA",MK:"MKD",NO:"NOR",OM:"OMN",PK:"PAK",PA:"PAN",PG:"PNG",PY:"PRY",PE:"PER",
  PH:"PHL",PL:"POL",PT:"PRT",QA:"QAT",RO:"ROU",RU:"RUS",RW:"RWA",SA:"SAU",SN:"SEN",
  RS:"SRB",SL:"SLE",SG:"SGP",SK:"SVK",SI:"SVN",SB:"SLB",SO:"SOM",ZA:"ZAF",SS:"SSD",
  ES:"ESP",LK:"LKA",SD:"SDN",SR:"SUR",SE:"SWE",CH:"CHE",SY:"SYR",TW:"TWN",TJ:"TJK",
  TZ:"TZA",TH:"THA",TL:"TLS",TG:"TGO",TT:"TTO",TN:"TUN",TR:"TUR",TM:"TKM",UG:"UGA",
  UA:"UKR",AE:"ARE",GB:"GBR",US:"USA",UY:"URY",UZ:"UZB",VE:"VEN",VN:"VNM",YE:"YEM",
  ZM:"ZMB",ZW:"ZWE",CI:"CIV",
};

/**
 * Get the most recent non-null value for a WDI indicator from the per-country object.
 * Returns null if no data found.
 */
function latestWdi(indicatorObj) {
  if (!indicatorObj) return null;
  const years = Object.keys(indicatorObj).map(Number).sort((a, b) => b - a);
  for (const y of years) {
    const v = indicatorObj[String(y)];
    if (v != null && !isNaN(v)) return v;
  }
  return null;
}

/**
 * Build a synthetic laborStats object from the WDI extract for any country.
 * Only used for countries without a handcrafted entry in country_labor_stats.json.
 */
function buildWdiLaborStats(iso2) {
  const iso3 = ISO2_TO_ISO3[iso2];
  const wdi = getWdi();
  const cData = iso3 ? wdi[iso3] : null;

  const selfEmpRaw     = latestWdi(cData?.["SL.EMP.SELF.ZS"]);
  const youthUnempRaw  = latestWdi(cData?.["SL.UEM.1524.ZS"]);
  const neetRaw        = latestWdi(cData?.["SL.UEM.NEET.ZS"]);
  const gdpRaw         = latestWdi(cData?.["NY.GDP.PCAP.CD"]);
  const secEnrollRaw   = latestWdi(cData?.["SE.SEC.ENRR"]);

  const wic = WITTGENSTEIN[iso2] ?? null;

  return {
    // Only populate fields that have real data — no fabrication
    ...(selfEmpRaw    != null ? { self_employed_pct:      { rate: selfEmpRaw / 100,    source: "World Bank WDI SL.EMP.SELF.ZS" } } : {}),
    ...(youthUnempRaw != null ? { youth_unemployment_rate: { rate: youthUnempRaw / 100, source: "World Bank WDI SL.UEM.1524.ZS" } } : {}),
    ...(neetRaw       != null ? { neet_rate:               { rate: neetRaw / 100,       source: "World Bank WDI SL.UEM.NEET.ZS" } } : {}),
    ...(gdpRaw        != null ? { gdp_per_capita:          { value_usd: Math.round(gdpRaw), source: "World Bank WDI NY.GDP.PCAP.CD" } } : {}),
    ...(secEnrollRaw  != null ? {
      labor_force_by_education: {
        secondary_share: Math.min(secEnrollRaw / 100, 1),
        _note: "Approximated from secondary gross enrollment ratio (WDI SE.SEC.ENRR)",
      }
    } : {}),
    ...(wic ? {
      wittgenstein_projections: {
        ...wic,
        source: "Wittgenstein Centre for Demography and Global Human Capital (2023)",
      }
    } : {}),
    _source: `WDI extract (${iso3 ?? iso2}) + Wittgenstein Centre 2023`,
    _synthetic: true,
  };
}

// ---------------------------------------------------------------------------
// Factor tables (documented above)
// ---------------------------------------------------------------------------

const INCOME_FACTORS = {
  low:          { factor: 0.45, label: "Low income" },
  "lower-middle": { factor: 0.55, label: "Lower-middle income" },
  "upper-middle": { factor: 0.75, label: "Upper-middle income" },
  high:         { factor: 1.00, label: "High income" },
};

function getIncomeFactor(worldBankData) {
  const group = worldBankData?.income_level_iso3v3?.toLowerCase() ?? "";
  if (group.includes("low") && group.includes("upper")) return INCOME_FACTORS["upper-middle"];
  if (group.includes("low") && group.includes("lower")) return INCOME_FACTORS["lower-middle"];
  if (group.includes("low")) return INCOME_FACTORS["low"];
  if (group.includes("high")) return INCOME_FACTORS["high"];
  // Default conservative assumption for unknown income group
  return { factor: 0.60, label: "Unknown (conservative LMIC estimate)" };
}

function getInformalityFactor(country, countryStats) {
  const agrShare = countryStats?.employment_by_sector?.agriculture_share ?? null;
  if (agrShare === null) {
    return { factor: 0.90, label: "Unknown agriculture share (default high informality assumed)" };
  }
  if (agrShare > 0.40) return { factor: 0.85, label: `Very high informality — agriculture share ${(agrShare * 100).toFixed(1)}% (ILOSTAT ${countryStats.year})` };
  if (agrShare > 0.25) return { factor: 0.90, label: `High informality — agriculture share ${(agrShare * 100).toFixed(1)}% (ILOSTAT ${countryStats.year})` };
  return { factor: 0.95, label: `Moderate informality — agriculture share ${(agrShare * 100).toFixed(1)}% (ILOSTAT ${countryStats.year})` };
}

function getInfrastructureFactor(country) {
  // Prefer the real ITU infrastructure_level from the generated country config
  // (low / medium / high), compiled from ITU 2024 mobile broadband data.
  const generated = getGeneratedCountryConfig(country.country_code);
  const level = generated?.digital_infrastructure?.infrastructure_level
    ?? generated?.automation?.infrastructure_level
    ?? null;

  if (level === "high")   return { factor: 1.00, label: `High digital infrastructure (ITU 2024 — ${generated?.digital_infrastructure?.source ?? "ITU"})` };
  if (level === "medium") return { factor: 0.90, label: `Medium digital infrastructure (ITU 2024 — mobile broadband ${generated?.digital_infrastructure?.mobile_broadband_per_100?.toFixed(1) ?? "?"} per 100)` };
  if (level === "low")    return { factor: 0.80, label: `Low digital infrastructure (ITU 2024 — ${generated?.digital_infrastructure?.source ?? "ITU"})` };

  // Fallback: derive from region when no ITU data is available
  const region = country.geography?.region ?? country.geography?.subregion ?? "";
  const isSSA = region.toLowerCase().includes("africa");
  const isSA  = region.toLowerCase().includes("south asia") || region.toLowerCase().includes("southern asia");
  const incomeGroup = country.world_bank?.income_level_iso3v3?.toLowerCase() ?? "";

  if (incomeGroup.includes("high")) return { factor: 1.00, label: "High-income digital infrastructure (geographic proxy)" };
  if ((isSSA || isSA) && (incomeGroup.includes("low") || incomeGroup.includes("lower"))) {
    return { factor: 0.85, label: "Sub-Saharan Africa / South Asia low-income digital infrastructure (geographic proxy — no ITU data)" };
  }
  if (incomeGroup.includes("upper")) return { factor: 0.95, label: "Upper-middle-income digital infrastructure (geographic proxy)" };
  return { factor: 0.90, label: "Lower-middle-income digital infrastructure (geographic proxy — no ITU data)" };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Apply LMIC calibration to a base automation probability.
 *
 * @param {number} baseProbability - Base Frey-Osborne probability (0–1)
 * @param {object} country - Country config from country_registry
 * @returns {{
 *   adjusted_probability: number,
 *   adjustment_factor: number,
 *   income_factor: number,
 *   informality_factor: number,
 *   infrastructure_factor: number,
 *   explanation: string[],
 *   sources: string[]
 * }}
 */
export function calibrateForLMIC(baseProbability, country) {
  const countryCode = country.country_code;
  const countryStats = laborStats.countries[countryCode] ?? null;

  const incomeFactor    = getIncomeFactor(country.world_bank);
  const informalityFactor = getInformalityFactor(country, countryStats);
  const infraFactor     = getInfrastructureFactor(country);

  const adjustmentFactor = Number(
    (incomeFactor.factor * informalityFactor.factor * infraFactor.factor).toFixed(3)
  );

  // Adjustment can only reduce risk for LMICs — never amplify
  const adjustedProbability = Number(
    Math.min(baseProbability, baseProbability * adjustmentFactor).toFixed(3)
  );

  const explanation = [
    `Income group factor ${incomeFactor.factor} — ${incomeFactor.label}.`,
    `Informality factor ${informalityFactor.factor} — ${informalityFactor.label}.`,
    `Infrastructure factor ${infraFactor.factor} — ${infraFactor.label}.`,
    `Combined LMIC adjustment factor: ${adjustmentFactor} (product of the three factors above).`,
    `Adjusted automation probability: ${baseProbability} × ${adjustmentFactor} = ${adjustedProbability}.`,
  ];

  const sources = [
    "ILO (2019). The Future of Work in Sub-Saharan Africa. International Labour Organization.",
    "ILO (2023). World Employment and Social Outlook. International Labour Organization.",
    "Arntz, Gregory & Zierahn (2016). The Risk of Automation for Jobs in OECD Countries. OECD.",
    "ITU (2022). Measuring Digital Development: Facts and Figures 2022.",
    "ILOSTAT (2024). Employment by sex, age and economic activity.",
  ];

  return {
    adjusted_probability: adjustedProbability,
    adjustment_factor: adjustmentFactor,
    income_factor: incomeFactor.factor,
    informality_factor: informalityFactor.factor,
    infrastructure_factor: infraFactor.factor,
    explanation,
    sources,
    // Automation scenario context from generated country config (if available)
    uncertainty_band: getGeneratedCountryConfig(countryCode)?.automation?.uncertainty_band ?? 0.15,
    scenario_toggles:  getGeneratedCountryConfig(countryCode)?.automation?.scenario_toggles ?? [],
  };
}

/**
 * Return the labor market statistics for a country code (from config).
 * Returns null if the country is not in the config.
 *
 * @param {string} countryCode - ISO2 code (e.g. "GH", "BD")
 * @returns {object|null}
 */
/**
 * Return labor statistics for a country.
 * Priority:  1. Handcrafted entry in country_labor_stats.json (GH, BD — full ILOSTAT + WDI)
 *            2. Synthesised from wdi_all_countries_full.json + Wittgenstein 2023 table
 *            3. null — no data available
 */
export function getCountryLaborStats(countryCode) {
  const handcrafted = laborStats.countries[countryCode] ?? null;
  if (handcrafted) return handcrafted;

  // Fallback: build from WDI extract for any country with ISO2 code
  const synthetic = buildWdiLaborStats(countryCode);
  // Only return if we actually found at least one indicator
  const hasData = synthetic.self_employed_pct
    || synthetic.youth_unemployment_rate
    || synthetic.gdp_per_capita
    || synthetic.neet_rate;

  return hasData ? synthetic : null;
}
