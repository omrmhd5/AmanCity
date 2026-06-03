const admin = require("firebase-admin");
const path = require("path");
const UserService = require("./userService");

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

  const nearbyUsers = await UserService.findUsersNear(lat, lng, 2);

  if (!nearbyUsers.length) return;

  // incident.type is a MongoDB ObjectId — populate it to get the type name
  let incidentTypeName = "Incident";
  if (incident.type) {
    // If already populated, use it; otherwise type is an ObjectId
    if (typeof incident.type === "object" && incident.type.type) {
      incidentTypeName = incident.type.type;
    }
  }

  const incidentTitle = incident.title || "Incident";
  const locationText = incident.location.text || "your area";

  // Calculate approximate distance from incident to each user (in km)
  // For now, we'll use a generic message; distance could be personalized per user later
  const distanceMsg = "within 2km";

  await sendPushToUsers(
    nearbyUsers,
    `${incidentTitle} · ${incidentTypeName} Alert ⚠️`,
    `Reported near ${distanceMsg} and ${locationText}. Stay alert.`,
    {
      incidentId: String(incident._id),
      incidentType: incidentTypeName,
      type: "nearbyIncident",
      lat: String(lat),
      lng: String(lng),
    },
  );
}

module.exports = { verifyIdToken, sendPushToUsers, notifyNearbyUsers };
