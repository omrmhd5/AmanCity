const crypto = require("crypto");
const SosSession = require("../model/SosSession");
const User = require("../model/User");
const UserService = require("./userService");
const { sendPushToUsers } = require("./notificationService");

class SosService {
  /**
   * Activate SOS: creates session, pushes FCM to accepted trusted contacts.
   */
  static async createSosSession(triggerUser, lat, lng) {
    const sessionId = crypto.randomUUID();
    await SosSession.create({
      sessionId,
      triggerUserId: triggerUser._id,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
    });

    // Notify accepted trusted contacts
    const contacts = await UserService.getAcceptedContacts(triggerUser.firebaseUid);
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
      ).catch((err) => console.error("[FCM] SosService.createSosSession notification failed:", err.message));
    }

    return sessionId;
  }

  /**
   * Update live location.
   */
  static async updateSosLocation(sessionId, lat, lng) {
    const session = await SosSession.findOne({ sessionId });
    if (!session) {
      throw new Error("Session not found.");
    }

    session.lat = parseFloat(lat);
    session.lng = parseFloat(lng);
    session.updatedAt = new Date();
    await session.save();

    return session;
  }

  /**
   * End SOS session and notify trusted contacts.
   */
  static async endSosSession(sessionId, callerFirebaseUid) {
    const session = await SosSession.findOne({ sessionId });
    if (!session) {
      throw new Error("Session not found.");
    }

    session.active = false;
    await session.save();

    const triggerUser = await User.findById(session.triggerUserId);
    const contacts = await UserService.getAcceptedContacts(callerFirebaseUid);
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
          sessionId: sessionId,
          triggerUserName: triggerUser?.name || "",
        },
      ).catch((err) => console.error("[FCM] SosService.endSosSession notification failed:", err.message));
    }

    return session;
  }

  /**
   * Get live location of session.
   */
  static async getSosSession(sessionId) {
    const session = await SosSession.findOne({
      sessionId,
    }).populate("triggerUserId", "name phone");
    if (!session) {
      throw new Error("Session not found.");
    }
    return session;
  }
}

module.exports = SosService;
