const Incident = require("../model/incident");
const IncidentType = require("../model/incidentType");

class IncidentService {
  /**
   * Convert YOLO confidence score to severity level
   * @param {number} yoloScore - YOLO confidence score (0-1)
   * @returns {string} - 'danger' | 'warning' | 'info'
   */
  static getConfidenceLevel(yoloScore) {
    if (yoloScore >= 0.8) return 0.9; // Critical confidence
    if (yoloScore >= 0.6) return 0.6; // Medium confidence
    return 0.3; // Low confidence
  }

  /**
   * Create a new incident
   */
  static async createIncident(incidentData) {
    try {
      // Verify incident type exists
      const incidentType = await IncidentType.findById(incidentData.type);
      if (!incidentType) {
        throw new Error("Invalid incident type");
      }

      const incident = new Incident({
        title: incidentData.title,
        description: incidentData.description,
        type: incidentData.type,
        location: {
          latitude: incidentData.location.latitude,
          longitude: incidentData.location.longitude,
          text: incidentData.location.text,
          city: incidentData.location.city,
        },
        confidence: incidentData.confidence || 0.5,
        timestamp: incidentData.timestamp || new Date(),
        media: incidentData.media || [],
        reportedBy: incidentData.reportedBy,
      });

      await incident.save();
      return incident.populate("type").populate("reportedBy");
    } catch (error) {
      throw new Error(`Failed to create incident: ${error.message}`);
    }
  }

  /**
   * Get all incidents with optional filters
   */
  static async getIncidents(filters = {}) {
    try {
      const query = {};

      // Filter by type
      if (filters.type) {
        query.type = filters.type;
      }

      // Filter by location (bounding box)
      if (
        filters.minLat &&
        filters.maxLat &&
        filters.minLng &&
        filters.maxLng
      ) {
        query["location.latitude"] = {
          $gte: filters.minLat,
          $lte: filters.maxLat,
        };
        query["location.longitude"] = {
          $gte: filters.minLng,
          $lte: filters.maxLng,
        };
      }

      // Filter by confidence threshold
      if (filters.minConfidence) {
        query.confidence = { $gte: filters.minConfidence };
      }

      // Filter by date range
      if (filters.startDate || filters.endDate) {
        query.timestamp = {};
        if (filters.startDate) {
          query.timestamp.$gte = new Date(filters.startDate);
        }
        if (filters.endDate) {
          query.timestamp.$lte = new Date(filters.endDate);
        }
      }

      const incidents = await Incident.find(query)
        .populate("type")
        .populate("reportedBy", "name email")
        .sort({ timestamp: -1 })
        .limit(filters.limit || 100)
        .skip(filters.skip || 0);

      return incidents;
    } catch (error) {
      throw new Error(`Failed to fetch incidents: ${error.message}`);
    }
  }

  /**
   * Get incident by ID
   */
  static async getIncidentById(id) {
    try {
      const incident = await Incident.findById(id)
        .populate("type")
        .populate("reportedBy", "name email");

      if (!incident) {
        throw new Error("Incident not found");
      }

      return incident;
    } catch (error) {
      throw new Error(`Failed to fetch incident: ${error.message}`);
    }
  }

  /**
   * Update incident
   */
  static async updateIncident(id, updateData) {
    try {
      const incident = await Incident.findByIdAndUpdate(id, updateData, {
        new: true,
        runValidators: true,
      })
        .populate("type")
        .populate("reportedBy", "name email");

      if (!incident) {
        throw new Error("Incident not found");
      }

      return incident;
    } catch (error) {
      throw new Error(`Failed to update incident: ${error.message}`);
    }
  }

  /**
   * Get nearby incidents
   */
  static async getNearbyIncidents(latitude, longitude, radiusKm = 5) {
    try {
      // Convert km to degrees (approximately 1 degree = 111 km)
      const radiusDegrees = radiusKm / 111;

      const incidents = await Incident.find({
        "location.latitude": {
          $gte: latitude - radiusDegrees,
          $lte: latitude + radiusDegrees,
        },
        "location.longitude": {
          $gte: longitude - radiusDegrees,
          $lte: longitude + radiusDegrees,
        },
      })
        .populate("type")
        .sort({ timestamp: -1 });

      return incidents;
    } catch (error) {
      throw new Error(`Failed to fetch nearby incidents: ${error.message}`);
    }
  }

  /**
   * Get incidents by type
   */
  static async getIncidentsByType(typeId, limit = 50) {
    try {
      const incidents = await Incident.find({ type: typeId })
        .populate("type")
        .populate("reportedBy", "name email")
        .sort({ timestamp: -1 })
        .limit(limit);

      return incidents;
    } catch (error) {
      throw new Error(`Failed to fetch incidents by type: ${error.message}`);
    }
  }

  /**
   * Delete incident
   */
  static async deleteIncident(id) {
    try {
      const incident = await Incident.findByIdAndDelete(id);

      if (!incident) {
        throw new Error("Incident not found");
      }

      return { message: "Incident deleted successfully", incident };
    } catch (error) {
      throw new Error(`Failed to delete incident: ${error.message}`);
    }
  }
}

module.exports = IncidentService;
