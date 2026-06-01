const express = require("express");
const router = express.Router();
const { getDashboard } = require("../controller/authorityController");

// GET /api/authority/dashboard
router.get("/dashboard", getDashboard);

module.exports = router;
