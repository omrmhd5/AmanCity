const SosService = require("../service/sosService");
const UserService = require("../service/userService");
const { verifyIdToken } = require("../service/notificationService");

/**
 * Extract and verify Firebase ID token from the Authorization header.
 * Returns the decoded token or sends 401.
 */
async function _verifyRequest(req, res) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) {
    res.status(401).json({ message: "Missing authorization token." });
    return null;
  }
  try {
    return await verifyIdToken(token);
  } catch {
    res.status(401).json({ message: "Invalid or expired token." });
    return null;
  }
}

class SosController {
  /**
   * POST /api/sos/sessions
   * Activate SOS: creates session, pushes FCM to accepted trusted contacts.
   */
  static async createSession(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const { lat, lng } = req.body;
    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ message: "lat and lng are required." });
    }

    try {
      const triggerUser = await UserService.findUserByFirebaseUid(decoded.uid);
      if (!triggerUser) {
        return res.status(404).json({ message: "User not found." });
      }

      const sessionId = await SosService.createSosSession(triggerUser, lat, lng);
      res.status(201).json({ sessionId });
    } catch (err) {
      res
        .status(500)
        .json({ message: err.message || "Failed to create SOS session." });
    }
  }

  /**
   * PATCH /api/sos/sessions/:id/location
   * Update live location (called every 10s from the SOS-active user's app).
   */
  static async updateLocation(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const { lat, lng } = req.body;
    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ message: "lat and lng are required." });
    }

    try {
      await SosService.updateSosLocation(req.params.id, lat, lng);
      res.status(200).json({ ok: true });
    } catch (err) {
      res
        .status(err.message === "Session not found." ? 404 : 500)
        .json({ message: err.message || "Failed to update location." });
    }
  }

  /**
   * PATCH /api/sos/sessions/:id/end
   * End SOS session and notify trusted contacts.
   */
  static async endSession(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    try {
      await SosService.endSosSession(req.params.id, decoded.uid);
      res.status(200).json({ ok: true });
    } catch (err) {
      res
        .status(err.message === "Session not found." ? 404 : 500)
        .json({ message: err.message || "Failed to end session." });
    }
  }

  /**
   * GET /api/sos/sessions/:id
   * Poll live location (called every 10s by the tracking-screen user).
   */
  static async getSession(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    try {
      const session = await SosService.getSosSession(req.params.id);
      const { lat, lng, active, updatedAt, triggerUserId: user } = session;
      res.status(200).json({
        lat,
        lng,
        active,
        updatedAt,
        triggerUser: {
          name: user?.name || "",
          phone: user?.phone || "",
        },
      });
    } catch (err) {
      res
        .status(err.message === "Session not found." ? 404 : 500)
        .json({ message: err.message || "Failed to get session." });
    }
  }
}

module.exports = SosController;
