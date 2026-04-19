const Incident = require("../model/Incident");
const { Worker } = require("worker_threads");
const path = require("path");

/**
 * Hotspot forecasting service
 * Identifies high-risk zones based on incident clustering and temporal trends
 * Uses Worker Threads to prevent blocking the main event loop with expensive DBSCAN calculations
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
        .sort({ timestamp: -1 })
        .lean(); // Convert Mongoose documents to plain objects for worker thread serialization

      return incidents;
    } catch (error) {
      throw new Error("Failed to fetch recent incidents");
    }
  }

  /**
   * Run hotspot calculation in a worker thread
   * Prevents blocking the main event loop with expensive DBSCAN operations
   * @param {Array} incidents - Array of incident objects
   * @returns {Promise<Array>} - Promise resolving to hotspots array
   */
  static async calculateHotspotsWithWorker(incidents) {
    return new Promise((resolve, reject) => {
      const worker = new Worker(
        path.join(__dirname, "../workers/hotspotWorker.js"),
      );

      const timeout = setTimeout(() => {
        worker.terminate();
        reject(new Error("Hotspot calculation timed out after 30 seconds"));
      }, 30000); // 30 second timeout

      worker.on("message", (message) => {
        clearTimeout(timeout);
        worker.terminate();

        if (message.success) {
          resolve(message.hotspots);
        } else {
          reject(new Error(message.error || "Worker error"));
        }
      });

      worker.on("error", reject);
      worker.on("exit", (code) => {
        if (code !== 0) {
          reject(new Error(`Worker exited with code ${code}`));
        }
      });

      // Send incidents to worker
      worker.postMessage({ incidents });
    });
  }

  /**
   * Main function: Calculate and cache hotspots
   * This is called asynchronously after new incident creation
   * Uses Worker Threads to prevent blocking the main thread
   */
  static async predictHotspots() {
    try {
      // Get recent incidents (last 24 hours, confidence > 0.5)
      const recentIncidents = await this.getRecentIncidents(24, 0.5);

      if (recentIncidents.length < 2) {
        return []; // Not enough data to form hotspots
      }

      // Calculate hotspots using worker thread
      const hotspots = await this.calculateHotspotsWithWorker(recentIncidents);

      // Return hotspots (can be cached in Redis or in-memory in production)
      return hotspots;
    } catch (error) {
      console.error("Error predicting hotspots:", error);
      throw error;
    }
  }
}

module.exports = HotspotService;
