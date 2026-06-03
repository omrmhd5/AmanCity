const PlacePhone = require("../model/PlacePhone");

/// Google Places API types mapping
const PLACE_TYPES_MAP = {
  hospital: "hospital",
  police: "police",
  fire: "fire_station",
};

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

class PlaceService {
  /**
   * Search for general places using Google Places API Text Search.
   */
  static async searchGeneralPlaces(query, latitude, longitude, radius = 5000, maxResults = 20) {
    console.log(`[DEBUG] API call: Google Places Text Search for "${query}"`);
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
          "places.displayName,places.formattedAddress,places.location,places.types,places.name",
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
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

  /**
   * Search for nearby places using searchNearby endpoint.
   */
  static async searchNearbyPlaces(latitude, longitude, searchTypes, radius = 5000) {
    console.log(
      `[DEBUG] API call: Google Places Nearby Search for types=${searchTypes.join(",")} at (${latitude}, ${longitude})`,
    );
    if (!GOOGLE_API_KEY) {
      throw new Error(
        "Location services are not configured. Please contact support.",
      );
    }

    const url = "https://places.googleapis.com/v1/places:searchNearby";
    const maxResultsPerType = 20;

    const fetchForType = async (searchType) => {
      const googlePlaceType = PLACE_TYPES_MAP[searchType];
      if (!googlePlaceType) return [];

      const requestBody = {
        includedTypes: [googlePlaceType],
        maxResultCount: maxResultsPerType,
        locationRestriction: {
          circle: {
            center: { latitude, longitude },
            radius,
          },
        },
      };

      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": GOOGLE_API_KEY,
          "X-Goog-FieldMask":
            "places.displayName,places.formattedAddress,places.location,places.name,places.types",
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        throw new Error("Unable to retrieve nearby locations. Please try again.");
      }

      const data = await response.json();

      return (data.places || []).map((place) => ({
        id: place.name,
        name: place.displayName?.text || place.name || "Unknown",
        lat: place.location?.latitude || 0,
        lng: place.location?.longitude || 0,
        address: place.formattedAddress || "",
        phoneNumber: null,
        type: searchType, // our internal type (hospital, police, fire)
      }));
    };

    const results = await Promise.all(searchTypes.map(fetchForType));
    return results.flat();
  }

  /**
   * Fetch, sort, and enrich nearby places with database phone numbers.
   */
  static async getNearbyPlacesEnriched(latitude, longitude, type, radius = 5000) {
    // Determine search types
    let searchTypes = [];
    if (type === "all") {
      searchTypes = ["hospital", "police", "fire"];
    } else if (type.includes("|")) {
      searchTypes = type.split("|").filter((t) => PLACE_TYPES_MAP[t]);
    } else if (PLACE_TYPES_MAP[type]) {
      searchTypes = [type];
    } else {
      throw new Error(
        "The selected location type is not recognized. Please select a valid type.",
      );
    }

    // Fetch all place types in a single API call
    let allPlaces = [];
    try {
      allPlaces = await this.searchNearbyPlaces(
        latitude,
        longitude,
        searchTypes,
        radius,
      );
    } catch (error) {
      // API call failed - return empty or propagate
      console.error("[PlaceService] searchNearbyPlaces failed:", error.message);
      throw error;
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

    // Enrich with phone numbers from DB (cheap lookup, no API cost)
    const placeIds = allPlaces.map((p) => p.id);
    const phoneRecords = await PlacePhone.find(
      { placeId: { $in: placeIds } },
      { placeId: 1, phoneNumber: 1, _id: 0 },
    ).lean();
    const phoneMap = Object.fromEntries(
      phoneRecords.map((r) => [r.placeId, r.phoneNumber]),
    );

    return allPlaces.map((p) => ({
      ...p,
      phoneNumber: phoneMap[p.id] ?? null,
    }));
  }
}

module.exports = PlaceService;
