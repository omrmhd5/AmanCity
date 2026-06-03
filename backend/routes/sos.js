const express = require("express");
const router = express.Router();
const SosController = require("../controller/sosController");

// POST /api/sos/sessions
router.post("/sessions", SosController.createSession);

// PATCH /api/sos/sessions/:id/location
router.patch("/sessions/:id/location", SosController.updateLocation);

// PATCH /api/sos/sessions/:id/end
router.patch("/sessions/:id/end", SosController.endSession);

// GET /api/sos/sessions/:id
router.get("/sessions/:id", SosController.getSession);

module.exports = router;
