const { askGemini } = require("../service/geminiService");
const IncidentService = require("../service/incidentService");

/**
 * POST /api/chat
 * Receives user message + location, fetches nearby incidents, passes to Gemini
 */
async function sendMessage(req, res) {
  const { message, latitude, longitude } = req.body;

  // Validate required fields
  if (!message || typeof message !== "string" || message.trim().length === 0) {
    return res.status(400).json({ message: "Message is required." });
  }

  console.log(`💬 Chat message received: "${message.slice(0, 50)}..."`);

  let nearbyIncidents = [];

  // If location provided, fetch nearby incidents for context
  if (latitude !== undefined && longitude !== undefined) {
    try {
      nearbyIncidents = await IncidentService.getNearbyIncidents(
        latitude,
        longitude,
        5, // 5 km radius
      );
      console.log(`🔍 Found ${nearbyIncidents.length} nearby incidents`);
    } catch (err) {
      console.warn("⚠️  Failed to fetch nearby incidents:", err.message);
      // Continue without incident context
    }
  } else {
    console.log("ℹ️  No location provided, sending query without context");
  }

  // Call Gemini with incident context
  try {
    const reply = await askGemini(message, nearbyIncidents);
    console.log(`✅ Gemini response generated`);

    return res.status(200).json({
      message: "Chat message processed successfully.",
      reply,
    });
  } catch (err) {
    console.error("❌ Gemini API error:", err.message);
    return res.status(503).json({
      message: "Unable to process your question. Please try again later.",
      error: err.message,
    });
  }
}

module.exports = { sendMessage };
