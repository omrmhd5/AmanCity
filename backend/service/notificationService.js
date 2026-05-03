const admin = require("firebase-admin");
const path = require("path");
const { findUsersNear } = require("./userService");

// Initialise Firebase Admin SDK once
if (!admin.apps.length) {
  const serviceAccount = require(
    path.join(__dirname, "../firebase-service-account.json"),
  );
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

/**
 * Verify a Firebase ID token and return the decoded token.
 * Throws if the token is invalid.
 */
async function verifyIdToken(idToken) {
  return admin.auth().verifyIdToken(idToken);
}

/**
 * Send an FCM push notification to a list of users.
 * @param {Array} users - Array of User documents (must have fcmToken)
 * @param {string} title
 * @param {string} body
 * @param {Object} data - Key-value string payload
 */
async function sendPushToUsers(users, title, body, data = {}) {
  const tokens = users.map((u) => u.fcmToken).filter(Boolean);
  if (!tokens.length) return;

  const message = {
    tokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)]),
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "nearby_alerts",
        sound: "default",
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(
      `📲 FCM sent: ${response.successCount} success, ${response.failureCount} failed`,
    );
  } catch (err) {
    console.error("FCM send error:", err.message);
  }
}

/**
 * Find users within 2km of an incident and push a notification to them.
 */
async function notifyNearbyUsers(incident) {
  const [lng, lat] = incident.location.coordinates;
  const nearbyUsers = await findUsersNear(lat, lng, 2);
  if (!nearbyUsers.length) return;

  const incidentType = incident.type || "Incident";
  const locationText = incident.locationText || "your area";

  await sendPushToUsers(
    nearbyUsers,
    `⚠️ ${incidentType} reported nearby`,
    `A ${incidentType.toLowerCase()} was reported near ${locationText}. Stay alert.`,
    {
      incidentId: String(incident._id),
      type: incidentType,
      lat: String(lat),
      lng: String(lng),
    },
  );
}

module.exports = { verifyIdToken, sendPushToUsers, notifyNearbyUsers };
