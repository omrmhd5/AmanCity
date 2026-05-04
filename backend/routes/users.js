const express = require("express");
const router = express.Router();
const UserController = require("../controller/userController");

router.post("/", UserController.registerUser);
router.put("/fcm-token", UserController.updateFcmToken);
router.put("/location", UserController.updateLocation);

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
