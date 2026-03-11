const multer = require("multer");
const path = require("path");

// Configure multer for file uploads
const storage = multer.memoryStorage(); // Store in memory for quick processing

// MIME type mapping from file extensions
const mimeTypeMap = {
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".mp4": "video/mp4",
  ".mov": "video/quicktime",
  ".mpeg": "video/mpeg",
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      "image/jpeg",
      "image/png",
      "image/jpg",
      "video/mp4",
      "video/x-mpeg",
      "video/quicktime",
      "application/octet-stream", // Accept generic binary (will validate by extension)
    ];

    // If MIME type is generic, try to detect from file extension
    const fileExt = path.extname(file.originalname).toLowerCase();
    const mimeFromExt = mimeTypeMap[fileExt];

    // Validate: either known MIME type or we can detect from extension
    if (allowedMimes.includes(file.mimetype) || mimeFromExt) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `File type ${file.mimetype} not allowed. Allowed extensions: .jpg, .jpeg, .png, .mp4, .mov`,
        ),
      );
    }
  },
});

module.exports = upload;
