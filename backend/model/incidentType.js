const mongoose = require("mongoose");

const incidentTypeSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      required: true,
      unique: true,
      enum: [
        "Accident",
        "Damaged_Building",
        "Fire",
        "Flood",
        "Normal",
        "Public_Issue",
        "Road_Damage",
      ],
    },
    nameEn: {
      type: String,
      required: true,
    },
    nameAr: {
      type: String,
      required: true,
    },
  },
  { timestamps: true },
);

module.exports =
  mongoose.models.IncidentType ||
  mongoose.model("IncidentType", incidentTypeSchema);
