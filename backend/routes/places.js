const express = require("express");
const router = express.Router();

/// Google Places API types mapping
const PLACE_TYPES_MAP = {
  hospital: "hospital",
  police: "police",
  fire: "fire_station",
};

/// Google Places API key from environment
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

/// Validate API key is configured
if (!GOOGLE_API_KEY) {
  console.warn(
    "⚠️ WARNING: GOOGLE_API_KEY not found in environment variables. Places API will not work.",
  );
}

/// GET /api/places/nearby
/// Query: lat, lng, type (hospital|police|fire|all)
/// Returns: Array of nearby places with {id, name, lat, lng, address, rating, type}
router.get("/nearby", async (req, res) => {
  try {
    const { lat, lng, type = "all" } = req.query;

    // Validate input
    if (!lat || !lng) {
      return res.status(400).json({
        message: "Missing required parameters: lat, lng",
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({
        message: "Invalid latitude/longitude values",
      });
    }

    // Determine search types
    let searchTypes = [];
    if (type === "all") {
      searchTypes = ["hospital", "police", "fire"];
    } else if (type.includes("|")) {
      searchTypes = type.split("|").filter((t) => PLACE_TYPES_MAP[t]);
    } else if (PLACE_TYPES_MAP[type]) {
      searchTypes = [type];
    } else {
      return res.status(400).json({
        message: "Invalid type. Must be: hospital, police, fire, or all",
      });
    }

    // Fetch places for each type
    const allPlaces = [];

    for (const searchType of searchTypes) {
      try {
        const places = await searchNearbyPlaces(
          latitude,
          longitude,
          searchType,
        );
        allPlaces.push(...places);
      } catch (error) {
        console.warn(`⚠️ Error fetching ${searchType} places:`, error.message);
        // Continue with other types even if one fails
      }
    }

    // Sort by distance (closest first) - using simple lat/lng distance
    allPlaces.sort((a, b) => {
      const distA = Math.sqrt(
        Math.pow(a.lat - latitude, 2) + Math.pow(a.lng - longitude, 2),
      );
      const distB = Math.sqrt(
        Math.pow(b.lat - latitude, 2) + Math.pow(b.lng - longitude, 2),
      );
      return distA - distB;
    });

    res.status(200).json({
      success: true,
      count: allPlaces.length,
      userLocation: { lat: latitude, lng: longitude },
      places: allPlaces,
    });
  } catch (error) {
    console.error("❌ Places API error:", error.message);
    res.status(500).json({
      message: "Failed to fetch nearby places",
      error: error.message,
    });
  }
});

/// Helper function to search nearby places
/// Uses Google Places API searchNearby endpoint
async function searchNearbyPlaces(latitude, longitude, type) {
  if (!GOOGLE_API_KEY) {
    throw new Error(
      "Google API key not configured. Set GOOGLE_API_KEY environment variable.",
    );
  }

  const googlePlaceType = PLACE_TYPES_MAP[type];
  if (!googlePlaceType) {
    throw new Error(`Unknown place type: ${type}`);
  }

  const url = "https://places.googleapis.com/v1/places:searchNearby";

  const requestBody = {
    includedTypes: [googlePlaceType],
    maxResultCount: 20,
    locationRestriction: {
      circle: {
        center: {
          latitude: latitude,
          longitude: longitude,
        },
        radius: 5000,
      },
    },
  };

  console.log(
    `📍 Searching for ${type} places around (${latitude}, ${longitude})`,
  );
  console.log("Request body:", JSON.stringify(requestBody, null, 2));

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": GOOGLE_API_KEY,
      "X-Goog-FieldMask":
        "places.displayName,places.formattedAddress,places.location,places.rating,places.internationalPhoneNumber,places.nationalPhoneNumber,places.websiteUri,places.name",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorData = await response.json();
    console.error(
      `❌ Google Places API error response:`,
      JSON.stringify(errorData, null, 2),
    );
    throw new Error(
      `Google Places API error: ${response.status} - ${errorData.error?.message || "Unknown error"}`,
    );
  }

  const data = await response.json();

  console.log(`✅ Got ${data.places?.length || 0} places`);

  // Map Google Places API response to our format
  return (data.places || []).map((place) => ({
    id: place.name, // Google returns full resource name like "places/ChIJ..."
    name: place.displayName?.text || place.name || "Unknown",
    lat: place.location?.latitude || 0,
    lng: place.location?.longitude || 0,
    address: place.formattedAddress || "",
    rating: place.rating || null,
    phoneNumber:
      place.internationalPhoneNumber || place.nationalPhoneNumber || null,
    type: type, // Our internal type (hospital, police, fire)
    websiteUrl: place.websiteUri || null,
  }));
}

module.exports = router;
