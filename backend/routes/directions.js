const express = require("express");
const router = express.Router();
const DirectionsController = require("../controller/directionsController");

// GET /api/directions
router.get("/", DirectionsController.getDirections);

module.exports = router;
