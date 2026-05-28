const express = require("express");
const router = express.Router();
const crypto = require("crypto");
const { verifyIdToken } = require("../service/notificationService");
const { sendPushToUsers } = require("../service/notificationService");
const {
  findUserByFirebaseUid,
  getAcceptedContacts,
} = require("../service/userService");
const SosSession = require("../model/SosSession");
const User = require("../model/User");

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

// ---------------------------------------------------------------------------
// POST /api/sos/sessions
// Activate SOS: creates session, pushes FCM to accepted trusted contacts.
// ---------------------------------------------------------------------------
router.post("/sessions", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;

  const { lat, lng } = req.body;
  if (lat === undefined || lng === undefined) {
    return res.status(400).json({ message: "lat and lng are required." });
  }

  try {
    const triggerUser = await findUserByFirebaseUid(decoded.uid);
    if (!triggerUser)
      return res.status(404).json({ message: "User not found." });

    const sessionId = crypto.randomUUID();
    await SosSession.create({
      sessionId,
      triggerUserId: triggerUser._id,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
    });

    // Notify accepted trusted contacts
    const contacts = await getAcceptedContacts(decoded.uid);
    const usersWithTokens = contacts
      .filter((c) => c.fcmToken)
      .map((c) => ({ fcmToken: c.fcmToken }));

    if (usersWithTokens.length > 0) {
      await sendPushToUsers(
        usersWithTokens,
        `🆘 ${triggerUser.name || "a contact"} is in danger!`,
        "Tap to see their live location.",
        {
          type: "sos_alert",
          sessionId,
          triggerUserName: triggerUser.name || "",
          triggerUserPhone: triggerUser.phone || "",
          lat: String(lat),
          lng: String(lng),
        },
      );
    }

    res.status(201).json({ sessionId });
  } catch (err) {
    res
      .status(500)
      .json({ message: err.message || "Failed to create SOS session." });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/sos/sessions/:id/location
// Update live location (called every 10s from the SOS-active user's app).
// ---------------------------------------------------------------------------
router.patch("/sessions/:id/location", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;

  const { lat, lng } = req.body;
  if (lat === undefined || lng === undefined) {
    return res.status(400).json({ message: "lat and lng are required." });
  }

  try {
    const session = await SosSession.findOne({ sessionId: req.params.id });
    if (!session)
      return res.status(404).json({ message: "Session not found." });

    session.lat = parseFloat(lat);
    session.lng = parseFloat(lng);
    session.updatedAt = new Date();
    await session.save();

    res.status(200).json({ ok: true });
  } catch (err) {
    res
      .status(500)
      .json({ message: err.message || "Failed to update location." });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/sos/sessions/:id/end
// End SOS session and notify trusted contacts.
// ---------------------------------------------------------------------------
router.patch("/sessions/:id/end", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;

  try {
    const session = await SosSession.findOne({ sessionId: req.params.id });
    if (!session)
      return res.status(404).json({ message: "Session not found." });

    session.active = false;
    await session.save();

    const triggerUser = await User.findById(session.triggerUserId);
    const contacts = await getAcceptedContacts(decoded.uid);
    const usersWithTokens = contacts
      .filter((c) => c.fcmToken)
      .map((c) => ({ fcmToken: c.fcmToken }));

    if (usersWithTokens.length > 0) {
      await sendPushToUsers(
        usersWithTokens,
        `✅ SOS ended, ${triggerUser?.name || "Your contact"} is safe`,
        "The SOS alert has been deactivated.",
        {
          type: "sos_ended",
          sessionId: req.params.id,
          triggerUserName: triggerUser?.name || "",
        },
      );
    }

    res.status(200).json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: err.message || "Failed to end session." });
  }
});

// ---------------------------------------------------------------------------
// GET /api/sos/sessions/:id
// Poll live location (called every 10s by the tracking-screen user).
// ---------------------------------------------------------------------------
router.get("/sessions/:id", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;

  try {
    const session = await SosSession.findOne({
      sessionId: req.params.id,
    }).populate("triggerUserId", "name phone");
    if (!session)
      return res.status(404).json({ message: "Session not found." });

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
    res.status(500).json({ message: err.message || "Failed to get session." });
  }
});

module.exports = router;
