const BulkIncident = require("../model/BulkIncident");
const Incident = require("../model/Incident");

// 2km in degrees (~1 degree latitude = 111 km)
const DEGREE_OFFSET = 2 / 111; // ≈ 0.018°

// 6-hour merge window
const SIX_HOURS_MS = 6 * 60 * 60 * 1000;

class BulkIncidentService {
  /**
   * Find an existing BulkIncident that a new incident should merge into.
   * Criteria: same type, center within 2km, lastUpdatedAt within 6 hours.
   * @param {ObjectId} typeId
   * @param {number} lat
   * @param {number} lng
   * @returns {Promise<BulkIncident|null>}
   */
  static async findMatchingBulk(typeId, lat, lng) {
    const sixHoursAgo = new Date(Date.now() - SIX_HOURS_MS);

    return BulkIncident.findOne({
      type: typeId,
      lastUpdatedAt: { $gte: sixHoursAgo },
      "center.latitude": {
        $gte: lat - DEGREE_OFFSET,
        $lte: lat + DEGREE_OFFSET,
      },
      "center.longitude": {
        $gte: lng - DEGREE_OFFSET,
        $lte: lng + DEGREE_OFFSET,
      },
    });
  }

  /**
   * Find a standalone incident (not yet merged) that could pair with a new one.
   * Used when no BulkIncident exists yet but two singles match.
   * @param {ObjectId} typeId
   * @param {number} lat
   * @param {number} lng
   * @param {string} excludeId - the new incident's _id to exclude from results
   * @returns {Promise<Incident|null>}
   */
  static async findStandaloneMatch(typeId, lat, lng, excludeId) {
    const sixHoursAgo = new Date(Date.now() - SIX_HOURS_MS);

    return Incident.findOne({
      _id: { $ne: excludeId },
      type: typeId,
      isMerged: false,
      bulkIncidentId: { $exists: false },
      timestamp: { $gte: sixHoursAgo },
      "location.latitude": {
        $gte: lat - DEGREE_OFFSET,
        $lte: lat + DEGREE_OFFSET,
      },
      "location.longitude": {
        $gte: lng - DEGREE_OFFSET,
        $lte: lng + DEGREE_OFFSET,
      },
    });
  }

  /**
   * Absorb a new incident into an existing BulkIncident.
   * Updates the bulk doc and flags the incident as merged.
   * @param {ObjectId} bulkId
   * @param {Incident} incident - mongoose document
   */
  static async addToBulk(bulkId, incident) {
    const bulk = await BulkIncident.findById(bulkId);
    if (!bulk) return;

    // Recalculate centroid
    const prevCount = bulk.count;
    const newCount = prevCount + 1;
    const newCenterLat =
      (bulk.center.latitude * prevCount + incident.location.latitude) /
      newCount;
    const newCenterLng =
      (bulk.center.longitude * prevCount + incident.location.longitude) /
      newCount;

    // Recalculate avgConfidence as rolling average
    const effectiveConf =
      incident.source === "OSINT_Twitter"
        ? (incident.osintConfidence ?? incident.confidence)
        : incident.confidence;
    const newAvgConf =
      (bulk.avgConfidence * prevCount + effectiveConf) / newCount;

    // Build $push updates
    const pushUpdates = { incidentIds: incident._id };
    if (incident.source === "Human" && incident.media?.length > 0) {
      const urls = incident.media.map((m) => m.url);
      pushUpdates.mediaUrls = { $each: urls };
    }
    if (
      incident.source === "OSINT_Twitter" &&
      incident.sourceUrls?.length > 0
    ) {
      pushUpdates.sourceUrls = { $each: incident.sourceUrls };
    }

    await BulkIncident.findByIdAndUpdate(bulkId, {
      $inc: { count: 1 },
      $addToSet: { confirmedSources: incident.source },
      $push: pushUpdates,
      $set: {
        "center.latitude": newCenterLat,
        "center.longitude": newCenterLng,
        avgConfidence: newAvgConf,
        lastUpdatedAt: new Date(),
      },
    });

    // Flag the incident as merged
    await Incident.findByIdAndUpdate(incident._id, {
      isMerged: true,
      bulkIncidentId: bulkId,
    });
  }

  /**
   * Create a brand new BulkIncident from two standalone incidents.
   * Flags both incidents as merged.
   * @param {Incident} incident1 - existing standalone incident (mongoose doc)
   * @param {Incident} incident2 - newly created incident (mongoose doc)
   * @returns {Promise<BulkIncident>}
   */
  static async createBulk(incident1, incident2) {
    const incidents = [incident1, incident2];

    // Centroid
    const centerLat =
      (incident1.location.latitude + incident2.location.latitude) / 2;
    const centerLng =
      (incident1.location.longitude + incident2.location.longitude) / 2;

    // Aggregate media and source URLs
    const mediaUrls = [];
    const sourceUrls = [];
    const confirmedSources = new Set();

    for (const inc of incidents) {
      confirmedSources.add(inc.source);
      if (inc.source === "Human" && inc.media?.length > 0) {
        mediaUrls.push(...inc.media.map((m) => m.url));
      }
      if (inc.source === "OSINT_Twitter" && inc.sourceUrls?.length > 0) {
        sourceUrls.push(...inc.sourceUrls);
      }
    }

    // Average confidence
    const getConf = (inc) =>
      inc.source === "OSINT_Twitter"
        ? (inc.osintConfidence ?? inc.confidence)
        : inc.confidence;
    const avgConfidence = (getConf(incident1) + getConf(incident2)) / 2;

    // Use earliest timestamp for firstReportedAt
    const firstReportedAt =
      incident1.timestamp < incident2.timestamp
        ? incident1.timestamp
        : incident2.timestamp;

    // Use location text from whichever has it
    const locationText =
      incident1.location.text || incident2.location.text || null;
    const city = incident1.location.city || incident2.location.city || null;

    const bulk = await BulkIncident.create({
      incidentIds: [incident1._id, incident2._id],
      count: 2,
      type: incident1.type,
      center: { latitude: centerLat, longitude: centerLng },
      locationText,
      city,
      firstReportedAt,
      lastUpdatedAt: new Date(),
      mediaUrls,
      sourceUrls,
      confirmedSources: [...confirmedSources],
      avgConfidence,
    });

    // Flag both incidents as merged
    await Incident.updateMany(
      { _id: { $in: [incident1._id, incident2._id] } },
      { isMerged: true, bulkIncidentId: bulk._id },
    );

    return bulk;
  }

  /**
   * Get all BulkIncidents, optionally filtered by bounding box.
   */
  static async getBulkIncidents(filters = {}) {
    const query = {};
    if (filters.minLat && filters.maxLat && filters.minLng && filters.maxLng) {
      query["center.latitude"] = {
        $gte: filters.minLat,
        $lte: filters.maxLat,
      };
      query["center.longitude"] = {
        $gte: filters.minLng,
        $lte: filters.maxLng,
      };
    }

    return BulkIncident.find(query)
      .populate("type")
      .sort({ lastUpdatedAt: -1 })
      .limit(filters.limit || 100);
  }

  /**
   * Get a single BulkIncident by ID with all sub-incidents populated.
   */
  static async getBulkIncidentById(id) {
    return BulkIncident.findById(id)
      .populate("type")
      .populate({
        path: "incidentIds",
        populate: { path: "type" },
      });
  }
}

module.exports = BulkIncidentService;
