const PlaceService = require("../service/placeService");

class PlaceController {
  /**
   * GET /api/places/nearby
   * Query: lat, lng, type (hospital|police|fire|all), radius (meters, default 5000)
   */
  static async getNearbyPlaces(req, res) {
    const { lat, lng, type = "all", radius = "5000" } = req.query;

    try {
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

      const enrichedPlaces = await PlaceService.getNearbyPlacesEnriched(
        latitude,
        longitude,
        type,
        searchRadius,
      );

      res.status(200).json({
        success: true,
        count: enrichedPlaces.length,
        userLocation: { lat: latitude, lng: longitude },
        searchRadius: searchRadius,
        places: enrichedPlaces,
      });
    } catch (error) {
      res.status(500).json({
        message: error.message || "Unable to find nearby locations. Please try again later.",
      });
    }
  }

  /**
   * GET /api/places/search
   * Query: query (search text), lat, lng, radius (optional, meters, default 5000)
   */
  static async searchPlaces(req, res) {
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

      const places = await PlaceService.searchGeneralPlaces(
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
        message: error.message || "Search failed. Please try again later.",
      });
    }
  }
}

module.exports = PlaceController;
