const multer = require("multer");
const path = require("path");

// Configure multer for file uploads
const storage = multer.memoryStorage(); // Store in memory for quick processing

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    const filename = file.originalname.toLowerCase();
    const mimeType = file.mimetype.toLowerCase();

    // Allow only images (JPG, PNG) and MP4 videos
    const isImage =
      (mimeType.startsWith("image/") ||
        mimeType === "application/octet-stream") &&
      (filename.endsWith(".jpg") ||
        filename.endsWith(".jpeg") ||
        filename.endsWith(".png"));
    const isMp4 =
      (mimeType === "video/mp4" ||
        mimeType === "application/octet-stream" ||
        filename.endsWith(".mp4")) &&
      filename.endsWith(".mp4");

    if (isImage || isMp4) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `Invalid file type. Please upload an image (JPG/PNG) or MP4 video file only.`,
        ),
      );
    }
  },
});

module.exports = upload;
