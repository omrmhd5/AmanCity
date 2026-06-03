const express = require("express");
const router = express.Router();
const GeocodeController = require("../controller/geocodeController");

// GET /api/geocode
router.get("/", GeocodeController.reverseGeocode);

module.exports = router;
