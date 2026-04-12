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
      throw new Error(
        "The image analysis service is temporarily unavailable. Please try again in a few moments.",
      );
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
          timeout: 180000, // 3 minutes for inference (crime detection processes multiple frames)
        },
      );

      return response.data;
    } catch (error) {
      // Handle specific error cases
      if (error.code === "ECONNREFUSED") {
        throw new Error(
          "The image analysis service is not running. Please contact support.",
        );
      }
      if (error.response?.status === 413) {
        throw new Error(
          "The image file is too large. Please use a smaller file.",
        );
      }
      if (error.code === "EAXIOS" || error.message?.includes("timeout")) {
        throw new Error(
          "The analysis took too long. Please try again with a different image.",
        );
      }
      throw new Error(
        "Unable to analyze the image. Please ensure it is a valid photo or video file.",
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
          timeout: 180000, // 3 minutes for batch (multiple videos can take time)
        },
      );

      return response.data;
    } catch (error) {
      if (error.code === "ECONNREFUSED") {
        throw new Error(
          "The image analysis service is not running. Please contact support.",
        );
      }
      throw new Error(
        "Unable to analyze the images. Please ensure all files are valid photos or videos.",
      );
    }
  }
}

module.exports = YOLOService;
