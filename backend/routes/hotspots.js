const express = require("express");
const HotspotController = require("../controller/hotspotController");

const router = express.Router();

// GET /api/hotspots - Get current predicted hotspots (cached)
router.get("/", HotspotController.getHotspots);

// POST /api/hotspots/recalculate - Manually trigger recalculation
router.post("/recalculate", HotspotController.recalculateHotspots);

module.exports = router;
