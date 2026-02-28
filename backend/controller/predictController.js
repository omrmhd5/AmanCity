const YOLOService = require("../service/yoloService");

class PredictController {
  // Just run inference without creating incident
  // POST /api/predict/inference-only
  static async predictOnly(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          message: "No file uploaded",
        });
      }

      const prediction = await YOLOService.predictFromBuffer(
        req.file.buffer,
        req.file.originalname,
      );

      res.status(200).json({
        message: "Prediction successful",
        data: prediction,
      });
    } catch (error) {
      console.error("Inference error:", error);
      res.status(500).json({
        message: error.message || "Inference failed",
      });
    }
  }

  // Health check for YOLO server
  // GET /api/predict/health
  static async checkYOLOHealth(req, res) {
    try {
      const health = await YOLOService.checkHealth();
      res.status(200).json({
        message: "YOLO server health check",
        data: health,
      });
    } catch (error) {
      res.status(503).json({
        message: "YOLO server unavailable",
        error: error.message,
      });
    }
  }
}

module.exports = PredictController;
