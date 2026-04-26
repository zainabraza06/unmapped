/**
 * Module 2 — Labor Market Risk Analysis Engine.
 *
 * Analyses an occupation profile and estimates automation / AI impact in a
 * specific country context. The pipeline has five steps:
 *
 *   Steps 1–2  Deterministic (no LLM):
 *     1. Automation risk estimation (Frey-Osborne + O*NET crosswalk)
 *     2. LMIC calibration (country config + ILOSTAT labor structure)
 *
 *   Steps 3–5  LLM-assisted (OpenRouter, falls back to structured templates):
 *     3. Task decomposition (high-risk vs low-risk tasks)
 *     4. Skill resilience analysis (at-risk / durable / adjacent)
 *     5. Macro context overlay (education projection + labor shift trend)
 *
 * Output is the strict JSON schema defined in the product spec.
 * Numeric values in the output come ONLY from the deterministic steps or the
 * Module 1 profile — the LLM provides narrative and classification only.
 */

import { getByONetLinks, getByISCOGroup } from "./automation-lookup.js";
import { calibrateForLMIC, getCountryLaborStats } from "./lmic-calibrator.js";
import { getTaxonomyIndex } from "./dataStore.js";
import { callOpenRouter, parseJsonResponse } from "./llm-client.js";

const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS ?? 60000);

// ---------------------------------------------------------------------------
// Step 1 — Automation risk estimation
// ---------------------------------------------------------------------------

function computeBaseAutomation(occupation) {
  // Tier 1: weighted average via pre-computed O*NET links in taxonomy
  const onetLinks = occupation.onet?.matches ?? [];
  const onetResult = getByONetLinks(onetLinks);
  if (onetResult) return onetResult;

  // Tier 2: ISCO major-group fallback (documented group averages)
  const groupResult = getByISCOGroup(occupation.isco_code);
  if (groupResult) return groupResult;

  // Tier 3: no data — return null; risk engine will mark confidence as none
  return null;
}

// ---------------------------------------------------------------------------
// Step 3–5 — LLM analysis prompt
// ---------------------------------------------------------------------------

const SYSTEM_PROMPT = `You are a labor economics analyst specialising in automation risk and LMIC labor markets.

You will receive a structured occupation profile with pre-computed automation probabilities. Your job is to:
1. Decompose the occupation into high-risk and low-risk tasks (step 3).
2. Classify the skills into at-risk, durable, and adjacent-upskilling categories (step 4).
3. Summarise macro trends affecting this occupation in the given country (step 5).

Rules you MUST follow:
- Do NOT invent or change any numeric probability values. They are provided to you.
- Base skill analysis ONLY on the skills listed in the profile. Do not add new ones.
- Be conservative; prefer lower risk ratings over aggressive claims.
- Risk scores must be between 0.0 and 1.0.
- Return valid JSON only. No markdown. No prose outside the JSON object.`;

function buildAnalysisPrompt(occupation, skills, country, automation, laborStats) {
  const onetTasks = (occupation.onet?.enrichments ?? [])
    .slice(0, 2)
    .flatMap((e) => (e.tasks ?? []).slice(0, 6).map((t) => t.task))
    .slice(0, 10);

  const wic = laborStats?.wittgenstein_projections ?? null;

  const context = {
    isco_code: occupation.isco_code,
    occupation_title: occupation.label,
    esco_code: occupation.esco_code,
    sector: occupation.sectors?.[0] ?? "unknown",
    skills_from_profile: skills,
    onet_sample_tasks: onetTasks,
    country: {
      name: country.country_name,
      code: country.country_code,
      world_bank_income: country.world_bank?.income_level_iso3v3 ?? "unknown",
      agriculture_share_2024: laborStats?.employment_by_sector?.agriculture_share ?? null,
      advanced_education_share_2024: laborStats?.labor_force_by_education?.advanced_share ?? null,
      wittgenstein_secondary_completion_2040: wic?.secondary_completion_2040 ?? null,
      wittgenstein_tertiary_share_2040: wic?.tertiary_share_2040 ?? null,
      wittgenstein_source: wic?.source ?? null,
    },
    pre_computed_automation: {
      base_probability: automation.base,
      adjusted_probability: automation.adjusted,
      adjustment_factor: automation.adjustment_factor,
      note: "These values are fixed. Do not change them in your output.",
    },
  };

  return `${JSON.stringify(context, null, 2)}

Analyse the occupation profile above and return ONLY valid JSON matching this structure exactly (no markdown fences, no extra keys, no angle-bracket placeholders):
{
  "task_breakdown": {
    "high_risk_tasks": [
      { "task": "Process routine data into standard templates", "risk_score": 0.82 },
      { "task": "Apply standardised testing protocols", "risk_score": 0.74 }
    ],
    "low_risk_tasks": [
      { "task": "Diagnose non-standard faults in complex systems", "risk_score": 0.21 },
      { "task": "Negotiate with clients on technical requirements", "risk_score": 0.15 }
    ]
  },
  "skill_resilience_analysis": {
    "at_risk_skills": ["routine testing", "data entry"],
    "durable_skills": ["fault diagnosis", "client communication"],
    "adjacent_skills": ["IoT sensor configuration", "basic data analysis"]
  },
  "macro_signals": {
    "education_projection": "Secondary completion is rising. By 2040 a larger workforce share will hold formal credentials, increasing competition for technical roles.",
    "labor_shift_trend": "A high-informality market is gradually formalising through mobile finance and digital supply chains, expected to accelerate through 2035."
  },
  "final_readiness_profile": {
    "risk_level": "medium",
    "resilience_level": "medium",
    "opportunity_type": "upskilling_required",
    "summary": "The occupation faces moderate risk. Durable skills buffer near-term displacement, but upskilling toward digital or supervisory roles is advisable within 5 years."
  },
  "explainability": {
    "key_drivers": [
      "Adjusted automation probability reflects LMIC infrastructure constraints.",
      "High-risk tasks are routine and procedural; low-risk tasks require contextual judgment.",
      "Informality and low wages delay automation adoption vs OECD baseline."
    ]
  }
}

Replace all example values with real analysis of the profile above. Rules:
- high_risk_tasks: 2 to 4 objects with numeric risk_score (0.0 to 1.0).
- low_risk_tasks: 2 to 4 objects with numeric risk_score (0.0 to 1.0).
- at_risk_skills and durable_skills: use ONLY skill names from skills_from_profile.
- adjacent_skills: 1 to 3 upskilling areas not already in the profile.
- risk_level and resilience_level must match adjusted_probability ${automation.adjusted}.
- key_drivers: exactly 3 strings.
- Return ONLY the JSON object. No prose. No markdown.`;
}

// ---------------------------------------------------------------------------
// LLM call with template fallback
// ---------------------------------------------------------------------------

async function callLLMOnce(occupation, skills, country, automation, laborStats) {
  const { content, model } = await callOpenRouter({
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: buildAnalysisPrompt(occupation, skills, country, automation, laborStats) },
    ],
    max_tokens: 2000,
    timeout_ms: LLM_TIMEOUT_MS,
    referer_title: "UNMAPPED Risk Engine",
    log_prefix: "[risk-engine]",
  });

  const parsed = parseJsonResponse(content);

  const required = ["task_breakdown", "skill_resilience_analysis", "macro_signals", "final_readiness_profile", "explainability"];
  for (const key of required) {
    if (!parsed[key]) throw new Error(`LLM response missing key: ${key}`);
  }
  return { ...parsed, _provider: `openrouter/${model}` };
}

async function runLLMAnalysis(occupation, skills, country, automation, laborStats) {
  if (!process.env.OPENROUTER_API_KEY) {
    console.info("[risk-engine] No OPENROUTER_API_KEY — using deterministic template.");
    return buildTemplateFallback(occupation, skills, automation, laborStats, country);
  }

  try {
    return await callLLMOnce(occupation, skills, country, automation, laborStats);
  } catch (err) {
    console.warn(`[risk-engine] All models exhausted: ${err.message} — using deterministic template`);
    return buildTemplateFallback(occupation, skills, automation, laborStats, country);
  }
}

// Generic ISCO task templates used when O*NET data is not available in the
// taxonomy. Based on ILO task classification by ISCO major group.
const ISCO_TEMPLATE_TASKS = {
  "1": {
    high: ["Coordinate and schedule operational activities", "Monitor budget and resource allocation"],
    low:  ["Negotiate with clients and partners", "Mentor and develop team members"],
  },
  "2": {
    high: ["Document and file case records", "Apply established research procedures"],
    low:  ["Diagnose complex or unusual situations", "Advise clients on specialized matters"],
  },
  "3": {
    high: ["Record and log data from instruments or equipment", "Apply standard testing protocols"],
    low:  ["Troubleshoot non-routine technical faults", "Coordinate with clients on technical issues"],
  },
  "4": {
    high: ["Process and file standard documents", "Enter data into information systems"],
    low:  ["Handle customer inquiries and complaints", "Resolve data discrepancies"],
  },
  "5": {
    high: ["Process routine transactions", "Maintain inventory counts"],
    low:  ["Serve and assist customers directly", "Adapt service to customer needs"],
  },
  "6": {
    high: ["Apply standard planting or harvesting methods", "Sort and grade produce"],
    low:  ["Monitor crop or animal health conditions", "Operate in variable terrain and weather"],
  },
  "7": {
    high: ["Perform repetitive assembly or fabrication tasks", "Apply standard finishing operations"],
    low:  ["Diagnose and repair non-standard faults", "Adapt methods to varying materials or conditions"],
  },
  "8": {
    high: ["Operate machinery on a fixed production line", "Load and unload materials according to schedule"],
    low:  ["Monitor equipment for abnormal conditions", "Respond to mechanical breakdowns"],
  },
  "9": {
    high: ["Perform routine cleaning or sorting tasks", "Follow simple sequential instructions"],
    low:  ["Navigate changing physical environments", "Interact directly with the public"],
  },
};

/**
 * Build grounded education_projection text from real Wittgenstein Centre and
 * WDI data stored in country_labor_stats.json. Never returns "LLM unavailable".
 */
function buildEducationProjection(laborStats, country) {
  const wic = laborStats?.wittgenstein_projections;
  const wdi = laborStats;

  if (wic?.secondary_completion_2040 != null) {
    const sec2020 = wic.secondary_completion_2020 != null ? `${Math.round(wic.secondary_completion_2020 * 100)}%` : null;
    const sec2040 = `${Math.round(wic.secondary_completion_2040 * 100)}%`;
    const ter2040 = wic.tertiary_share_2040 != null ? `${Math.round(wic.tertiary_share_2040 * 100)}%` : null;
    const secTrend = sec2020 ? `up from ${sec2020} in 2020 to a projected ${sec2040} by 2040` : `a projected ${sec2040} by 2040`;
    const terPart  = ter2040 ? ` Tertiary attainment is projected to reach ${ter2040} of the workforce by 2040.` : "";
    return `Secondary completion in ${country.label ?? country.country_code} is ${secTrend} (${wic.source ?? "Wittgenstein Centre 2023"}).${terPart} Rising education levels will gradually shift the labor market toward semi-formal and credentialed employment, increasing competition for technical roles.`;
  }

  // WDI proxy: secondary enrollment trend
  const secEnroll = wdi?.labor_force_by_education?.secondary_share;
  if (secEnroll != null) {
    const pct = `${Math.round(secEnroll * 100)}%`;
    return `Secondary enrollment in ${country.label ?? country.country_code} stands at approximately ${pct} of the relevant age cohort (World Bank WDI). Continued expansion of secondary and vocational education over 2025–2035 will gradually raise credential expectations for technical and trade occupations.`;
  }

  return `Education attainment in ${country.label ?? country.country_code} is expanding across secondary and vocational levels. The ILO projects continued growth in formal credentialing in LMIC labor markets through 2035, which will gradually shift hiring expectations for technical occupations.`;
}

function buildLaborShiftTrend(laborStats, country) {
  const selfEmp = laborStats?.self_employed_pct?.rate ?? laborStats?.self_employed_pct;
  const agri    = laborStats?.employment_by_sector?.agriculture_share;
  const informal = country.informality_level ?? "high";

  const selfEmpPct = selfEmp != null ? `${Math.round(selfEmp * 100)}%` : null;
  const agriPct    = agri   != null ? `${Math.round(agri   * 100)}%` : null;

  let sentence = `${country.label ?? country.country_code} has a ${informal}-informality labor market`;
  if (selfEmpPct) sentence += ` where ${selfEmpPct} of workers are self-employed`;
  if (agriPct)   sentence += ` and agriculture employs approximately ${agriPct} of the workforce`;
  sentence += ". ";

  sentence += "The structural shift from subsistence and informal employment toward semi-formal service and trade roles is ongoing but slow, constrained by credential gaps and infrastructure. Formalization is expected to accelerate modestly between 2025–2035 as mobile finance and digital supply chains expand.";
  return sentence;
}

function buildTemplateFallback(occupation, skills, automation, laborStats, country) {
  const prob = automation.adjusted;
  const riskLevel = prob >= 0.7 ? "very high" : prob >= 0.5 ? "high" : prob >= 0.3 ? "medium" : "low";
  const iscoMajor = String(occupation.isco_code ?? "7")[0];
  const templates = ISCO_TEMPLATE_TASKS[iscoMajor] ?? ISCO_TEMPLATE_TASKS["7"];

  const onetTasks = (occupation.onet?.enrichments ?? [])
    .slice(0, 1)
    .flatMap((e) => (e.tasks ?? []).slice(0, 4).map((t) => t.task));

  const highRiskSource = onetTasks.length >= 2 ? onetTasks.slice(0, 2) : templates.high;
  const lowRiskSource  = onetTasks.length >= 4 ? onetTasks.slice(2, 4) : templates.low;

  const highRisk = highRiskSource.map((t) => ({ task: t, risk_score: Number((prob * 0.9).toFixed(2)) }));
  const lowRisk  = lowRiskSource.map((t) => ({ task: t, risk_score: Number((prob * 0.35).toFixed(2)) }));

  const half = Math.ceil(skills.length / 2);
  return {
    task_breakdown: { high_risk_tasks: highRisk, low_risk_tasks: lowRisk },
    skill_resilience_analysis: {
      at_risk_skills:  skills.slice(0, half),
      durable_skills:  skills.slice(half),
      adjacent_skills: [],
    },
    macro_signals: {
      education_projection: buildEducationProjection(laborStats, country),
      labor_shift_trend:    buildLaborShiftTrend(laborStats, country),
    },
    final_readiness_profile: {
      risk_level: riskLevel,
      resilience_level: prob >= 0.6 ? "low" : "medium",
      opportunity_type: prob >= 0.65 ? "upskilling_required" : "stable",
      summary: `Template fallback (LLM unavailable). Adjusted automation probability ${prob} implies ${riskLevel} risk for this occupation in the given country context.`,
    },
    explainability: {
      key_drivers: [
        `Adjusted automation probability ${prob} (base × LMIC factor ${automation.adjustment_factor}).`,
        `ISCO group ${iscoMajor} task structure — high-risk tasks are repetitive/procedural; low-risk tasks involve contextual judgment.`,
        "LMIC context reduces near-term automation risk vs OECD baseline due to informality and infrastructure constraints.",
      ],
    },
    _provider: "template_fallback",
  };
}

// ---------------------------------------------------------------------------
// Main entry point
// ---------------------------------------------------------------------------

/**
 * Run the full Module 2 risk analysis pipeline.
 *
 * @param {object} params
 * @param {object} params.profile    - Module 1 profile output (from buildProfile)
 * @param {object} params.country    - Country config object from country_registry
 * @returns {Promise<object>}        - Risk analysis in the Module 2 JSON schema
 */
export async function analyseRisk({ profile, country }) {
  // Resolve occupation from taxonomy for O*NET task data
  const taxonomy = getTaxonomyIndex();
  const occupationId = profile.primary_occupation?.occupation_id;
  const occupation = occupationId ? taxonomy.occupations[occupationId] : null;

  // Step 1 — Base automation probability
  const baseResult =
    occupation
      ? computeBaseAutomation(occupation)
      : getByISCOGroup(profile.primary_occupation?.isco_code);

  const baseProbability = baseResult?.probability ?? null;
  const baseSource      = baseResult?.source ?? "unavailable";

  // Step 2 — LMIC calibration
  const lmicResult = baseProbability !== null
    ? calibrateForLMIC(baseProbability, country)
    : null;

  const adjustedProbability = lmicResult?.adjusted_probability ?? baseProbability ?? null;
  const adjustmentFactor    = lmicResult?.adjustment_factor ?? 1.0;

  const automationSummary = {
    base: baseProbability,
    adjusted: adjustedProbability,
    adjustment_factor: adjustmentFactor,
    base_source: baseSource,
  };

  // Collect skills from the profile (Module 1 only — no hallucination)
  const skillLabels = (profile.skills?.mapped ?? []).map((s) => s.plain_label || s.label);

  // Country labor stats for macro context
  const laborStats = getCountryLaborStats(country.country_code);

  // Steps 3–5 — LLM analysis
  const llmResult = await runLLMAnalysis(occupation ?? {}, skillLabels, country, automationSummary, laborStats);

  // Assemble final output per the strict JSON schema
  return {
    isco_code: profile.primary_occupation?.isco_code ?? "",
    occupation_title: profile.primary_occupation?.title ?? "",

    automation_analysis: {
      source_model: "Frey-Osborne (2017) + ILO LMIC adjustment",
      base_automation_probability: baseProbability,
      base_source: baseSource,
      lmic_adjustment_explanation: lmicResult?.explanation ?? [
        "No LMIC adjustment applied — base probability unavailable.",
      ],
      adjustment_factor: adjustmentFactor,
      adjusted_automation_probability: adjustedProbability,
      sources: lmicResult?.sources ?? [],
    },

    task_breakdown: llmResult.task_breakdown,
    skill_resilience_analysis: llmResult.skill_resilience_analysis,

    economic_context: {
      country: country.country_name,
      informality_level: laborStats?.employment_by_sector?.agriculture_share != null
        ? `Agriculture share ${(laborStats.employment_by_sector.agriculture_share * 100).toFixed(1)}% (ILOSTAT ${laborStats.year ?? "recent"})`
        : country.informality_level ?? "Data not available",
      interpretation: lmicResult?.explanation?.[0] ?? "LMIC calibration not available",
    },

    macro_signals: llmResult.macro_signals,
    final_readiness_profile: llmResult.final_readiness_profile,
    explainability: llmResult.explainability,

    _meta: {
      analysis_provider: llmResult._provider ?? "unknown",
      profile_id: profile.id,
      generated_at: new Date().toISOString(),
    },
  };
}
