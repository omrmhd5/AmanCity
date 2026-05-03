const User = require("../model/User");

/**
 * Create or update a user by Firebase UID (upsert).
 */
async function createOrUpdateUser({ firebaseUid, name, phone, email }) {
  return User.findOneAndUpdate(
    { firebaseUid },
    { $set: { name, phone, email } },
    { upsert: true, new: true, runValidators: true },
  );
}

/**
 * Update the FCM token for a user.
 */
async function updateFcmToken(firebaseUid, fcmToken) {
  return User.findOneAndUpdate(
    { firebaseUid },
    { $set: { fcmToken } },
    { new: true },
  );
}

/**
 * Update the last known location for a user.
 */
async function updateLocation(firebaseUid, lat, lng) {
  return User.findOneAndUpdate(
    { firebaseUid },
    {
      $set: {
        lastLocation: {
          type: "Point",
          coordinates: [lng, lat], // GeoJSON: [longitude, latitude]
        },
      },
    },
    { new: true },
  );
}

/**
 * Find all users whose lastLocation is within radiusKm kilometres of [lat, lng].
 * Only returns users that have a non-null fcmToken.
 */
async function findUsersNear(lat, lng, radiusKm) {
  const radiusMetres = radiusKm * 1000;
  return User.find({
    fcmToken: { $ne: null },
    lastLocation: {
      $near: {
        $geometry: { type: "Point", coordinates: [lng, lat] },
        $maxDistance: radiusMetres,
      },
    },
  });
}

module.exports = {
  createOrUpdateUser,
  updateFcmToken,
  updateLocation,
  findUsersNear,
};
