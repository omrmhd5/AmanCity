const { parentPort } = require("worker_threads");

/**
 * Worker thread for computing hotspots asynchronously
 * Prevents blocking the main thread with expensive DBSCAN calculations
 */

// Haversine distance function
const haversineDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

// DBSCAN clustering
const dbscan = (incidents, eps = 2.0, minPts = 2) => {
  const visited = new Set();
  const clusters = [];
  const noise = [];

  const distance = (inc1, inc2) => {
    return haversineDistance(
      inc1.location.latitude,
      inc1.location.longitude,
      inc2.location.latitude,
      inc2.location.longitude,
    );
  };

  const getNeighbors = (incidentIndex) => {
    const neighbors = [];
    for (let i = 0; i < incidents.length; i++) {
      if (distance(incidents[incidentIndex], incidents[i]) <= eps) {
        neighbors.push(i);
      }
    }
    return neighbors;
  };

  for (let i = 0; i < incidents.length; i++) {
    if (visited.has(i)) continue;

    const neighbors = getNeighbors(i);

    if (neighbors.length < minPts) {
      noise.push(i);
      visited.add(i);
      continue;
    }

    const cluster = [];
    const queue = [...neighbors];
    visited.add(i);
    cluster.push(i);

    while (queue.length > 0) {
      const currentIdx = queue.shift();

      if (visited.has(currentIdx)) continue;

      visited.add(currentIdx);
      cluster.push(currentIdx);

      const currentNeighbors = getNeighbors(currentIdx);
      if (currentNeighbors.length >= minPts) {
        queue.push(...currentNeighbors.filter((idx) => !visited.has(idx)));
      }
    }

    clusters.push(cluster);
  }

  return { clusters, noise };
};

// Calculate hotspots from clusters
const calculateHotspots = (incidents) => {
  if (incidents.length < 2) {
    return [];
  }

  const { clusters } = dbscan(incidents, 2.0, 2);

  const hotspots = clusters
    .map((clusterIndices) => {
      if (clusterIndices.length < 2) return null;

      const clusterIncidents = clusterIndices.map((idx) => incidents[idx]);

      const centerLat =
        clusterIncidents.reduce((sum, inc) => sum + inc.location.latitude, 0) /
        clusterIncidents.length;
      const centerLng =
        clusterIncidents.reduce((sum, inc) => sum + inc.location.longitude, 0) /
        clusterIncidents.length;

      let maxDistanceKm = 0;
      for (let inc of clusterIncidents) {
        const distance = haversineDistance(
          inc.location.latitude,
          inc.location.longitude,
          centerLat,
          centerLng,
        );

        if (distance > maxDistanceKm) {
          maxDistanceKm = distance;
        }
      }

      const incidentCount = clusterIncidents.length;
      const avgConfidence =
        clusterIncidents.reduce((sum, inc) => sum + inc.confidence, 0) /
        incidentCount;

      const now = new Date();
      const recencyWeights = clusterIncidents.map((inc) => {
        const hoursOld =
          (now.getTime() - new Date(inc.timestamp).getTime()) /
          (1000 * 60 * 60);
        if (hoursOld <= 6) return 1.0;
        if (hoursOld <= 12) return 0.7;
        if (hoursOld <= 24) return 0.4;
        return 0.1;
      });

      const avgRecencyWeight =
        recencyWeights.reduce((a, b) => a + b, 0) / recencyWeights.length;

      // Normalize incident count: cap at 10 incidents to prevent runaway multiplier
      const normalizedCount = Math.min(incidentCount, 10) / 10;

      const riskScore =
        normalizedCount * 0.15 + avgRecencyWeight * 0.4 + avgConfidence * 0.45;

      const normalizedRisk = Math.min(1.0, Math.max(0, riskScore));

      return {
        id: `hotspot_${centerLat.toFixed(4)}_${centerLng.toFixed(4)}`,
        center: {
          latitude: centerLat,
          longitude: centerLng,
        },
        radiusKm: Math.max(0.5, maxDistanceKm * 1.2),
        radiusMeters: Math.max(500, maxDistanceKm * 1.2 * 1000),
        riskScore: normalizedRisk,
        incidentCount: incidentCount,
        avgConfidence: avgConfidence,
        updatedAt: new Date(),
        recentIncidents: clusterIndices,
      };
    })
    .filter((h) => h !== null)
    .sort((a, b) => b.riskScore - a.riskScore);

  return hotspots;
};

// Listen for messages from main thread
parentPort.on("message", (message) => {
  try {
    const { incidents } = message;
    const hotspots = calculateHotspots(incidents);

    parentPort.postMessage({
      success: true,
      hotspots: hotspots,
    });
  } catch (error) {
    parentPort.postMessage({
      success: false,
      error: error.message,
    });
  }
});
