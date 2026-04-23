const Incident = require("../model/Incident");
const IncidentType = require("../model/IncidentType");

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

  static async createIncident(incidentData) {
    try {
      // Verify incident type exists
      const incidentType = await IncidentType.findById(incidentData.type);
      if (!incidentType) {
        throw new Error("The selected incident type is not valid.");
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
        timestamp: incidentData.timestamp || new Date(),
        media: incidentData.media || [],
        reportedBy: incidentData.reportedBy,
        ...(incidentData.confidence !== undefined && {
          confidence: incidentData.confidence,
        }),
        ...(incidentData.source && { source: incidentData.source }),
        ...(incidentData.sourceUrls && { sourceUrls: incidentData.sourceUrls }),
        ...(incidentData.osintConfidence !== undefined && {
          osintConfidence: incidentData.osintConfidence,
        }),
        ...(incidentData.locationPrecision && {
          locationPrecision: incidentData.locationPrecision,
        }),
      });

      await incident.save();

      const populatedIncident = await Incident.findById(incident._id)
        .populate("type")
        .populate("reportedBy");
      return populatedIncident;
    } catch (error) {
      throw new Error(
        error.message || "Unable to save your report. Please try again.",
      );
    }
  }

  /**
   * Check if an OSINT incident already exists nearby (deduplication)
   * Matches same type, within ~500m, in the last 30 minutes
   * @param {ObjectId} typeId
   * @param {number} lat
   * @param {number} lng
   * @returns {Promise<boolean>}
   */
  static async checkDuplicate(typeId, lat, lng) {
    const DEGREE_OFFSET = 0.0045; // ~500m
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);

    const existing = await Incident.findOne({
      type: typeId,
      source: "OSINT_Twitter",
      timestamp: { $gte: thirtyMinutesAgo },
      "location.latitude": {
        $gte: lat - DEGREE_OFFSET,
        $lte: lat + DEGREE_OFFSET,
      },
      "location.longitude": {
        $gte: lng - DEGREE_OFFSET,
        $lte: lng + DEGREE_OFFSET,
      },
    });

    return existing !== null;
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
      throw new Error(
        "Unable to retrieve reports. Please check your connection and try again.",
      );
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
        throw new Error("The report could not be found.");
      }

      return incident;
    } catch (error) {
      throw new Error("Unable to retrieve the report. Please try again.");
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
        throw new Error("The report could not be found.");
      }

      return incident;
    } catch (error) {
      throw new Error("Unable to update the report. Please try again.");
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
      throw new Error("Unable to retrieve nearby reports. Please try again.");
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
      throw new Error(
        "Unable to retrieve reports of this type. Please try again.",
      );
    }
  }

  /**
   * Delete incident
   */
  static async deleteIncident(id) {
    try {
      const incident = await Incident.findByIdAndDelete(id);

      if (!incident) {
        throw new Error("The report could not be found.");
      }

      return { message: "Report deleted successfully", incident };
    } catch (error) {
      throw new Error("Unable to delete the report. Please try again.");
    }
  }
}

module.exports = IncidentService;
