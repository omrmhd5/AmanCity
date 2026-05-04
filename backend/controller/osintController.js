const { runGrokScan } = require("../service/osintService");
const GeocodingService = require("../service/geocodingService");
const IncidentService = require("../service/incidentService");
const BulkIncidentService = require("../service/bulkIncidentService");
const IncidentType = require("../model/IncidentType");
const { notifyNearbyUsers } = require("../service/notificationService");

/**
 * POST /api/osint/scan
 * Triggers a Grok OSINT scan and saves discovered incidents to MongoDB
 */
async function scanOsint(req, res) {
  console.log("📡 OSINT scan triggered via API");

  let grokRaw = [];
  let sources = [];

  // Step 1: Run Grok scan
  try {
    const result = await runGrokScan();
    grokRaw = result.incidents;
    sources = result.sources;
    console.log(`✅ Grok returned ${grokRaw.length} raw incident(s)`);
  } catch (err) {
    console.error("❌ Grok scan failed:", err.message);
    return res
      .status(502)
      .json({ message: "Grok scan failed.", error: err.message });
  }

  if (grokRaw.length === 0) {
    return res.status(200).json({
      message: "Scan complete. No incidents found.",
      scanned: 0,
      saved: 0,
      skipped_vague: 0,
      skipped_duplicate: 0,
      skipped_geocode_fail: 0,
      skipped_unknown_type: 0,
    });
  }

  // Step 2: Process each raw incident
  const summary = {
    scanned: grokRaw.length,
    saved: 0,
    skipped_vague: 0,
    skipped_duplicate: 0,
    skipped_geocode_fail: 0,
    skipped_unknown_type: 0,
  };

  const savedIncidents = [];

  for (const raw of grokRaw) {
    // Resolve incident type ObjectId
    const incidentTypeDoc = await IncidentType.findOne({ type: raw.type });
    if (!incidentTypeDoc) {
      console.warn(`⚠️  Unknown type "${raw.type}" — skipping`);
      summary.skipped_unknown_type++;
      continue;
    }

    // Forward geocode the Arabic location text
    const geo = await GeocodingService.forwardGeocode(raw.location_text);
    if (!geo) {
      console.warn(
        `⚠️  Geocoding failed for "${raw.location_text}" — skipping`,
      );
      summary.skipped_geocode_fail++;
      continue;
    }

    // Deduplicate: skip only if same sourceUrl is already in an existing bulk's sourceUrls
    // Otherwise, save and attempt merge (absorb into BulkIncident)
    const isDuplicate = await IncidentService.checkDuplicate(
      incidentTypeDoc._id,
      geo.latitude,
      geo.longitude,
      raw.source_urls || [],
    );
    if (isDuplicate) {
      console.log(`🔁 Duplicate skipped: ${raw.title}`);
      summary.skipped_duplicate++;
      continue;
    }

    // Save to MongoDB
    try {
      const incident = await IncidentService.createIncident({
        title: raw.title,
        description: raw.location_text, // store original Arabic text as description
        type: incidentTypeDoc._id,
        location: {
          latitude: geo.latitude,
          longitude: geo.longitude,
          text: geo.text,
          city: geo.city,
        },
        source: "OSINT_Twitter",
        sourceUrls: raw.source_urls || [],
        osintConfidence: raw.severity,
        locationPrecision: raw.location_precision || null,
        confidence: 0,
      });

      savedIncidents.push(incident);
      summary.saved++;

      // Attempt merge into BulkIncident (non-blocking, errors swallowed)
      _attemptOsintMerge(incident).catch(() => {});

      // Notify nearby users via FCM (non-blocking)
      notifyNearbyUsers(incident).catch((err) =>
        console.error("[FCM] osintController:", err.message),
      );

      const precisionTag = raw.location_precision === "VAGUE" ? " [VAGUE]" : "";
      console.log(`💾 Saved: ${raw.title}${precisionTag} (${geo.text})`);
    } catch (err) {
      console.error(`❌ Failed to save "${raw.title}":`, err.message);
    }
  }

  console.log(`\n📊 Scan Summary:`, summary);

  return res.status(200).json({
    message: "OSINT scan complete.",
    ...summary,
    incidents: savedIncidents.map((i) => ({
      id: i._id,
      title: i.title,
      type: i.type?.type,
      location: i.location?.text,
      locationPrecision: i.locationPrecision,
      osintConfidence: i.osintConfidence,
    })),
  });
}

/**
 * GET /api/osint/incidents
 * Fetches all OSINT_Twitter incidents from MongoDB, sorted by timestamp desc
 */
async function getOsintIncidents(req, res) {
  try {
    const incidents = await IncidentService.getIncidentsBySource(
      "OSINT_Twitter",
      50, // limit to 50 incidents
    );

    console.log(`✅ Fetched ${incidents.length} OSINT_Twitter incidents`);

    return res.status(200).json({
      message: "OSINT incidents retrieved successfully.",
      count: incidents.length,
      incidents: incidents.map((i) => ({
        id: i._id,
        title: i.title,
        type: i.type?.type || "Unknown",
        location: i.location?.text,
        latitude: i.location?.latitude,
        longitude: i.location?.longitude,
        locationPrecision: i.locationPrecision,
        osintConfidence: i.osintConfidence,
        sourceUrls: i.sourceUrls || [],
        timestamp: i.timestamp,
      })),
    });
  } catch (err) {
    console.error("❌ Failed to fetch OSINT incidents:", err.message);
    return res.status(500).json({
      message: "Failed to fetch incidents.",
      error: err.message,
    });
  }
}

module.exports = { scanOsint, getOsintIncidents };

/**
 * Attempt to merge an OSINT incident into an existing BulkIncident or
 * pair it with a nearby standalone incident to create one.
 * Non-blocking — caller must handle errors.
 */
async function _attemptOsintMerge(incident) {
  const lat = incident.location.latitude;
  const lng = incident.location.longitude;
  const typeId = incident.type._id || incident.type;

  const existingBulk = await BulkIncidentService.findMatchingBulk(
    typeId,
    lat,
    lng,
  );
  if (existingBulk) {
    await BulkIncidentService.addToBulk(existingBulk._id, incident);
    console.log(
      `🔗 OSINT incident ${incident._id} merged into BulkIncident ${existingBulk._id}`,
    );
    return;
  }

  const standaloneMatch = await BulkIncidentService.findStandaloneMatch(
    typeId,
    lat,
    lng,
    incident._id,
  );
  if (standaloneMatch) {
    const bulk = await BulkIncidentService.createBulk(
      standaloneMatch,
      incident,
    );
    console.log(
      `🆕 BulkIncident ${bulk._id} created from OSINT + existing incident`,
    );
  }
}
