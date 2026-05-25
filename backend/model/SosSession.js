const mongoose = require("mongoose");

const sosSessionSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true, unique: true, index: true },
    triggerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    lat: { type: Number, default: 0 },
    lng: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000),
    },
  },
  { timestamps: true },
);

// TTL index — MongoDB auto-deletes sessions 24h after creation
sosSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model("SosSession", sosSessionSchema);
