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
  // API key missing - will be handled at request time
}

/// GET /api/places/nearby
/// Query: lat, lng, type (hospital|police|fire|all), radius (meters, default 5000)
/// Returns: Array of nearby places with {id, name, lat, lng, address, rating, type}
router.get("/nearby", async (req, res) => {
  try {
    const { lat, lng, type = "all", radius = "5000" } = req.query;

    // Validate input
    if (!lat || !lng) {
      return res.status(400).json({
        message:
          "Unable to determine location. Please enable location services and try again.",
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const searchRadius = parseInt(radius);
    const maxResults = 20; // Fixed at 20

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({
        message: "The location coordinates are invalid. Please try again.",
      });
    }

    if (isNaN(searchRadius) || searchRadius < 100 || searchRadius > 50000) {
      return res.status(400).json({
        message:
          "The search radius is invalid. Please select a radius between 1 and 25 km.",
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
    } else if (searchTypes.length === 0 || !PLACE_TYPES_MAP[type]) {
      return res.status(400).json({
        message:
          "The selected location type is not recognized. Please select a valid type.",
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
          searchRadius,
        );
        allPlaces.push(...places);
      } catch (error) {
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
      searchRadius: searchRadius,
      places: allPlaces,
    });
  } catch (error) {
    res.status(500).json({
      message: "Unable to find nearby locations. Please try again later.",
    });
  }
});

/// GET /api/places/search
/// Query: query (search text), lat, lng, radius (optional, meters, default 5000)
/// Returns: Array of places (both POIs and general places) with type classification
router.get("/search", async (req, res) => {
  try {
    const { query, lat, lng, radius = "5000" } = req.query;

    // Validate input
    if (!query || query.trim().length === 0) {
      return res.status(400).json({
        message: "Search query is required.",
      });
    }

    if (!lat || !lng) {
      return res.status(400).json({
        message:
          "Unable to determine location. Please enable location services and try again.",
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const searchRadius = parseInt(radius);
    const maxResults = 20;

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({
        message: "The location coordinates are invalid. Please try again.",
      });
    }

    // Search using Google Places API Text Search
    const places = await searchGeneralPlaces(
      query,
      latitude,
      longitude,
      searchRadius,
      maxResults,
    );

    res.status(200).json({
      success: true,
      count: places.length,
      userLocation: { lat: latitude, lng: longitude },
      searchRadius: searchRadius,
      places: places,
    });
  } catch (error) {
    res.status(500).json({
      message: "Search failed. Please try again later.",
    });
  }
});

/// Helper function to search for general places
/// Uses Google Places API Text Search
async function searchGeneralPlaces(
  query,
  latitude,
  longitude,
  radius = 5000,
  maxResults = 20,
) {
  if (!GOOGLE_API_KEY) {
    throw new Error(
      "Location services are not configured. Please contact support.",
    );
  }

  const url = "https://places.googleapis.com/v1/places:searchText";

  const requestBody = {
    textQuery: query,
    maxResultCount: maxResults,
    locationBias: {
      circle: {
        center: {
          latitude: latitude,
          longitude: longitude,
        },
        radius: radius,
      },
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": GOOGLE_API_KEY,
      "X-Goog-FieldMask":
        "places.displayName,places.formattedAddress,places.location,places.nationalPhoneNumber,places.types,places.name",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error("Unable to search for places. Please try again.");
  }

  const data = await response.json();

  // Map Google Places API response to our format
  return (data.places || []).map((place) => {
    // Determine if this is a POI type we recognize
    let poiType = null;
    const types = place.types || [];

    if (types.includes("hospital")) {
      poiType = "hospital";
    } else if (types.includes("police")) {
      poiType = "police";
    } else if (types.includes("fire_station")) {
      poiType = "fire";
    }

    return {
      id: place.name,
      name: place.displayName?.text || place.name || "Unknown",
      lat: place.location?.latitude || 0,
      lng: place.location?.longitude || 0,
      address: place.formattedAddress || "",
      phoneNumber: place.nationalPhoneNumber || null,
      type: poiType, // null for generic places, "hospital"/"police"/"fire" for POIs
      googleTypes: types, // Store original Google types for reference
    };
  });
}
/// Uses Google Places API searchNearby endpoint
async function searchNearbyPlaces(latitude, longitude, type, radius = 5000) {
  if (!GOOGLE_API_KEY) {
    throw new Error(
      "Location services are not configured. Please contact support.",
    );
  }

  const maxResults = 20; // Fixed at 20 results per type

  const googlePlaceType = PLACE_TYPES_MAP[type];
  if (!googlePlaceType) {
    throw new Error("The selected location type is not recognized.");
  }

  const url = "https://places.googleapis.com/v1/places:searchNearby";

  const requestBody = {
    includedTypes: [googlePlaceType],
    maxResultCount: maxResults,
    locationRestriction: {
      circle: {
        center: {
          latitude: latitude,
          longitude: longitude,
        },
        radius: radius,
      },
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": GOOGLE_API_KEY,
      "X-Goog-FieldMask":
        "places.displayName,places.formattedAddress,places.location,places.nationalPhoneNumber,places.name",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error("Unable to retrieve nearby locations. Please try again.");
  }

  const data = await response.json();

  // Map Google Places API response to our format
  return (data.places || []).map((place) => ({
    id: place.name, // Google returns full resource name like "places/ChIJ..."
    name: place.displayName?.text || place.name || "Unknown",
    lat: place.location?.latitude || 0,
    lng: place.location?.longitude || 0,
    address: place.formattedAddress || "",
    phoneNumber: place.nationalPhoneNumber || null,
    type: type, // Our internal type (hospital, police, fire)
  }));
}

module.exports = router;
