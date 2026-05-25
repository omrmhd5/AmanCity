const mongoose = require("mongoose");

const placePhoneSchema = new mongoose.Schema({
  placeId: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  phoneNumber: {
    type: String,
    default: null,
  },
});

module.exports =
  mongoose.models.PlacePhone ||
  mongoose.model("PlacePhone", placePhoneSchema);
