const BulkIncidentService = require("../service/bulkIncidentService");

class BulkIncidentController {
  /**
   * GET /api/bulk-incidents
   * Returns all BulkIncidents (optionally filtered by bounding box)
   */
  static async getBulkIncidents(req, res) {
    try {
      const { minLat, maxLat, minLng, maxLng, limit } = req.query;
      const filters = {
        minLat: minLat ? parseFloat(minLat) : null,
        maxLat: maxLat ? parseFloat(maxLat) : null,
        minLng: minLng ? parseFloat(minLng) : null,
        maxLng: maxLng ? parseFloat(maxLng) : null,
        limit: limit ? parseInt(limit) : 100,
      };

      const bulks = await BulkIncidentService.getBulkIncidents(filters);

      return res.status(200).json({
        message: "Bulk incidents retrieved successfully.",
        count: bulks.length,
        data: bulks,
      });
    } catch (err) {
      return res.status(500).json({
        message: "Failed to retrieve bulk incidents.",
        error: err.message,
      });
    }
  }

  /**
   * GET /api/bulk-incidents/:id
   * Returns a single BulkIncident with all sub-incidents fully populated
   */
  static async getBulkIncidentById(req, res) {
    try {
      const { id } = req.params;
      const bulk = await BulkIncidentService.getBulkIncidentById(id);

      if (!bulk) {
        return res.status(404).json({ message: "Bulk incident not found." });
      }

      return res.status(200).json({
        message: "Bulk incident retrieved successfully.",
        data: bulk,
      });
    } catch (err) {
      return res.status(500).json({
        message: "Failed to retrieve bulk incident.",
        error: err.message,
      });
    }
  }
}

module.exports = BulkIncidentController;
