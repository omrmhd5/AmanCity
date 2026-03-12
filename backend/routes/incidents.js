const express = require("express");
const upload = require("../middleware/uploadMiddleware");
const IncidentController = require("../controller/incidentController");

const router = express.Router();

// Create incident with file upload
router.post("/", upload.single("file"), IncidentController.createIncident);

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
