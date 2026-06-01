/**
 * createAuthorityUser.js
 *
 * Creates an authority user in both Firebase Auth and MongoDB.
 *
 * Usage:
 *   node scripts/createAuthorityUser.js
 *
 * Credentials created:
 *   Email:    auth@gmail.com
 *   Password: 123456
 *   Role:     authority
 */

const path = require("path");
const admin = require("firebase-admin");
const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config({ path: path.join(__dirname, "../.env") });

const serviceAccount = require("../firebase-service-account.json");

// Initialise Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Minimal inline schema so the script is self-contained
const { Schema } = mongoose;

const authorityEmail = "auth@gmail.com";
const authorityPassword = "123456";
const authorityName = "Authority";

async function run() {
  // ── Connect to MongoDB ──────────────────────────────────────────────────────
  const mongoUri =
    process.env.MONGO_URI || "mongodb://localhost:27017/amancity";
  await mongoose.connect(mongoUri);
  console.log("✅ MongoDB connected");

  // Require model after connection so it picks up correct connection
  const User = require("../model/User");

  // ── Step 1: Create or get Firebase Auth user ────────────────────────────────
  let firebaseUser;
  try {
    firebaseUser = await admin.auth().getUserByEmail(authorityEmail);
    console.log(`ℹ️  Firebase user already exists: ${firebaseUser.uid}`);
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      firebaseUser = await admin.auth().createUser({
        email: authorityEmail,
        password: authorityPassword,
        displayName: authorityName,
        emailVerified: true,
      });
      console.log(`✅ Firebase user created: ${firebaseUser.uid}`);
    } else {
      throw err;
    }
  }

  // Ensure email is marked as verified (in case the user pre-existed)
  await admin.auth().updateUser(firebaseUser.uid, { emailVerified: true });
  console.log("✅ Firebase emailVerified = true");

  // ── Step 2: Create or update MongoDB user ───────────────────────────────────
  const existing = await User.findOne({ firebaseUid: firebaseUser.uid });
  if (existing) {
    existing.role = "authority";
    await existing.save();
    console.log(
      `ℹ️  MongoDB user updated to role=authority (id: ${existing._id})`,
    );
  } else {
    const newUser = await User.create({
      firebaseUid: firebaseUser.uid,
      name: authorityName,
      email: authorityEmail,
      phone: "",
      role: "authority",
    });
    console.log(`✅ MongoDB user created (id: ${newUser._id})`);
  }

  console.log("\n🎉 Authority user ready.");
  console.log(`   Email:    ${authorityEmail}`);
  console.log(`   Password: ${authorityPassword}`);
  console.log(`   Role:     authority`);

  await mongoose.disconnect();
  process.exit(0);
}

run().catch((err) => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
