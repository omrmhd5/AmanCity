const mongoose = require("mongoose");

const trustedContactSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    status: {
      type: String,
      enum: ["pending_sent", "pending_incoming", "accepted"],
      default: "pending_sent",
    },
  },
  { _id: false },
);

const userSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    name: { type: String, default: "" },
    phone: { type: String, default: "" },
    email: { type: String, default: "" },
    fcmToken: { type: String, default: null },
    role: { type: String, enum: ["user", "authority"], default: "user" },
    trustedContacts: { type: [trustedContactSchema], default: [] },
    lastLocation: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },
  },
  { timestamps: true },
);

userSchema.index({ lastLocation: "2dsphere" });

module.exports = mongoose.model("User", userSchema);
