const express = require("express");
const router = express.Router();
const GeocodingService = require("../service/geocodingService");

/// GET /api/geocode?lat=30.145&lng=31.64
/// Returns: {text: formatted_address, city: city_name}
router.get("/", async (req, res) => {
  try {
    const { lat, lng } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({
        message: "Please provide lat and lng parameters.",
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({
        message: "Invalid latitude or longitude.",
      });
    }

    const { text, city } = await GeocodingService.reverseGeocode(
      latitude,
      longitude,
    );

    res.status(200).json({
      success: true,
      text,
      city,
      location: { lat: latitude, lng: longitude },
    });
  } catch (error) {
    res.status(500).json({
      message: "Unable to geocode location. Please try again.",
    });
  }
});

module.exports = router;
