const {
  createOrUpdateUser,
  updateFcmToken,
  updateLocation,
} = require("../service/userService");
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

class UserController {
  /**
   * POST /api/users
   * Register or update a user profile after Firebase Auth sign-up/sign-in.
   */
  static async registerUser(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const { name, phone, email } = req.body;
    try {
      const user = await createOrUpdateUser({
        firebaseUid: decoded.uid,
        name: name || decoded.name || "",
        phone: phone || "",
        email: email || decoded.email || "",
      });
      res.status(200).json({ message: "User saved.", data: user });
    } catch (err) {
      res.status(500).json({ message: err.message || "Failed to save user." });
    }
  }

  /**
   * PUT /api/users/fcm-token
   * Store or refresh the FCM token for push notifications.
   */
  static async updateFcmToken(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const { fcmToken } = req.body;
    if (!fcmToken)
      return res.status(400).json({ message: "fcmToken is required." });

    try {
      await updateFcmToken(decoded.uid, fcmToken);
      res.status(200).json({ message: "FCM token updated." });
    } catch (err) {
      res
        .status(500)
        .json({ message: err.message || "Failed to update token." });
    }
  }

  /**
   * PUT /api/users/location
   * Update the user's last known location for proximity-based push notifications.
   */
  static async updateLocation(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const { lat, lng } = req.body;
    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ message: "lat and lng are required." });
    }

    try {
      await updateLocation(decoded.uid, parseFloat(lat), parseFloat(lng));
      res.status(200).json({ message: "Location updated." });
    } catch (err) {
      res
        .status(500)
        .json({ message: err.message || "Failed to update location." });
    }
  }
}

module.exports = UserController;
