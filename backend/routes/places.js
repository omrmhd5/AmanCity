const express = require("express");
const router = express.Router();
const PlaceController = require("../controller/placeController");

// GET /api/places/nearby
router.get("/nearby", PlaceController.getNearbyPlaces);

// GET /api/places/search
router.get("/search", PlaceController.searchPlaces);

module.exports = router;
