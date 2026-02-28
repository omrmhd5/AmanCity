const express = require("express");
const IncidentController = require("../controller/incidentController");

const router = express.Router();

// Create incident
router.post("/", IncidentController.createIncident);

// Get all incidents
router.get("/", IncidentController.getIncidents);

// Get nearby incidents
router.get(
  "/nearby/:latitude/:longitude",
  IncidentController.getNearbyIncidents,
);

// Get incidents by type
router.get("/type/:typeId", IncidentController.getIncidentsByType);

// Get incident by ID
router.get("/:id", IncidentController.getIncidentById);

// Update incident
router.patch("/:id", IncidentController.updateIncident);

// Delete incident
router.delete("/:id", IncidentController.deleteIncident);

module.exports = router;
