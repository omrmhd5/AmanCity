const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

/// File service for saving incident photos to class-specific folders
class FileService {
  /// Base uploads directory
  static uploadsDir = path.join(__dirname, "../uploads");

  /// Get class folder path and create if needed
  static getClassFolder(className) {
    const classFolder = path.join(this.uploadsDir, className);

    // Create folder if it doesn't exist
    if (!fs.existsSync(classFolder)) {
      fs.mkdirSync(classFolder, { recursive: true });
    }

    return classFolder;
  }

  /// Save file buffer to class-specific folder
  /// Returns relative path for storing in database
  static saveFileToClass(fileBuffer, className, originalFilename) {
    try {
      // Validate class name (prevent directory traversal)
      // Note: Normal images are blocked and never uploaded
      const validClasses = [
        "Accident",
        "Damaged_Building",
        "Fire",
        "Flood",
        "Public_Issue",
        "Road_Damage",
        "Weapon",
      ];

      if (!validClasses.includes(className)) {
        throw new Error(
          "The selected incident type cannot be saved. Please contact support.",
        );
      }

      // Get class folder
      const classFolder = this.getClassFolder(className);

      // Generate unique filename
      const ext = path.extname(originalFilename);
      const timestamp = Date.now();
      const random = crypto.randomBytes(4).toString("hex");
      const filename = `${timestamp}-${random}${ext}`;

      // Full file path
      const filePath = path.join(classFolder, filename);

      // Save file
      fs.writeFileSync(filePath, fileBuffer);

      // Return relative path for database
      const relativePath = path.join("uploads", className, filename);
      return relativePath.replace(/\\/g, "/"); // Convert to forward slashes for URLs
    } catch (error) {
      throw new Error(
        "Unable to save the file. Please ensure it is a valid image or video.",
      );
    }
  }

  /// Delete file by path
  static deleteFile(relativePath) {
    try {
      const filePath = path.join(this.uploadsDir, "..", relativePath);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    } catch (error) {
      console.error(`Failed to delete file: ${error.message}`);
    }
  }
}

module.exports = FileService;
