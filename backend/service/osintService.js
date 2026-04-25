// OSINT Grok Radar Service
// Scans X (Twitter) for real-time safety emergencies in Greater Cairo
// Uses @ai-sdk/xai via dynamic import (ESM package in CommonJS project)

const SYSTEM_RULES = `You are an automated OSINT intelligence officer for the AmanCity urban safety platform. 
Your ONLY job is to analyze the X (Twitter) search results you gather and format them strictly as a JSON array.

**Instructions for Output:**
1. You MUST map the incident to one of these exact English categories for the type field: ["Accident", "Damaged Building", "Fire", "Flood", "Public Issue", "Road Damage", "Firearm", "Cold Weapon", "Arrest", "Arson", "Assault", "Burglary", "Explosion", "Fighting", "Robbery", "Shooting", "Shoplifting", "Stealing", "Vandalism"].
2. Keep the location_text in the original Arabic.
3. If they mention a specific neighborhood or landmark, set location_precision to "EXACT". If they only mention a vague area or a massive highway (e.g., "الدائري"), set location_precision to "VAGUE".
4. Estimate a severity score from 0.0 to 1.0.
5. CRITICAL: You must extract the direct URL of the exact tweet(s) you used to verify this incident and include them in a "source_urls" array.

**Output Format:**
[{"title": "string", "type": "ExactEnumString", "location_text": "Arabic text", "location_precision": "EXACT" | "VAGUE", "severity": 0.8, "source_urls": ["https://x.com/..."]}]

If there are no emergencies, output []. Do not output any conversational text or markdown blocks outside of the JSON.`;

const SEARCH_PROMPT = `Please search X (Twitter) for posts from the last 48 hours reporting real-time safety emergencies like car accidents, massive fires, severe road damage, floods, or violent fights. 

Target Areas to search: Greater Cairo, Giza, Nasr City, Maadi, Heliopolis, 6th of October, Sheikh Zayed, Haram, Shubra, Imbaba, New Cairo, El Shorouk, Madinaty, Al Rehab, Obour City, Badr City, the Ring Road, Suez Road, and Ismailia Road.`;

// Strip markdown code fences that LLMs often wrap around JSON
function sanitizeJson(raw) {
  return raw.replace(/```json\n?|\n?```/g, "").trim();
}

// Run a Grok OSINT scan on X (Twitter) for Cairo safety emergencies
async function runGrokScan() {
  if (!process.env.XAI_API_KEY) {
    throw new Error("XAI_API_KEY is not set in environment variables.");
  }

  // Dynamic import required: @ai-sdk/xai and ai are ESM-only packages
  const { xai } = await import("@ai-sdk/xai");
  const { generateText } = await import("ai");

  const { text, sources } = await generateText({
    model: xai.responses("grok-4.20-reasoning"),
    system: SYSTEM_RULES,
    prompt: SEARCH_PROMPT,
    maxSteps: 5,
    tools: {
      x_search: xai.tools.xSearch({
        enableImageUnderstanding: true,
        enableVideoUnderstanding: true,
      }),
    },
  });

  const cleanText = sanitizeJson(text);

  let incidents;
  try {
    incidents = JSON.parse(cleanText);
  } catch (parseError) {
    throw new Error(
      `Grok returned non-parseable output. Raw: ${text.slice(0, 200)}`,
    );
  }

  if (!Array.isArray(incidents)) {
    throw new Error("Grok output was not a JSON array.");
  }

  return { incidents, sources: sources || [] };
}

module.exports = { runGrokScan };
