const express = require("express");
const rateLimit = require("express-rate-limit");
const { sendMessage } = require("../controller/chatController");

const router = express.Router();

// Rate limit: 20 requests per minute per IP
const chatLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    message: "Too many chat requests. Please wait a moment and try again.",
  },
});

// POST /api/chat/send
router.post("/send", chatLimiter, sendMessage);

module.exports = router;
