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
  // Incident model stores flat latitude/longitude (NOT GeoJSON coordinates)
  const lat = incident.location?.latitude;
  const lng = incident.location?.longitude;

  if (lat === undefined || lng === undefined) {
    console.warn(
      "[FCM] notifyNearbyUsers: incident missing lat/lng",
      incident._id,
    );
    return;
  }

  console.log(`[FCM] Searching for users within 2km of lat=${lat}, lng=${lng}`);
  const nearbyUsers = await findUsersNear(lat, lng, 2);
  console.log(
    `[FCM] Found ${nearbyUsers.length} nearby user(s) with FCM tokens`,
  );

  if (!nearbyUsers.length) return;

  // incident.type is a MongoDB ObjectId — use incident.title for display
  const incidentTitle = incident.title || "Incident";
  const locationText = incident.location.text || "your area";

  await sendPushToUsers(
    nearbyUsers,
    `⚠️ ${incidentTitle} reported nearby`,
    `A ${incidentTitle.toLowerCase()} was reported near ${locationText}. Stay alert.`,
    {
      incidentId: String(incident._id),
      type: "nearbyIncident",
      lat: String(lat),
      lng: String(lng),
    },
  );
}

module.exports = { verifyIdToken, sendPushToUsers, notifyNearbyUsers };
