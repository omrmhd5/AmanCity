const IncidentService = require("../service/incidentService");
const FileService = require("../service/fileService");
const IncidentType = require("../model/IncidentType");

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
          message: "Missing required fields: title, className, location",
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
          message: "Location must include latitude and longitude",
        });
      }

      // Look up IncidentType by class name (type field)
      const incidentType = await IncidentType.findOne({ type: className });

      if (!incidentType) {
        return res.status(400).json({
          message: `Invalid incident class: ${className}. Must be one of: Accident, Damaged_Building, Fire, Flood, Normal, Public_Issue, Road_Damage`,
        });
      }

      // Handle file upload if present
      let mediaArray = [];
      if (req.file) {
        try {
          const filePath = FileService.saveFileToClass(
            req.file.buffer,
            className,
            req.file.originalname,
          );

          mediaArray = [
            {
              mediaType: req.file.mimetype.startsWith("video")
                ? "VIDEO"
                : "IMAGE",
              url: filePath,
            },
          ];
        } catch (fileError) {
          return res.status(400).json({
            message: `File upload failed: ${fileError.message}`,
          });
        }
      }

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

      res.status(201).json({
        message: "Incident created successfully",
        data: incident,
      });
    } catch (error) {
      console.error("Create incident error:", error);
      res.status(500).json({
        message: error.message || "Failed to create incident",
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
        message: error.message || "Failed to fetch incidents",
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
        message: error.message || "Incident not found",
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
        message: error.message || "Failed to fetch nearby incidents",
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
        message: error.message || "Failed to fetch incidents by type",
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
        message: error.message || "Failed to update incident",
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
        message: error.message || "Failed to delete incident",
      });
    }
  }
}

module.exports = IncidentController;
