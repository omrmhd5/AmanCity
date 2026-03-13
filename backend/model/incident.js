const mongoose = require("mongoose");

const incidentSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
    },
    type: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "IncidentType",
      required: true,
    },
    location: {
      latitude: {
        type: Number,
        required: true,
      },
      longitude: {
        type: Number,
        required: true,
      },
      text: {
        type: String,
      },
      city: {
        type: String,
      },
    },
    confidence: {
      type: Number,
      min: 0,
      max: 1,
      default: 0,
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
    media: [
      {
        mediaType: {
          type: String,
          enum: ["IMAGE", "VIDEO"],
          required: true,
        },
        url: {
          type: String,
          required: true,
        },
        _id: false,
      },
    ],
    reportedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  },
  { timestamps: true },
);

// Index for faster queries
incidentSchema.index({ "location.latitude": 1, "location.longitude": 1 });
incidentSchema.index({ timestamp: -1 });
incidentSchema.index({ type: 1 });
incidentSchema.index({ status: 1 });

module.exports =
  mongoose.models.Incident || mongoose.model("Incident", incidentSchema);
