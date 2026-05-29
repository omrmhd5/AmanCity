const express = require("express");
const router = express.Router();
const UserController = require("../controller/userController");
const { verifyIdToken } = require("../service/notificationService");
const { sendPushToUsers } = require("../service/notificationService");
const {
  findUserByFirebaseUid,
  searchUsers,
  sendContactRequest,
  respondToContactRequest,
  removeTrustedContact,
} = require("../service/userService");
const User = require("../model/User");

router.post("/", UserController.registerUser);
router.put("/fcm-token", UserController.updateFcmToken);
router.put("/location", UserController.updateLocation);
router.put("/phone", UserController.updatePhone);

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

// GET /api/users/search?q=<query> — find users by name or phone
router.get("/search", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;
  const q = (req.query.q || "").trim();
  if (q.length < 2)
    return res
      .status(400)
      .json({ message: "Query must be at least 2 characters." });
  try {
    const users = await searchUsers(q, decoded.uid);
    res.json(
      users.map((u) => ({ userId: u._id, name: u.name, phone: u.phone })),
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/users/trusted-contacts — list my contacts (all statuses)
router.get("/trusted-contacts", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;
  try {
    const user = await User.findOne({ firebaseUid: decoded.uid }).populate(
      "trustedContacts.userId",
      "name phone _id",
    );
    if (!user) return res.status(404).json({ message: "User not found." });
    const contacts = user.trustedContacts.map((c) => ({
      userId: c.userId._id,
      name: c.userId.name,
      phone: c.userId.phone,
      status: c.status,
    }));
    res.json(contacts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/users/trusted-contacts/request — send a contact request { toUserId }
router.post("/trusted-contacts/request", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;
  const { toUserId } = req.body;
  if (!toUserId)
    return res.status(400).json({ message: "toUserId is required." });
  try {
    const { fromUser, toUser } = await sendContactRequest(
      decoded.uid,
      toUserId,
    );
    // FCM notification to the receiver
    if (toUser.fcmToken) {
      await sendPushToUsers(
        [{ fcmToken: toUser.fcmToken }],
        `👤 SOS Contact request from ${fromUser.name || "someone"}`,
        "Open the app to accept or decline.",
        {
          type: "contact_request",
          fromUserId: String(fromUser._id),
          fromUserName: fromUser.name || "",
        },
      );
    }
    res.status(200).json({ message: "Request sent." });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PATCH /api/users/trusted-contacts/:contactId/respond — accept/decline { accept: true|false }
router.patch("/trusted-contacts/:contactId/respond", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;
  const accept = req.body.accept === true || req.body.accept === "true";
  try {
    const { fromUser } = await respondToContactRequest(
      decoded.uid,
      req.params.contactId,
      accept,
    );
    // Notify the sender of the outcome
    if (accept && fromUser?.fcmToken) {
      const receiver = await findUserByFirebaseUid(decoded.uid);
      await sendPushToUsers(
        [{ fcmToken: fromUser.fcmToken }],
        `✅ ${receiver?.name || "Someone"} accepted your SOS contact request`,
        "You can now send SOS alerts to each other.",
        {
          type: "contact_accepted",
          fromUserId: String(receiver?._id || ""),
          fromUserName: receiver?.name || "",
        },
      );
    }
    res.status(200).json({
      message: accept
        ? "✅ SOS contact request accepted."
        : "❌ SOS contact request declined.",
    });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE /api/users/trusted-contacts/:contactId — remove a contact
router.delete("/trusted-contacts/:contactId", async (req, res) => {
  const decoded = await _verifyRequest(req, res);
  if (!decoded) return;
  try {
    await removeTrustedContact(decoded.uid, req.params.contactId);
    res.status(200).json({ message: "❌ SOS contact removed." });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DEV-ONLY: test FCM pipeline — GET /api/users/debug-fcm?lat=xx&lng=xx
router.get("/debug-fcm", async (req, res) => {
  const { findUsersNear } = require("../service/userService");
  const { sendPushToUsers } = require("../service/notificationService");
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  if (isNaN(lat) || isNaN(lng)) {
    return res.status(400).json({ message: "Provide ?lat=xx&lng=xx" });
  }
  const users = await findUsersNear(lat, lng, 50); // 50km radius for testing
  if (!users.length) {
    return res.json({
      message: "No users with FCM tokens found within 50km",
      lat,
      lng,
    });
  }
  await sendPushToUsers(
    users,
    "Test Alert · Test Alert ⚠️",
    "Reported near within 2km and test location. Stay alert.",
    {
      incidentType: "Test",
      type: "system",
    },
  );
  res.json({
    message: `Test notification sent to ${users.length} user(s)`,
    users: users.map((u) => ({
      uid: u.firebaseUid,
      token: u.fcmToken?.slice(0, 20) + "...",
      location: u.lastLocation?.coordinates,
    })),
  });
});

module.exports = router;
