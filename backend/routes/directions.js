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

    // Call Google Directions API
    const url = new URL("https://maps.googleapis.com/maps/api/directions/json");
    url.searchParams.append("origin", `${originLat},${originLng}`);
    url.searchParams.append("destination", `${destLat},${destLng}`);
    url.searchParams.append("mode", "driving");
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
    const route = data.routes[0];
    const leg = route.legs[0];

    res.status(200).json({
      success: true,
      polyline: route.overview_polyline.points,
      distance: {
        text: leg.distance.text,
        value: leg.distance.value, // meters
      },
      duration: {
        text: leg.duration.text,
        value: leg.duration.value, // seconds
      },
      startAddress: leg.start_address,
      endAddress: leg.end_address,
      bounds: route.bounds,
    });
  } catch (error) {
    res.status(500).json({
      message: "Unable to calculate route. Please try again later.",
    });
  }
});

module.exports = router;
