const mongoose = require("mongoose");

const incidentTypeSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      required: true,
      unique: true,
      enum: [
        // Environmental (7Classes Model)
        "Accident",
        "Damaged Building",
        "Fire",
        "Flood",
        "Public Issue",
        "Road Damage",
        // Weapons (Weapons Model)
        "Firearm",
        "Cold Weapon",
        // Behavioral Crimes (Crime Model)
        "Arrest",
        "Arson",
        "Assault",
        "Burglary",
        "Explosion",
        "Fighting",
        "Robbery",
        "Shooting",
        "Shoplifting",
        "Stealing",
        "Vandalism",
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
