const Incident = require("../model/Incident");
const BulkIncident = require("../model/BulkIncident");
const SosSession = require("../model/SosSession");
const User = require("../model/User");
const { verifyIdToken } = require("../service/notificationService");

async function _verifyAuthority(req, res) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) {
    res.status(401).json({ message: "Missing authorization token." });
    return null;
  }
  try {
    const decoded = await verifyIdToken(token);
    const user = await User.findOne({ firebaseUid: decoded.uid });
    if (!user || user.role !== "authority") {
      res.status(403).json({ message: "Access denied. Authority only." });
      return null;
    }
    return { decoded, user };
  } catch {
    res.status(401).json({ message: "Invalid or expired token." });
    return null;
  }
}

/**
 * GET /api/authority/dashboard
 * Returns aggregated stats for the authority dashboard.
 */
async function getDashboard(req, res) {
  const auth = await _verifyAuthority(req, res);
  if (!auth) return;

  try {
    const now = new Date();
    const last24h = new Date(now - 24 * 60 * 60 * 1000);
    const last7d = new Date(now - 7 * 24 * 60 * 60 * 1000);
    const last30d = new Date(now - 30 * 24 * 60 * 60 * 1000);

    // ── Counts ──────────────────────────────────────────────────────────────
    const [total, last24hCount, last7dCount, humanCount, osintCount] =
      await Promise.all([
        Incident.countDocuments(),
        Incident.countDocuments({ timestamp: { $gte: last24h } }),
        Incident.countDocuments({ timestamp: { $gte: last7d } }),
        Incident.countDocuments({ source: "Human" }),
        Incident.countDocuments({ source: "OSINT_Twitter" }),
      ]);

    // ── Top incident types (last 30 days) ────────────────────────────────────
    const topTypes = await Incident.aggregate([
      { $match: { timestamp: { $gte: last30d } } },
      {
        $lookup: {
          from: "incidenttypes",
          localField: "type",
          foreignField: "_id",
          as: "typeDoc",
        },
      },
      { $unwind: { path: "$typeDoc", preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: "$typeDoc.type",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
      { $limit: 6 },
    ]);

    // ── Top areas/cities (last 30 days) ──────────────────────────────────────
    const topAreas = await Incident.aggregate([
      {
        $match: {
          timestamp: { $gte: last30d },
          "location.city": { $ne: null, $exists: true, $ne: "" },
        },
      },
      {
        $group: {
          _id: "$location.city",
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
      { $limit: 6 },
    ]);

    // ── Recent incidents (last 10) ────────────────────────────────────────────
    const recentIncidents = await Incident.find()
      .sort({ timestamp: -1 })
      .limit(10)
      .populate("type", "type")
      .lean();

    // ── Active SOS sessions ──────────────────────────────────────────────────
    const activeSosSessions = await SosSession.find({ active: true })
      .sort({ createdAt: -1 })
      .limit(20)
      .populate("triggerUserId", "name phone")
      .lean();

    // ── Bulk incident count ───────────────────────────────────────────────────
    const bulkCount = await BulkIncident.countDocuments();

    return res.status(200).json({
      stats: {
        total,
        last24h: last24hCount,
        last7d: last7dCount,
        human: humanCount,
        osint: osintCount,
        bulkIncidents: bulkCount,
      },
      topTypes: topTypes.map((t) => ({
        type: t._id || "Unknown",
        count: t.count,
      })),
      topAreas: topAreas.map((a) => ({
        area: a._id || "Unknown",
        count: a.count,
      })),
      recentIncidents: recentIncidents.map((i) => ({
        id: i._id,
        title: i.title,
        type: i.type?.type || "Unknown",
        source: i.source,
        location: i.location?.text || i.location?.city || "Unknown",
        city: i.location?.city,
        osintConfidence: i.osintConfidence,
        timestamp: i.timestamp,
      })),
      activeSos: activeSosSessions.map((s) => ({
        sessionId: s.sessionId,
        userName: s.triggerUserId?.name || "Anonymous",
        userPhone: s.triggerUserId?.phone || "",
        lat: s.lat,
        lng: s.lng,
        createdAt: s.createdAt,
      })),
    });
  } catch (err) {
    console.error("❌ Authority dashboard error:", err.message);
    res.status(500).json({ message: "Failed to load dashboard." });
  }
}

module.exports = { getDashboard };
