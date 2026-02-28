const express = require("express");
const upload = require("../middleware/uploadMiddleware");
const PredictController = require("../controller/predictController");

const router = express.Router();

// Health check
router.get("/health", PredictController.checkYOLOHealth);

// Predict
router.post("/", upload.single("file"), PredictController.predictOnly);

module.exports = router;
