const multer = require("multer");

// Configure multer for file uploads
const storage = multer.memoryStorage(); // Store in memory for quick processing

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
    ];

    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `File type ${file.mimetype} not allowed. Allowed types: ${allowedMimes.join(", ")}`,
        ),
      );
    }
  },
});

module.exports = upload;
