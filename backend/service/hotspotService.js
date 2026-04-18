const Incident = require("../model/Incident");

/**
 * Hotspot forecasting service
 * Identifies high-risk zones based on incident clustering and temporal trends
 */
class HotspotService {
  /**
   * Get recent incidents from the last 24 hours
   * Filters by confidence threshold to avoid low-quality data
   */
  static async getRecentIncidents(hoursBack = 24, minConfidence = 0.5) {
    try {
      const timeThreshold = new Date(Date.now() - hoursBack * 60 * 60 * 1000);

      const incidents = await Incident.find({
        timestamp: { $gte: timeThreshold },
        confidence: { $gte: minConfidence },
      })
        .populate("type")
        .sort({ timestamp: -1 });

      return incidents;
    } catch (error) {
      throw new Error("Failed to fetch recent incidents");
    }
  }

  /**
   * DBSCAN clustering algorithm
   * Finds natural spatial clusters of incidents
   * @param {Array} incidents - Array of incident objects with location.latitude/longitude
   * @param {number} eps - Search radius in kilometers
   * @param {number} minPts - Minimum points to form a cluster
   */
  static dbscan(incidents, eps = 2.0, minPts = 2) {
    if (incidents.length === 0) return [];

    const clusters = [];
    const visited = new Set();
    const noise = [];

    // Helper: calculate distance between two incidents in km
    const distance = (inc1, inc2) => {
      const lat1 = inc1.location.latitude;
      const lng1 = inc1.location.longitude;
      const lat2 = inc2.location.latitude;
      const lng2 = inc2.location.longitude;

      const R = 6371; // Earth's radius in km
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

    // Helper: get neighbors within eps radius
    const getNeighbors = (incidentIndex) => {
      const neighbors = [];
      for (let i = 0; i < incidents.length; i++) {
        if (distance(incidents[incidentIndex], incidents[i]) <= eps) {
          neighbors.push(i);
        }
      }
      return neighbors;
    };

    // Main DBSCAN loop
    for (let i = 0; i < incidents.length; i++) {
      if (visited.has(i)) continue;

      const neighbors = getNeighbors(i);

      if (neighbors.length < minPts) {
        noise.push(i);
        visited.add(i);
        continue;
      }

      // Start new cluster
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
  }

  /**
   * Calculate hotspot zones from incident clusters
   * @param {Array} incidents - Array of incident objects
   */
  static calculateHotspots(incidents) {
    if (incidents.length < 2) {
      return []; // Need at least 2 incidents to form a hotspot
    }

    const { clusters } = this.dbscan(incidents, 2.0, 2); // 2km radius, min 2 incidents

    const hotspots = clusters
      .map((clusterIndices) => {
        if (clusterIndices.length < 2) return null;

        const clusterIncidents = clusterIndices.map((idx) => incidents[idx]);

        // Calculate cluster center (mean of all incident locations)
        const centerLat =
          clusterIncidents.reduce(
            (sum, inc) => sum + inc.location.latitude,
            0,
          ) / clusterIncidents.length;
        const centerLng =
          clusterIncidents.reduce(
            (sum, inc) => sum + inc.location.longitude,
            0,
          ) / clusterIncidents.length;

        // Calculate max distance from center (cluster radius)
        let maxDistanceKm = 0;
        for (let inc of clusterIncidents) {
          const R = 6371;
          const dLat = ((inc.location.latitude - centerLat) * Math.PI) / 180;
          const dLng = ((inc.location.longitude - centerLng) * Math.PI) / 180;
          const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos((centerLat * Math.PI) / 180) *
              Math.cos((inc.location.latitude * Math.PI) / 180) *
              Math.sin(dLng / 2) *
              Math.sin(dLng / 2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
          const distance = R * c;

          if (distance > maxDistanceKm) {
            maxDistanceKm = distance;
          }
        }

        // Calculate risk score
        // Weighted formula: (incident_count * 0.4) + (recency_weight * 0.4) + (confidence_avg * 0.2)
        const incidentCount = clusterIncidents.length;
        const avgConfidence =
          clusterIncidents.reduce((sum, inc) => sum + inc.confidence, 0) /
          incidentCount;

        // Recency weight: incidents from last 6 hours get max weight
        const now = new Date();
        const recencyWeights = clusterIncidents.map((inc) => {
          const hoursOld =
            (now.getTime() - inc.timestamp.getTime()) / (1000 * 60 * 60);
          if (hoursOld <= 6) return 1.0;
          if (hoursOld <= 12) return 0.7;
          if (hoursOld <= 24) return 0.4;
          return 0.1;
        });

        const avgRecencyWeight =
          recencyWeights.reduce((a, b) => a + b, 0) / recencyWeights.length;

        const riskScore =
          incidentCount * 0.15 + // More weight on count now
          avgRecencyWeight * 0.4 +
          avgConfidence * 0.45; // High confidence incidents are very important

        // Clamp risk score 0-1
        const normalizedRisk = Math.min(1.0, Math.max(0, riskScore));

        return {
          id: `hotspot_${centerLat.toFixed(4)}_${centerLng.toFixed(4)}`,
          center: {
            latitude: centerLat,
            longitude: centerLng,
          },
          radiusKm: Math.max(0.5, maxDistanceKm * 1.2), // Add 20% buffer
          radiusMeters: Math.max(500, maxDistanceKm * 1.2 * 1000),
          riskScore: normalizedRisk,
          incidentCount: incidentCount,
          avgConfidence: avgConfidence,
          updatedAt: new Date(),
          recentIncidents: clusterIndices, // Indices of incidents in this cluster
        };
      })
      .filter((h) => h !== null)
      .sort((a, b) => b.riskScore - a.riskScore); // Sort by risk descending

    return hotspots;
  }

  /**
   * Main function: Calculate and cache hotspots
   * This is called asynchronously after new incident creation
   */
  static async predictHotspots() {
    try {
      // Get recent incidents (last 24 hours, confidence > 0.5)
      const recentIncidents = await this.getRecentIncidents(24, 0.5);

      if (recentIncidents.length < 2) {
        return []; // Not enough data to form hotspots
      }

      // Calculate hotspots using DBSCAN
      const hotspots = this.calculateHotspots(recentIncidents);

      // Return hotspots (can be cached in Redis or in-memory in production)
      return hotspots;
    } catch (error) {
      console.error("Error predicting hotspots:", error);
      throw error;
    }
  }
}

module.exports = HotspotService;
