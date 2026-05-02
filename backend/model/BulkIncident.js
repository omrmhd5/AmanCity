const mongoose = require("mongoose");

const bulkIncidentSchema = new mongoose.Schema(
  {
    // All merged incident document references
    incidentIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Incident",
      },
    ],

    // Total number of reports merged here (= incidentIds.length)
    count: {
      type: Number,
      default: 1,
      min: 1,
    },

    // Shared incident type across all merged reports
    type: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "IncidentType",
      required: true,
    },

    // Centroid of all merged incident locations
    center: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },

    // Human-readable address from first geocoded report
    locationText: { type: String },
    city: { type: String },

    // Time range
    firstReportedAt: { type: Date, required: true },
    lastUpdatedAt: { type: Date, default: Date.now },

    // Aggregated media URLs from all Human source incidents
    mediaUrls: {
      type: [String],
      default: [],
    },

    // Aggregated tweet URLs from all OSINT_Twitter incidents
    sourceUrls: {
      type: [String],
      default: [],
    },

    // Union of source types that contributed (e.g. ["Human", "OSINT_Twitter"])
    confirmedSources: {
      type: [String],
      default: [],
    },

    // Rolling weighted average confidence across all merged incidents
    avgConfidence: {
      type: Number,
      min: 0,
      max: 1,
      default: 0,
    },
  },
  { timestamps: true },
);

// Index for fast proximity + type lookups during merge candidate search
bulkIncidentSchema.index({
  type: 1,
  "center.latitude": 1,
  "center.longitude": 1,
});
bulkIncidentSchema.index({ lastUpdatedAt: -1 });

module.exports =
  mongoose.models.BulkIncident ||
  mongoose.model("BulkIncident", bulkIncidentSchema);
