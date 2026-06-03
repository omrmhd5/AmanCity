const DirectionsService = require("../service/directionsService");

class DirectionsController {
  /**
   * GET /api/directions
   * Query: origin_lat, origin_lng, dest_lat, dest_lng
   */
  static async getDirections(req, res) {
    const { origin_lat, origin_lng, dest_lat, dest_lng } = req.query;

    try {
      // Validate input
      if (!origin_lat || !origin_lng || !dest_lat || !dest_lng) {
        return res.status(400).json({
          message: "Please provide origin and destination coordinates.",
        });
      }

      const originLat = parseFloat(origin_lat);
      const originLng = parseFloat(origin_lng);
      const destLat = parseFloat(dest_lat);
      const destLng = parseFloat(dest_lng);

      if (
        isNaN(originLat) ||
        isNaN(originLng) ||
        isNaN(destLat) ||
        isNaN(destLng)
      ) {
        return res.status(400).json({
          message: "Invalid coordinates provided.",
        });
      }

      const routeResult = await DirectionsService.calculateRoutes(
        originLat,
        originLng,
        destLat,
        destLng,
      );

      res.status(200).json({
        success: true,
        ...routeResult,
      });
    } catch (error) {
      // Use 400 for input/Google API business errors (e.g. ZERO_RESULTS)
      const isValidationError = error.message.includes("No route found") || error.message.includes("coordinates");
      res.status(isValidationError ? 400 : 500).json({
        message: error.message || "Unable to calculate route. Please try again later.",
      });
    }
  }
}

module.exports = DirectionsController;
