const express = require("express");
const BulkIncidentController = require("../controller/bulkIncidentController");

const router = express.Router();

// Get all bulk incidents (with optional bbox query params)
router.get("/", BulkIncidentController.getBulkIncidents);

// Get single bulk incident with all sub-incidents populated
router.get("/:id", BulkIncidentController.getBulkIncidentById);

module.exports = router;
