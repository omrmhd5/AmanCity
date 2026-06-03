const UserService = require("../service/userService");
const admin = require("firebase-admin");
const { verifyIdToken, sendPushToUsers } = require("../service/notificationService");

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
      const user = await UserService.createOrUpdateUser({
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
      await UserService.updateFcmToken(decoded.uid, fcmToken);
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
      await UserService.updateLocation(decoded.uid, parseFloat(lat), parseFloat(lng));
      res.status(200).json({ message: "Location updated." });
    } catch (err) {
      res
        .status(500)
        .json({ message: err.message || "Failed to update location." });
    }
  }

  /**
   * PUT /api/users/phone
   * Update the authenticated user's phone number.
   */
  static async updatePhone(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const phone = String(req.body.phone || "").trim();
    if (!phone) {
      return res.status(400).json({ message: "phone is required." });
    }

    try {
      const user = await UserService.updatePhone(decoded.uid, phone);
      res.status(200).json({ message: "Phone updated.", data: user });
    } catch (err) {
      res
        .status(500)
        .json({ message: err.message || "Failed to update phone." });
    }
  }

  /**
   * PUT /api/users/profile
   * Update name and/or phone for the authenticated user.
   * Also syncs displayName to Firebase Auth if name is changed.
   */
  static async updateUserProfile(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const name = typeof req.body.name === "string" ? req.body.name.trim() : undefined;
    const phone = typeof req.body.phone === "string" ? req.body.phone.trim() : undefined;

    if (name === undefined && phone === undefined) {
      return res.status(400).json({ message: "Provide at least name or phone." });
    }
    if (name !== undefined && name.length === 0) {
      return res.status(400).json({ message: "Name cannot be empty." });
    }
    if (phone !== undefined && phone.length === 0) {
      return res.status(400).json({ message: "Phone cannot be empty." });
    }

    try {
      const user = await UserService.updateProfile(decoded.uid, { name, phone });

      // Keep Firebase Auth displayName in sync when name changes
      if (name !== undefined) {
        try {
          await admin.auth().updateUser(decoded.uid, { displayName: name });
        } catch (_) {
          // Non-fatal — MongoDB record is source of truth
        }
      }

      res.status(200).json({ message: "Profile updated.", data: user });
    } catch (err) {
      res
        .status(500)
        .json({ message: err.message || "Failed to update profile." });
    }
  }

  /**
   * GET /api/users/me
   * Return the current user's profile.
   */
  static async getUserProfile(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    try {
      const user = await UserService.getUserProfile(decoded.uid);
      res.json(user);
    } catch (err) {
      res.status(err.message === "User not found." ? 404 : 500).json({ message: err.message });
    }
  }

  /**
   * GET /api/users/search?q=<query>
   * Find users by name or phone.
   */
  static async searchUsers(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const q = (req.query.q || "").trim();
    if (q.length < 2) {
      return res.status(400).json({ message: "Query must be at least 2 characters." });
    }

    try {
      const users = await UserService.searchUsers(q, decoded.uid);
      res.json(
        users.map((u) => ({ userId: u._id, name: u.name, phone: u.phone })),
      );
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  /**
   * GET /api/users/trusted-contacts
   * List trusted contacts.
   */
  static async getTrustedContacts(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    try {
      const contacts = await UserService.getTrustedContacts(decoded.uid);
      res.json(contacts);
    } catch (err) {
      res.status(err.message === "User not found." ? 404 : 500).json({ message: err.message });
    }
  }

  /**
   * POST /api/users/trusted-contacts/request
   * Send a contact request.
   */
  static async sendContactRequest(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const { toUserId } = req.body;
    if (!toUserId) {
      return res.status(400).json({ message: "toUserId is required." });
    }

    try {
      const { fromUser, toUser } = await UserService.sendContactRequest(
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
        ).catch((err) => console.error("[FCM] sendContactRequest:", err.message));
      }

      res.status(200).json({ message: "Request sent." });
    } catch (err) {
      res.status(400).json({ message: err.message });
    }
  }

  /**
   * PATCH /api/users/trusted-contacts/:contactId/respond
   * Accept/decline contact request.
   */
  static async respondToContactRequest(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    const accept = req.body.accept === true || req.body.accept === "true";
    try {
      const { fromUser } = await UserService.respondToContactRequest(
        decoded.uid,
        req.params.contactId,
        accept,
      );

      // Notify the sender of the outcome
      if (accept && fromUser?.fcmToken) {
        const receiver = await UserService.findUserByFirebaseUid(decoded.uid);
        await sendPushToUsers(
          [{ fcmToken: fromUser.fcmToken }],
          `✅ ${receiver?.name || "Someone"} accepted your SOS contact request`,
          "You can now send SOS alerts to each other.",
          {
            type: "contact_accepted",
            fromUserId: String(receiver?._id || ""),
            fromUserName: receiver?.name || "",
          },
        ).catch((err) => console.error("[FCM] respondToContactRequest:", err.message));
      }

      res.status(200).json({
        message: accept
          ? "✅ SOS contact request accepted."
          : "❌ SOS contact request declined.",
      });
    } catch (err) {
      res.status(400).json({ message: err.message });
    }
  }

  /**
   * DELETE /api/users/trusted-contacts/:contactId
   * Remove a trusted contact.
   */
  static async removeTrustedContact(req, res) {
    const decoded = await _verifyRequest(req, res);
    if (!decoded) return;

    try {
      await UserService.removeTrustedContact(decoded.uid, req.params.contactId);
      res.status(200).json({ message: "❌ SOS contact removed." });
    } catch (err) {
      res.status(400).json({ message: err.message });
    }
  }

  /**
   * GET /api/users/debug-fcm
   * DEV-ONLY: test FCM pipeline.
   */
  static async debugFcm(req, res) {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ message: "Provide ?lat=xx&lng=xx" });
    }

    try {
      const users = await UserService.findUsersNear(lat, lng, 50); // 50km radius for testing
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
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
}

module.exports = UserController;
