/**
 * Shared OpenRouter HTTP client with model cascade.
 *
 * Free-tier models on OpenRouter have strict per-model rate limits.
 * When the primary model returns HTTP 429, this client automatically
 * retries with the next model in the cascade — no manual intervention needed.
 *
 * Cascade: OPENROUTER_MODEL first, then diverse free models (different
 * upstream quotas), ending with openrouter/free which auto-routes to any
 * available free endpoint.
 */

const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";

const PRIMARY_MODEL = process.env.OPENROUTER_MODEL ?? "meta-llama/llama-3.3-70b-instruct:free";

// Diverse providers — avoids exhausting a single model family under 429.
// Slugs verified on OpenRouter free tier (Apr 2026); 404/429 skip to next.
const FALLBACK_MODELS = [
  "meta-llama/llama-3.3-70b-instruct:free",
  "google/gemma-3-27b-it:free",
  "google/gemma-3-12b-it:free",
  "google/gemma-3-4b-it:free",
  "google/gemma-2-9b-it:free",
  "mistralai/mistral-nemo:free",
  "mistralai/mistral-small-3.1-24b-instruct:free",
  "qwen/qwen3-4b:free",
  "qwen/qwen3-14b:free",
  "openai/gpt-oss-120b:free",
  "openrouter/free",
];

const MODEL_CASCADE = [
  PRIMARY_MODEL,
  ...FALLBACK_MODELS.filter((m) => m !== PRIMARY_MODEL),
];

export function getModelCascade() {
  return MODEL_CASCADE;
}

function buildCascade(preferred_model) {
  if (!preferred_model) return MODEL_CASCADE;
  return [preferred_model, ...MODEL_CASCADE.filter((m) => m !== preferred_model)];
}

/**
 * Google Gemma on OpenRouter rejects separate system messages ("Developer
 * instruction is not enabled"). Merge system prompts into the user turn.
 * Same merge for openrouter/free since the router may pick Gemma.
 */
function adaptMessagesForModel(model, messages) {
  const slug = model.toLowerCase();
  const mergeSystem =
    slug.includes("gemma") || model === "openrouter/free";
  if (!mergeSystem) return messages;

  const systemParts = messages.filter((x) => x.role === "system");
  const rest = messages.filter((x) => x.role !== "system");
  if (!systemParts.length) return messages;

  const sysText = systemParts.map((s) => s.content).join("\n\n");
  if (!rest.length) return [{ role: "user", content: sysText }];

  const [first, ...others] = rest;
  if (first.role === "user") {
    return [{ role: "user", content: `${sysText}\n\n${first.content}` }, ...others];
  }
  return [{ role: "user", content: sysText }, ...rest];
}

function extractMessageContent(message) {
  if (!message) return "";
  const c = message.content;
  if (typeof c === "string") return c;
  if (Array.isArray(c)) {
    return c.map((part) => (typeof part === "string" ? part : part?.text ?? "")).join("");
  }
  return "";
}

function withTimeout(promise, ms) {
  let timer;
  const deadline = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`LLM timeout after ${ms}ms`)), ms);
  });
  return Promise.race([promise, deadline]).finally(() => clearTimeout(timer));
}

/**
 * Call OpenRouter with automatic model cascade on 429.
 *
 * @param {object} params
 * @param {object[]} params.messages     - Chat messages array
 * @param {number}  params.max_tokens    - Max output tokens
 * @param {number}  params.timeout_ms    - Per-request timeout
 * @param {string}  params.referer_title - X-Title header for attribution
 * @param {string}  [params.log_prefix]  - Console prefix e.g. "[llm-extractor]"
 * @param {string}  [params.preferred_model] - Try this model first if provided
 * @returns {Promise<{ content: string, model: string }>}
 */
export async function callOpenRouter({ messages, max_tokens, timeout_ms, referer_title, log_prefix = "[llm-client]", preferred_model = null }) {
  const key = process.env.OPENROUTER_API_KEY;
  if (!key) throw new Error("OPENROUTER_API_KEY not set");

  for (const model of buildCascade(preferred_model)) {
    console.info(`${log_prefix} Trying model=${model}`);
    try {
      const adapted = adaptMessagesForModel(model, messages);
      const res = await withTimeout(
        fetch(OPENROUTER_API_URL, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${key}`,
            "Content-Type": "application/json",
            "HTTP-Referer": "https://unmapped.app",
            "X-Title": referer_title ?? "UNMAPPED",
          },
          body: JSON.stringify({
            model,
            max_tokens,
            // Free router may reject strict json_mode; omit for openrouter/free
            ...(model === "openrouter/free" ? {} : { response_format: { type: "json_object" } }),
            stream: false,
            messages: adapted,
          }),
        }),
        timeout_ms
      );

      // 429 / 404 — try next model (rate limit or no endpoint for this account)
      if (res.status === 429 || res.status === 404) {
        const body = await res.text().catch(() => "");
        console.warn(`${log_prefix} model=${model} HTTP ${res.status} — trying next. ${body.slice(0, 100)}`);
        continue;
      }

      if (!res.ok) {
        const body = await res.text().catch(() => "");
        throw new Error(`OpenRouter HTTP ${res.status}: ${body.slice(0, 200)}`);
      }

      const result = await res.json();
      if (result.error) {
        const msg = result.error.message ?? JSON.stringify(result.error);
        // Treat upstream rate-limit errors as 429 and cascade
        if (result.error.code === 429 || msg.toLowerCase().includes("rate-limit") || msg.toLowerCase().includes("rate limit")) {
          console.warn(`${log_prefix} model=${model} upstream rate-limited — trying next model.`);
          continue;
        }
        throw new Error(`OpenRouter error: ${msg}`);
      }

      const msg0 = result.choices?.[0]?.message;
      const content = extractMessageContent(msg0);
      if (!content.trim()) {
        console.warn(`${log_prefix} model=${model} returned empty content — trying next model.`);
        continue;
      }

      console.info(`${log_prefix} model=${model} succeeded.`);
      return { content, model };

    } catch (err) {
      // Timeout or network error — don't cascade, propagate
      if (err.message.includes("timeout") || err.message.includes("fetch")) {
        throw err;
      }
      // Other errors — log and try next
      console.warn(`${log_prefix} model=${model} failed: ${err.message} — trying next model.`);
    }
  }

  throw new Error(`All models in cascade exhausted (429/404/empty/errors).`);
}

/**
 * Sanitize LLM JSON output: strip markdown fences and fix control chars
 * inside string values (some models emit literal newlines in JSON strings).
 */
export function parseJsonResponse(raw) {
  const stripped = raw
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/, "")
    .trim();

  try {
    return JSON.parse(stripped);
  } catch {
    // Sanitize control chars inside JSON string literals only
    const sanitized = stripped.replace(/"(?:[^"\\]|\\.)*"/g, (s) =>
      s.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "")
       .replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\t/g, "\\t")
    );
    return JSON.parse(sanitized);
  }
}
