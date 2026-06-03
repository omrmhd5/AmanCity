// Gemini Service — Conversational Safety Assistant
// Uses @google/generative-ai to answer user questions with live incident context

const { GoogleGenerativeAI } = require("@google/generative-ai");

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.1-flash-lite";

const SYSTEM_PROMPT = `You are the Safety Assistant for AmanCity, an urban safety platform for Greater Cairo. 
Your role is to provide accurate, helpful safety information based on REAL DATA from the platform.

**CRITICAL RULES:**
1. You are NOT a general chatbot. You answer ONLY safety-related questions about Cairo and surrounding areas.
2. You NEVER invent incidents or data. You use ONLY the incident data provided in context. If no relevant data is provided, say so explicitly.
3. When given incident context (JSON array of recent incidents), analyze it and provide factual, location-specific safety insights.
4. If asked about an area with incidents nearby, reference them directly: "Based on 3 recent reports in your area..."
5. Always encourage users to call 122 for emergencies or use the app to report new incidents.
6. Keep responses concise (2-3 sentences max) unless asked for details.
7. If you're unsure about safety data for a location, admit it: "I don't have recent safety data for that area."
8. If the user asks for the safest route home but has no home location set (indicated in the message), politely instruct them to set their home location in the Settings (under the Profile tab) first so we can calculate the safest route for them.
9. **LANGUAGE RULE (MANDATORY):** You MUST always reply in the SAME language the user wrote in. If the user writes in Arabic, your ENTIRE response must be in Arabic. If they write in English, reply in English. Never mix languages. Never default to English when the user writes in Arabic.

**Example responses:**
- Safe: "Nasr City is currently SAFE. I have no incident reports in the last 24 hours from your immediate area."
- Caution: "I found 2 recent incidents near Maadi Metro: a traffic accident 30 min ago and a minor street incident 2 hours ago. Stay alert in that zone."
- Emergency: "If this is an emergency, call 122 immediately. You can also use the app's emergency button for quick response."
- Arabic example: "منطقتك آمنة حالياً. لا توجد حوادث مُبلَّغ عنها في آخر 24 ساعة بالقرب منك."`;


/**
 * Ask Gemini a safety question with live incident context
 * @param {string} userMessage - User's question
 * @param {Array} nearbyIncidents - Array of incident objects from MongoDB
 * @returns {Promise<string>} - Gemini's response text
 */
async function askGemini(userMessage, nearbyIncidents = []) {
  if (!GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not set in environment variables.");
  }

  const client = new GoogleGenerativeAI(GEMINI_API_KEY);
  const model = client.getGenerativeModel({ model: GEMINI_MODEL });

  // Format incident context for Gemini
  let incidentContext = "";
  if (nearbyIncidents && nearbyIncidents.length > 0) {
    const formattedIncidents = nearbyIncidents
      .slice(0, 10) // Limit to 10 most recent
      .map((incident, i) => {
        const typeStr = incident.type?.type || "Unknown";
        const locationStr = incident.location?.text || "Unknown location";
        const source = incident.source || "User Report";
        const timeAgo = getTimeAgo(incident.timestamp);
        return `${i + 1}. ${typeStr} at ${locationStr} (${timeAgo}, ${source}, confidence: ${incident.osintConfidence || incident.confidence || 0})`;
      })
      .join("\n");

    incidentContext = `\n\n**LIVE INCIDENT DATA (Recent incidents in/near user's area):**\n${formattedIncidents}`;
  } else {
    incidentContext =
      "\n\n**LIVE INCIDENT DATA:** No recent incidents in the user's area.";
  }

  // Detect user language and add explicit reply-language instruction
  const containsArabic = /[\u0600-\u06FF]/.test(userMessage);
  const languageInstruction = containsArabic
    ? "\n\n[IMPORTANT: The user wrote in Arabic. You MUST reply entirely in Arabic.]"
    : "\n\n[IMPORTANT: The user wrote in English. You MUST reply entirely in English.]";

  // Build the full user message with context
  const fullMessage =
    userMessage +
    incidentContext +
    languageInstruction +
    "\n\nProvide a safety-focused response based on the above data.";

  try {
    const result = await model.generateContent({
      contents: [
        {
          role: "user",
          parts: [{ text: fullMessage }],
        },
      ],
      systemInstruction: SYSTEM_PROMPT,
    });

    const response = result.response.text();
    return response;
  } catch (error) {
    throw new Error(`Gemini API error: ${error.message}`);
  }
}

/**
 * Format time difference (e.g., "30 minutes ago")
 * @param {Date} timestamp
 * @returns {string}
 */
function getTimeAgo(timestamp) {
  if (!timestamp) return "unknown time";

  const now = new Date();
  const diff = Math.floor((now - new Date(timestamp)) / 1000); // seconds

  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

module.exports = { askGemini };
