const express = require("express");
const rateLimit = require("express-rate-limit");
const { scanOsint } = require("../controller/osintController");

const router = express.Router();

// Protect the scan endpoint — Grok API calls are expensive
const scanLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    message:
      "Too many scan requests. You can trigger a maximum of 5 scans per hour.",
  },
});

// POST /api/osint/scan
router.post("/scan", scanLimiter, scanOsint);

module.exports = router;
