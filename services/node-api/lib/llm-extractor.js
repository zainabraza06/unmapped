/**
 * LLM-based skill extractor — powered by OpenRouter.
 *
 * Uses shared HTTP client (llm-client.js) with a multi-model cascade on OpenRouter.
 * Falls back to deterministic heuristic extraction when OPENROUTER_API_KEY
 * is absent or the LLM call fails, so the system runs fully offline.
 *
 * Output is a strict superset of the legacy extractSignals() shape so
 * scorer.js and the rest of the pipeline remain unchanged.
 *
 * Environment variables (set in .env):
 *   OPENROUTER_API_KEY   — required to enable the LLM path
 *   OPENROUTER_MODEL     — primary model slug (cascade continues on 429/404)
 *   LLM_TIMEOUT_MS       — request timeout in ms, default 60000
 */

import { normalizeText } from "./text.js";
import { callOpenRouter, parseJsonResponse, getModelCascade } from "./llm-client.js";

// Free-tier models on OpenRouter can take 30-60s — give them full headroom.
const LLM_TIMEOUT_MS = Number(process.env.LLM_TIMEOUT_MS ?? 60000);

// ---------------------------------------------------------------------------
// Heuristic fallback — runs when no API key is set or on LLM failure.
// Preserved verbatim from original nlp.js so behavior is identical.
// ---------------------------------------------------------------------------

const SKILL_KEYWORDS = {
  "repair mobile devices": [
    "fix phone",
    "repair phone",
    "replace screen",
    "battery",
    "lcd",
    "keypad",
    "mobile",
  ],
  troubleshoot: ["diagnose", "fault", "problem", "not working", "troubleshoot"],
  "maintain customer service": ["customer", "client", "explain", "advise"],
  "manage inventory": ["stock", "inventory", "parts", "supplies"],
  "use digital tools": [
    "internet",
    "youtube",
    "whatsapp",
    "computer",
    "mobile money",
    "bkash",
  ],
  "train others informally": [
    "teach",
    "train",
    "apprentice",
    "helper",
    "cousin",
  ],
};

const TOOL_KEYWORDS = {
  "mobile phone": ["phone", "mobile", "cell"],
  "small repair tools": ["screwdriver", "tool", "pliers", "solder"],
  internet: ["internet", "youtube", "online", "whatsapp"],
  "payment tools": ["mobile money", "momo", "bkash", "cash"],
};

const SECTOR_KEYWORDS = {
  technical_services: [
    "repair",
    "phone",
    "electronics",
    "device",
    "technical",
    "software",
  ],
  retail_trade: ["sell", "shop", "customer", "cashier", "stock"],
  construction: [
    "build",
    "construction",
    "carpenter",
    "weld",
    "electrician",
    "plumb",
  ],
  garments: ["sew", "tailor", "garment", "dress", "fabric"],
  transport: ["drive", "deliver", "motorbike", "taxi", "van"],
  food_services: ["cook", "kitchen", "food", "restaurant"],
};

function countMatches(text, keywords) {
  return keywords.reduce(
    (count, kw) => count + (text.includes(normalizeText(kw)) ? 1 : 0),
    0
  );
}

function heuristicExtract(answers) {
  const text = normalizeText(
    [
      answers.work_description,
      answers.extra_skills,
      ...(answers.tools ?? []),
      ...(answers.selected_skills ?? []),
    ].join(" ")
  );

  const skills = Object.entries(SKILL_KEYWORDS)
    .filter(([, kws]) => countMatches(text, kws) > 0)
    .map(([skill]) => skill);

  const tools = Object.entries(TOOL_KEYWORDS)
    .filter(([, kws]) => countMatches(text, kws) > 0)
    .map(([tool]) => tool);

  const sectorScores = Object.fromEntries(
    Object.entries(SECTOR_KEYWORDS).map(([sector, kws]) => [
      sector,
      countMatches(text, kws),
    ])
  );
  const likelySector = Object.entries(sectorScores).sort(
    (a, b) => b[1] - a[1]
  )[0];

  return {
    skills,
    tools,
    extracted_skills: skills.map((s) => ({
      label: s,
      confidence: 0.6,
      esco_hint: null,
      source: "heuristic",
    })),
    extracted_tasks: [],
    likely_sector:
      likelySector?.[1] > 0 ? likelySector[0] : (answers.sector ?? null),
    confidence: "heuristic",
    notes: ["node_deterministic_nlp"],
    provider: "heuristic",
  };
}

// ---------------------------------------------------------------------------
// LLM extraction via OpenRouter SDK
// ---------------------------------------------------------------------------

const SYSTEM_PROMPT = `You are a labor market analyst specializing in the ESCO (European Skills, Competencies, Qualifications and Occupations) taxonomy.

Your job: analyze informal work descriptions from workers in developing economies and extract structured occupational skill and task information.

Rules:
- Extract ONLY skills and tasks explicitly evidenced in the text. Do not infer or invent.
- Phrase skills in ESCO verb-object style: e.g. "repair electronic equipment", "manage customer interactions", "operate hand tools".
- Include occupational skills only — not personality traits or soft-skill generics.
- Confidence (0.0–1.0): how certain you are the skill is evidenced by the text.
- Output valid JSON only. No markdown fences, no prose outside the JSON object.`;

function buildUserPrompt(answers) {
  const lines = [
    `Work description: ${answers.work_description || "(not provided)"}`,
    `Sector: ${answers.sector || "(not provided)"}`,
    answers.extra_skills ? `Additional skills stated: ${answers.extra_skills}` : null,
    answers.tools?.length ? `Tools mentioned: ${answers.tools.join(", ")}` : null,
    answers.selected_skills?.length
      ? `Self-selected skills: ${answers.selected_skills.join(", ")}`
      : null,
  ]
    .filter(Boolean)
    .join("\n");

  return `${lines}

Extract structured skills and tasks. Return ONLY this JSON object (no extra keys):
{
  "extracted_skills": [
    { "label": "<ESCO-phrased skill>", "confidence": <0.0-1.0>, "esco_hint": "<nearest ESCO skill label or null>" }
  ],
  "extracted_tasks": ["<concrete task verb phrase>"],
  "likely_sector": "<one of: technical_services | retail_trade | construction | garments | transport | food_services | agriculture | personal_services | professional_services | other>",
  "extraction_notes": "<one sentence, optional, or null>"
}

Constraints: up to 8 skills, up to 6 tasks. Do not guess the sector beyond what the text implies.`;
}

/**
 * Strip markdown code fences if the model wraps its JSON output in them.
 * Some models return ```json ... ``` even when instructed not to.
 */
function stripCodeFences(raw) {
  return raw
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/, "")
    .trim();
}

async function callLLM(answers) {
  const { content, model } = await callOpenRouter({
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: buildUserPrompt(answers) },
    ],
    max_tokens: 800,
    timeout_ms: LLM_TIMEOUT_MS,
    referer_title: "UNMAPPED Skill Extractor",
    log_prefix: "[llm-extractor]",
  });

  const parsed = parseJsonResponse(content);

  const extractedSkills = (parsed.extracted_skills ?? [])
    .filter((s) => s && typeof s.label === "string" && s.label.trim())
    .slice(0, 8)
    .map((s) => ({
      label: s.label.trim().toLowerCase(),
      confidence: Math.min(1, Math.max(0, Number(s.confidence) || 0.7)),
      esco_hint: typeof s.esco_hint === "string" ? s.esco_hint : null,
      source: "llm",
    }));

  const extractedTasks = (parsed.extracted_tasks ?? [])
    .filter((t) => typeof t === "string" && t.trim())
    .slice(0, 6)
    .map((t) => t.trim().toLowerCase());

  const likelySector =
    typeof parsed.likely_sector === "string" && parsed.likely_sector.trim()
      ? parsed.likely_sector.trim()
      : answers.sector ?? null;

  return {
    skills: extractedSkills.map((s) => s.label),
    tools: answers.tools ?? [],
    extracted_skills: extractedSkills,
    extracted_tasks: extractedTasks,
    likely_sector: likelySector,
    confidence: "llm",
    notes: [`llm_openrouter`],
    provider: "openrouter",
    model,
  };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Extract skills, tasks, and sector signal from Module1 intake answers.
 *
 * Uses OpenRouter when OPENROUTER_API_KEY is set;
 * otherwise falls back to deterministic heuristic extraction at zero cost.
 * LLM failures also fall back automatically — the pipeline never breaks.
 *
 * Returned shape is backward compatible with scorer.js `aiSignals` parameter.
 *
 * @param {object} answers - Module1 intake answers
 * @returns {Promise<object>}
 */
export async function extractSkills(answers) {
  if (!process.env.OPENROUTER_API_KEY) {
    console.info("[llm-extractor] No OPENROUTER_API_KEY — running heuristic extraction.");
    return heuristicExtract(answers);
  }

  console.info(`[llm-extractor] LLM extraction starting (cascade: ${getModelCascade().join(" → ")}, timeout=${LLM_TIMEOUT_MS}ms)`);
  try {
    const result = await callLLM(answers);
    console.info(`[llm-extractor] LLM extraction succeeded — provider=${result.provider}`);
    return result;
  } catch (err) {
    console.warn(
      `[llm-extractor] LLM call failed after ${LLM_TIMEOUT_MS}ms — falling back to heuristic. Reason: ${err.message}`
    );
    const fallback = heuristicExtract(answers);
    return {
      ...fallback,
      notes: [...fallback.notes, "llm_fallback_used"],
    };
  }
}
