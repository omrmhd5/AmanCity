const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files with proper headers for video streaming
app.use(
  express.static("uploads", {
    setHeaders: (res, path) => {
      // Enable range requests for MP4 video files
      if (path.endsWith(".mp4")) {
        res.setHeader("Accept-Ranges", "bytes");
        res.setHeader("Content-Type", "video/mp4");
        res.setHeader("Cache-Control", "public, max-age=3600");
      }
    },
  }),
);

// Routes
app.use("/api/incidents", require("./routes/incidents"));
app.use("/api/predict", require("./routes/predict"));
app.use("/api/places", require("./routes/places"));
app.use("/api/geocode", require("./routes/geocode"));
app.use("/api/directions", require("./routes/directions"));
app.use("/api/hotspots", require("./routes/hotspots"));
app.use("/api/osint", require("./routes/osint"));
app.use("/api/chat", require("./routes/chat"));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);

  // Check for multer file size error
  if (err.code === "LIMIT_FILE_SIZE") {
    return res.status(413).json({
      message: "The file is too large. Please use a smaller file (max 100MB).",
    });
  }

  // Check for multer file type error from uploadMiddleware
  if (err.message && err.message.includes("Please upload a valid")) {
    return res.status(400).json({ message: err.message });
  }

  // Default generic error
  res
    .status(500)
    .json({ message: "An unexpected error occurred. Please try again." });
});

module.exports = app;
