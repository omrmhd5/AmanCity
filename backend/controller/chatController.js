const { askGemini } = require("../service/geminiService");
const IncidentService = require("../service/incidentService");
const GeocodingService = require("../service/geocodingService");

// Egyptian cities and areas (matches OSINT target areas) - English + Arabic
const EGYPTIAN_CITIES = {
  // Nasr City
  "nasr city": "Nasr City",
  nasr: "Nasr City",
  "مدينة نصر": "Nasr City",
  نصر: "Nasr City",

  // Shorouk
  shorouk: "El Shorouk",
  "el shorouk": "El Shorouk",
  الشروق: "El Shorouk",

  // 6th of October
  "6 october": "6th of October",
  october: "6th of October",
  "6th october": "6th of October",
  أكتوبر: "6th of October",

  // Sheikh Zayed
  "sheikh zayed": "Sheikh Zayed",
  "الشيخ زايد": "Sheikh Zayed",
  زايد: "Sheikh Zayed",

  // Haram
  haram: "Haram",
  هرم: "Haram",

  // Helwan
  helwan: "Helwan",
  حلوان: "Helwan",

  // Giza
  giza: "Giza",
  جيزة: "Giza",

  // Zamalek
  zamalek: "Zamalek",
  زمالك: "Zamalek",

  // Heliopolis
  heliopolis: "Heliopolis",
  "مصر الجديدة": "Heliopolis",

  // Maadi
  maadi: "Maadi",
  المعادي: "Maadi",
  معادي: "Maadi",

  // Mohandessin
  mohandessin: "Mohandessin",
  المهندسين: "Mohandessin",
  "محرم بك": "Mohandessin",

  // Kasr El Nile
  "kasr el nile": "Kasr El Nile",
  "قصر النيل": "Kasr El Nile",

  // Downtown Cairo
  downtown: "Downtown Cairo",
  "downtown cairo": "Downtown Cairo",
  "وسط البلد": "Downtown Cairo",
  البلد: "Downtown Cairo",

  // Old Cairo
  "old cairo": "Old Cairo",
  "القاهرة القديمة": "Old Cairo",

  // Shubra
  shubra: "Shubra",
  شبرا: "Shubra",

  // Imbaba
  imbaba: "Imbaba",
  إمبابة: "Imbaba",
  امبابة: "Imbaba",

  // New Cairo
  "new cairo": "New Cairo",
  "القاهرة الجديدة": "New Cairo",

  // Madinaty
  madinaty: "Madinaty",
  مدينتي: "Madinaty",

  // Al Rehab
  "al rehab": "Al Rehab",
  rehab: "Al Rehab",
  الرحاب: "Al Rehab",

  // Obour City
  "obour city": "Obour City",
  obour: "Obour City",
  أبور: "Obour City",
  ابور: "Obour City",

  // Badr City
  "badr city": "Badr City",
  badr: "Badr City",
  بدر: "Badr City",

  // Ring Road
  "ring road": "Ring Road",
  daa2ery: "Ring Road",
  الدائري: "Ring Road",
  دائري: "Ring Road",

  // Suez Road
  "suez road": "Suez Road",
  "طريق السويس": "Suez Road",
  السويس: "Suez Road",

  // Ismailia Road
  "ismailia road": "Ismailia Road",
  "طريق الإسماعيلية": "Ismailia Road",
  الإسماعيلية: "Ismailia Road",
  اسماعيلية: "Ismailia Road",

  // Bulaq
  bulaq: "Bulaq",
  بولاق: "Bulaq",

  // Dokki
  dokki: "Dokki",
  الدقي: "Dokki",
  دقي: "Dokki",

  // Agouza
  agouza: "Agouza",
  العجوزة: "Agouza",
  اجوزة: "Agouza",

  // Cairo General
  cairo: "Cairo",
  "el cairo": "Cairo",
  القاهرة: "Cairo",
};

/**
 * Extract Egyptian city names from user message
 * @param {string} message
 * @returns {string|null} - City name if found, else null
 */
function extractLocationFromMessage(message) {
  const lowerMessage = message.toLowerCase();
  for (const [keyword, cityName] of Object.entries(EGYPTIAN_CITIES)) {
    if (lowerMessage.includes(keyword)) {
      return keyword; // Return the keyword so we use it for geocoding
    }
  }
  return null;
}

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
  let fetchLat = latitude;
  let fetchLng = longitude;

  // Try to extract location from message
  const mentionedLocation = extractLocationFromMessage(message);
  if (mentionedLocation) {
    console.log(`📍 Detected location mention: "${mentionedLocation}"`);
    try {
      const geocoded = await GeocodingService.forwardGeocode(mentionedLocation);
      if (geocoded) {
        fetchLat = geocoded.latitude;
        fetchLng = geocoded.longitude;
        console.log(
          `✅ Geocoded to: ${geocoded.text} (${fetchLat}, ${fetchLng})`,
        );
      }
    } catch (err) {
      console.warn("⚠️  Geocoding failed:", err.message);
      // Fall back to user location if available
    }
  }

  // Fetch nearby incidents for context
  if (fetchLat !== undefined && fetchLng !== undefined) {
    try {
      nearbyIncidents = await IncidentService.getNearbyIncidents(
        fetchLat,
        fetchLng,
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
