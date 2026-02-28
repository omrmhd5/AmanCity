const axios = require("axios");

const PYTHON_SERVER_URL =
  process.env.PYTHON_SERVER_URL || "http://localhost:5001";

class YOLOService {
  // Check if Python inference server is available
  static async checkHealth() {
    try {
      const response = await axios.get(`${PYTHON_SERVER_URL}/health`, {
        timeout: 5000,
      });
      return response.data;
    } catch (error) {
      throw new Error(`YOLO Server unavailable: ${error.message}`);
    }
  }

  // Run inference on a single image/video file
  // fileBuffer: File buffer
  // filename: Original filename
  // Returns: {class_id, class_name, confidence}
  static async predictFromBuffer(fileBuffer, filename) {
    try {
      const formData = new FormData();
      const blob = new Blob([fileBuffer], { type: "application/octet-stream" });
      formData.append("file", blob, filename);

      const response = await axios.post(
        `${PYTHON_SERVER_URL}/predict`,
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
          timeout: 30000, // 30 seconds for inference
        },
      );

      return response.data;
    } catch (error) {
      throw new Error(
        `YOLO Prediction failed: ${error.response?.data?.detail || error.message}`,
      );
    }
  }

  // Run batch inference on multiple files
  // files: Array of {buffer, filename} objects
  // Returns: Array of predictions
  static async predictBatch(files) {
    try {
      const formData = new FormData();

      files.forEach((file) => {
        const blob = new Blob([file.buffer], {
          type: "application/octet-stream",
        });
        formData.append("files", blob, file.filename);
      });

      const response = await axios.post(
        `${PYTHON_SERVER_URL}/predict-batch`,
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
          timeout: 60000, // 60 seconds for batch
        },
      );

      return response.data;
    } catch (error) {
      throw new Error(
        `YOLO Batch Prediction failed: ${error.response?.data?.detail || error.message}`,
      );
    }
  }
}

module.exports = YOLOService;
