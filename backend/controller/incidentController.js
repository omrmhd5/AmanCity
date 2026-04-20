const IncidentService = require("../service/incidentService");
const FileService = require("../service/fileService");
const GeocodingService = require("../service/geocodingService");
const IncidentType = require("../model/IncidentType");
const HotspotController = require("./hotspotController");

class IncidentController {
  /**
   * Create new incident with file upload
   * POST /api/incidents
   * Accepts multipart/form-data with file
   */
  static async createIncident(req, res) {
    try {
      const {
        title,
        description,
        className,
        location,
        confidence,
        reportedBy,
      } = req.body;

      // Validation
      if (!title || !className || !location) {
        return res.status(400).json({
          message: "Please provide a title, incident type, and location.",
        });
      }

      // Parse location if it's a string (from multipart form)
      let parsedLocation = location;
      if (typeof location === "string") {
        try {
          parsedLocation = JSON.parse(location);
        } catch (e) {
          parsedLocation = { text: location };
        }
      }

      // Validate location has lat/lng after parsing
      if (
        parsedLocation.latitude === undefined ||
        parsedLocation.longitude === undefined
      ) {
        return res.status(400).json({
          message:
            "Unable to determine your location. Please check that location services are enabled.",
        });
      }

      // Look up IncidentType by class name (type field)
      const incidentType = await IncidentType.findOne({ type: className });

      if (!incidentType) {
        return res.status(400).json({
          message:
            "The selected incident type is not recognized. Please select a valid incident type.",
        });
      }

      // Handle file upload if present
      let mediaArray = [];
      if (req.file) {
        try {
          // Validate file type - allow images and MP4 videos only
          const filename = req.file.originalname.toLowerCase();
          const mimeType = req.file.mimetype.toLowerCase();

          // Check if it's an image (JPG, PNG)
          const isJpg = filename.endsWith(".jpg") || filename.endsWith(".jpeg");
          const isPng = filename.endsWith(".png");
          const isImage =
            (mimeType.startsWith("image/") ||
              mimeType === "application/octet-stream") &&
            (isJpg || isPng);

          // Check if it's a video (MP4)
          const isVideo =
            (mimeType === "video/mp4" ||
              mimeType === "application/octet-stream") &&
            filename.endsWith(".mp4");

          if (!isImage && !isVideo) {
            return res.status(400).json({
              message:
                "Invalid file type. Please upload an image (JPG/PNG) or MP4 video file.",
            });
          }

          const filePath = FileService.saveFileToClass(
            req.file.buffer,
            className,
            req.file.originalname,
          );

          // Determine media type based on file extension
          let mediaType = "IMAGE";
          if (filename.endsWith(".mp4")) {
            mediaType = "VIDEO";
          }

          mediaArray = [
            {
              mediaType: mediaType,
              url: filePath,
            },
          ];
        } catch (fileError) {
          return res.status(400).json({
            message:
              "Unable to upload the file. Please ensure the file is not corrupted or too large.",
          });
        }
      }

      // Reverse geocode the location
      const { text, city } = await GeocodingService.reverseGeocode(
        parsedLocation.latitude,
        parsedLocation.longitude,
      );
      parsedLocation.text = text;
      parsedLocation.city = city;

      const incidentData = {
        title,
        description: description || "",
        type: incidentType._id,
        location: parsedLocation,
        confidence: parseFloat(confidence) || 0.5,
        media: mediaArray,
        reportedBy,
        timestamp: new Date(),
      };

      const incident = await IncidentService.createIncident(incidentData);

      const responseData = {
        _id: incident._id,
        title: incident.title,
        description: incident.description,
        type: incident.type,
        location: incident.location,
        confidence: incident.confidence,
        timestamp: incident.timestamp,
        media: incident.media,
      };

      // Trigger async hotspot recalculation (non-blocking)
      // This updates the hotspot predictions based on the new incident
      HotspotController.triggerAsyncRecalculation();

      res.status(201).json({
        message: "Incident created successfully",
        data: responseData,
      });
    } catch (error) {
      res.status(500).json({
        message:
          error.message || "Unable to save your report. Please try again.",
      });
    }
  }

  /**
   * Get all incidents
   * GET /api/incidents
   */
  static async getIncidents(req, res) {
    try {
      const {
        type,
        minLat,
        maxLat,
        minLng,
        maxLng,
        minConfidence,
        startDate,
        endDate,
        limit,
        skip,
      } = req.query;

      const filters = {
        type,
        minLat: minLat ? parseFloat(minLat) : null,
        maxLat: maxLat ? parseFloat(maxLat) : null,
        minLng: minLng ? parseFloat(minLng) : null,
        maxLng: maxLng ? parseFloat(maxLng) : null,
        minConfidence: minConfidence ? parseFloat(minConfidence) : null,
        startDate,
        endDate,
        limit: limit ? parseInt(limit) : 100,
        skip: skip ? parseInt(skip) : 0,
      };

      const incidents = await IncidentService.getIncidents(filters);

      res.status(200).json({
        message: "Incidents retrieved successfully",
        count: incidents.length,
        data: incidents,
      });
    } catch (error) {
      res.status(500).json({
        message:
          error.message ||
          "Unable to retrieve reports. Please check your connection and try again.",
      });
    }
  }

  /**
   * Get incident by ID
   * GET /api/incidents/:id
   */
  static async getIncidentById(req, res) {
    try {
      const { id } = req.params;
      const incident = await IncidentService.getIncidentById(id);

      res.status(200).json({
        message: "Incident retrieved successfully",
        data: incident,
      });
    } catch (error) {
      res.status(404).json({
        message: error.message || "The report could not be found.",
      });
    }
  }

  /**
   * Get nearby incidents
   * GET /api/incidents/nearby/:latitude/:longitude
   */
  static async getNearbyIncidents(req, res) {
    try {
      const { latitude, longitude } = req.params;
      const { radiusKm } = req.query;

      const incidents = await IncidentService.getNearbyIncidents(
        parseFloat(latitude),
        parseFloat(longitude),
        radiusKm ? parseFloat(radiusKm) : 5,
      );

      res.status(200).json({
        message: "Nearby incidents retrieved successfully",
        count: incidents.length,
        data: incidents,
      });
    } catch (error) {
      res.status(500).json({
        message:
          error.message ||
          "Unable to retrieve nearby reports. Please try again.",
      });
    }
  }

  /**
   * Get incidents by type
   * GET /api/incidents/type/:typeId
   */
  static async getIncidentsByType(req, res) {
    try {
      const { typeId } = req.params;
      const { limit } = req.query;

      const incidents = await IncidentService.getIncidentsByType(
        typeId,
        limit ? parseInt(limit) : 50,
      );

      res.status(200).json({
        message: "Incidents retrieved successfully",
        count: incidents.length,
        data: incidents,
      });
    } catch (error) {
      res.status(500).json({
        message:
          error.message ||
          "Unable to retrieve reports of this type. Please try again.",
      });
    }
  }

  /**
   * Update incident
   * PATCH /api/incidents/:id
   */
  static async updateIncident(req, res) {
    try {
      const { id } = req.params;
      const updateData = req.body;

      // Don't allow updating type and reportedBy directly
      delete updateData.type;
      delete updateData.reportedBy;
      delete updateData.createdAt;

      const incident = await IncidentService.updateIncident(id, updateData);

      res.status(200).json({
        message: "Incident updated successfully",
        data: incident,
      });
    } catch (error) {
      res.status(500).json({
        message:
          error.message || "Unable to update the report. Please try again.",
      });
    }
  }

  /**
   * Delete incident
   * DELETE /api/incidents/:id
   */
  static async deleteIncident(req, res) {
    try {
      const { id } = req.params;
      const result = await IncidentService.deleteIncident(id);

      res.status(200).json({
        message: result.message,
        data: result.incident,
      });
    } catch (error) {
      res.status(404).json({
        message:
          error.message || "Unable to delete the report. Please try again.",
      });
    }
  }
}

module.exports = IncidentController;
