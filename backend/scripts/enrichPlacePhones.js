/**
 * enrichPlacePhones.js
 *
 * One-time script to fetch all hospital/police/fire_station places within a
 * radius and persist their phone numbers in MongoDB.
 *
 * Usage:
 *   node scripts/enrichPlacePhones.js
 *   node scripts/enrichPlacePhones.js --lat 30.12496 --lng 31.621495 --radius 5000
 *
 * Re-running is safe — uses upsert on placeId.
 */

require("dotenv").config({ path: require("path").join(__dirname, "../.env") });
const mongoose = require("mongoose");
const PlacePhone = require("../model/PlacePhone");

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/amancity";

const PLACE_TYPES = ["hospital", "police", "fire_station"];

// --- Parse CLI args ----------------------------------------------------------
function getArg(name, fallback) {
  const idx = process.argv.indexOf(`--${name}`);
  return idx !== -1 ? process.argv[idx + 1] : fallback;
}

const LAT = parseFloat(getArg("lat", "30.12496"));
const LNG = parseFloat(getArg("lng", "31.621495"));
const RADIUS = parseInt(getArg("radius", "5000"));

// --- API call ----------------------------------------------------------------
async function fetchPlaces(type) {
  const url = "https://places.googleapis.com/v1/places:searchNearby";

  const body = {
    includedTypes: [type],
    maxResultCount: 20,
    locationRestriction: {
      circle: {
        center: { latitude: LAT, longitude: LNG },
        radius: RADIUS,
      },
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": GOOGLE_API_KEY,
      "X-Goog-FieldMask":
        "places.name,places.displayName,places.nationalPhoneNumber",
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Places API error for type=${type}: ${err}`);
  }

  const data = await res.json();
  return data.places || [];
}

// --- Main --------------------------------------------------------------------
async function main() {
  if (!GOOGLE_API_KEY) {
    console.error("?  GOOGLE_API_KEY is not set in .env");
    process.exit(1);
  }

  console.log(`\nConnecting to MongoDB…`);
  await mongoose.connect(MONGO_URI);
  console.log("?  Connected\n");

  console.log(
    `Fetching places within ${RADIUS}m of (${LAT}, ${LNG})\n`
  );

  let totalSaved = 0;

  for (const type of PLACE_TYPES) {
    process.stdout.write(`  [${type}] fetching… `);
    const places = await fetchPlaces(type);
    process.stdout.write(`${places.length} results ? `);

    let saved = 0;
    for (const place of places) {
      const placeId = place.name; // e.g. "places/ChIJ..."
      const phoneNumber = place.nationalPhoneNumber || null;

      await PlacePhone.findOneAndUpdate(
        { placeId },
        { placeId, phoneNumber },
        { upsert: true, new: true }
      );
      saved++;
    }

    console.log(`upserted ${saved}`);
    totalSaved += saved;
  }

  console.log(`\n?  Done — ${totalSaved} total records upserted.\n`);
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error("?  Script failed:", err.message);
  process.exit(1);
});
