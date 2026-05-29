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
    { new: true, upsert: true },
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
    { new: true, upsert: true },
  );
}

/**
 * Update phone number for a user by Firebase UID.
 */
async function updatePhone(firebaseUid, phone) {
  return User.findOneAndUpdate(
    { firebaseUid },
    { $set: { phone } },
    { new: true, upsert: true, runValidators: true },
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

/**
 * Find a single user by their Firebase UID.
 */
async function findUserByFirebaseUid(firebaseUid) {
  return User.findOne({ firebaseUid });
}

/**
 * Search users by name or phone (case-insensitive, partial match).
 * Excludes the caller and returns minimal public fields.
 * @param {string} query
 * @param {string} excludeFirebaseUid - caller's uid to exclude from results
 */
async function searchUsers(query, excludeFirebaseUid) {
  const regex = new RegExp(query.trim(), "i");
  return User.find({
    firebaseUid: { $ne: excludeFirebaseUid },
    $or: [{ name: regex }, { phone: regex }],
  })
    .select("_id name phone")
    .limit(15);
}

/**
 * Send a trusted contact request from A → B.
 * Adds pending_sent to A's list, pending_incoming to B's list.
 * Throws if a relationship already exists.
 */
async function sendContactRequest(fromFirebaseUid, toUserId) {
  const fromUser = await User.findOne({ firebaseUid: fromFirebaseUid });
  if (!fromUser) throw new Error("Caller not found.");

  const toUser = await User.findById(toUserId);
  if (!toUser) throw new Error("Target user not found.");

  const alreadyExists = fromUser.trustedContacts.some(
    (c) => c.userId.toString() === toUserId.toString(),
  );
  if (alreadyExists) throw new Error("Relationship already exists.");

  await User.findByIdAndUpdate(fromUser._id, {
    $push: {
      trustedContacts: { userId: toUser._id, status: "pending_sent" },
    },
  });
  await User.findByIdAndUpdate(toUser._id, {
    $push: {
      trustedContacts: { userId: fromUser._id, status: "pending_incoming" },
    },
  });

  return { fromUser, toUser };
}

/**
 * Accept or decline an incoming contact request.
 * @param {string} receiverFirebaseUid
 * @param {string} fromUserId - ObjectId of the sender
 * @param {boolean} accept
 */
async function respondToContactRequest(
  receiverFirebaseUid,
  fromUserId,
  accept,
) {
  const receiver = await User.findOne({ firebaseUid: receiverFirebaseUid });
  if (!receiver) throw new Error("User not found.");

  const entry = receiver.trustedContacts.find(
    (c) =>
      c.userId.toString() === fromUserId.toString() &&
      c.status === "pending_incoming",
  );
  if (!entry) throw new Error("No pending request from this user.");

  if (accept) {
    // Both sides → accepted
    await User.updateOne(
      { _id: receiver._id, "trustedContacts.userId": fromUserId },
      { $set: { "trustedContacts.$.status": "accepted" } },
    );
    await User.updateOne(
      { _id: fromUserId, "trustedContacts.userId": receiver._id },
      { $set: { "trustedContacts.$.status": "accepted" } },
    );
  } else {
    // Remove from both sides
    await User.findByIdAndUpdate(receiver._id, {
      $pull: { trustedContacts: { userId: fromUserId } },
    });
    await User.findByIdAndUpdate(fromUserId, {
      $pull: { trustedContacts: { userId: receiver._id } },
    });
  }

  return { fromUser: await User.findById(fromUserId) };
}

/**
 * Remove an accepted/pending trusted contact relationship (both sides).
 */
async function removeTrustedContact(callerFirebaseUid, contactUserId) {
  const caller = await User.findOne({ firebaseUid: callerFirebaseUid });
  if (!caller) throw new Error("User not found.");

  await User.findByIdAndUpdate(caller._id, {
    $pull: { trustedContacts: { userId: contactUserId } },
  });
  await User.findByIdAndUpdate(contactUserId, {
    $pull: { trustedContacts: { userId: caller._id } },
  });
}

/**
 * Get all accepted trusted contacts for a user (populated with name/phone).
 */
async function getAcceptedContacts(firebaseUid) {
  const user = await User.findOne({ firebaseUid }).populate(
    "trustedContacts.userId",
    "name phone firebaseUid fcmToken",
  );
  if (!user) return [];
  return user.trustedContacts
    .filter((c) => c.status === "accepted")
    .map((c) => ({
      userId: c.userId._id,
      name: c.userId.name,
      phone: c.userId.phone,
      fcmToken: c.userId.fcmToken,
    }));
}

module.exports = {
  createOrUpdateUser,
  updateFcmToken,
  updateLocation,
  updatePhone,
  findUsersNear,
  findUserByFirebaseUid,
  searchUsers,
  sendContactRequest,
  respondToContactRequest,
  removeTrustedContact,
  getAcceptedContacts,
};
