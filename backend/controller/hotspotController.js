const HotspotService = require("../service/hotspotService");

/**
 * In-memory cache for hotspots
 * In production, consider using Redis for distributed caching
 */
let hotspotCache = {
  data: [],
  timestamp: null,
  ttlMinutes: 60,
};

/**
 * Hotspot Controller
 * Manages hotspot prediction and caching
 */
class HotspotController {
  /**
   * GET /api/hotspots
   * Returns cached hotspots or recalculates if cache expired
   */
  static async getHotspots(req, res) {
    try {
      // Check if cache is fresh
      if (hotspotCache.data.length > 0 && hotspotCache.timestamp) {
        const cacheAge = Date.now() - hotspotCache.timestamp.getTime();
        const cacheTTL = hotspotCache.ttlMinutes * 60 * 1000;

        if (cacheAge < cacheTTL) {
          return res.status(200).json({
            success: true,
            data: hotspotCache.data,
            source: "cache",
            cachedAt: hotspotCache.timestamp,
          });
        }
      }

      // Cache expired or empty, recalculate
      const hotspots = await HotspotService.predictHotspots();

      // Update cache
      hotspotCache.data = hotspots;
      hotspotCache.timestamp = new Date();

      return res.status(200).json({
        success: true,
        data: hotspots,
        source: "fresh",
        calculatedAt: hotspotCache.timestamp,
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: "Failed to retrieve hotspots",
        error: error.message,
      });
    }
  }

  /**
   * POST /api/hotspots/recalculate
   * Manually trigger hotspot recalculation (invalidates cache)
   * This is called asynchronously from incident creation
   */
  static async recalculateHotspots(req, res) {
    try {
      // Don't block the response - just acknowledge
      res.status(200).json({
        success: true,
        message: "Hotspot recalculation triggered",
      });

      // Perform recalculation asynchronously (fire and forget)
      setImmediate(async () => {
        try {
          const hotspots = await HotspotService.predictHotspots();

          // Update cache
          hotspotCache.data = hotspots;
          hotspotCache.timestamp = new Date();
        } catch (error) {
          // Silently fail - don't break incident creation
        }
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: "Failed to trigger hotspot recalculation",
        error: error.message,
      });
    }
  }

  /**
   * Internal method: Async hotspot recalculation (called from incidentController)
   * Non-blocking, returns immediately
   */
  static async triggerAsyncRecalculation() {
    // Use setImmediate to run after current execution context
    // This ensures incident creation completes before hotspot calculation starts
    setImmediate(async () => {
      try {
        const hotspots = await HotspotService.predictHotspots();

        // Update cache
        hotspotCache.data = hotspots;
        hotspotCache.timestamp = new Date();
      } catch (error) {
        // Silently fail - don't affect incident creation
      }
    });
  }

  /**
   * Clear hotspot cache (useful for testing)
   */
  static clearCache() {
    hotspotCache = {
      data: [],
      timestamp: null,
      ttlMinutes: 60,
    };
  }
}

module.exports = HotspotController;
