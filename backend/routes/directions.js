const express = require("express");
const router = express.Router();

/// Google Directions API key from environment
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

/// GET /api/directions
/// Query: origin_lat, origin_lng, dest_lat, dest_lng
/// Returns: {success, distance, duration, polyline, bounds}
router.get("/", async (req, res) => {
  try {
    const { origin_lat, origin_lng, dest_lat, dest_lng } = req.query;

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

    if (!GOOGLE_API_KEY) {
      return res.status(500).json({
        message: "Navigation service not configured. Please try again later.",
      });
    }

    // Call Google Directions API with alternatives=true for safe route scoring
    const url = new URL("https://maps.googleapis.com/maps/api/directions/json");
    url.searchParams.append("origin", `${originLat},${originLng}`);
    url.searchParams.append("destination", `${destLat},${destLng}`);
    url.searchParams.append("mode", "driving");
    url.searchParams.append("alternatives", "true"); // Get up to 3 alternative routes
    url.searchParams.append("key", GOOGLE_API_KEY);

    const response = await fetch(url.toString());

    if (!response.ok) {
      return res.status(500).json({
        message: "Unable to calculate route. Please try again.",
      });
    }

    const data = await response.json();

    if (data.status !== "OK") {
      return res.status(400).json({
        message:
          data.status === "ZERO_RESULTS"
            ? "No route found between these locations."
            : "Unable to calculate route. Please try again.",
      });
    }

    // Extract route data
    const primaryRoute = data.routes[0];
    const primaryLeg = primaryRoute.legs[0];

    // Extract all routes for safe route scoring
    const allRoutes = data.routes.map((route) => {
      const leg = route.legs[0];
      return {
        polyline: route.overview_polyline.points,
        distance: {
          text: leg.distance.text,
          value: leg.distance.value,
        },
        duration: {
          text: leg.duration.text,
          value: leg.duration.value,
        },
        startAddress: leg.start_address,
        endAddress: leg.end_address,
        bounds: route.bounds,
      };
    });

    res.status(200).json({
      success: true,
      // Backwards compatibility: primary route at top level
      polyline: primaryRoute.overview_polyline.points,
      distance: {
        text: primaryLeg.distance.text,
        value: primaryLeg.distance.value,
      },
      duration: {
        text: primaryLeg.duration.text,
        value: primaryLeg.duration.value,
      },
      startAddress: primaryLeg.start_address,
      endAddress: primaryLeg.end_address,
      bounds: primaryRoute.bounds,
      // All routes for safe route calculation
      routes: allRoutes,
    });
  } catch (error) {
    res.status(500).json({
      message: "Unable to calculate route. Please try again later.",
    });
  }
});

module.exports = router;
