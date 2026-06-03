const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

class DirectionsService {
  /**
   * Calculate routes using Google Directions API.
   * Returns formatted primary route details and alternative routes.
   */
  static async calculateRoutes(originLat, originLng, destLat, destLng) {
    if (!GOOGLE_API_KEY) {
      throw new Error("Navigation service not configured. Please try again later.");
    }

    const url = new URL("https://maps.googleapis.com/maps/api/directions/json");
    url.searchParams.append("origin", `${originLat},${originLng}`);
    url.searchParams.append("destination", `${destLat},${destLng}`);
    url.searchParams.append("mode", "driving");
    url.searchParams.append("alternatives", "true"); // Get up to 3 alternative routes
    url.searchParams.append("key", GOOGLE_API_KEY);

    const response = await fetch(url.toString());

    if (!response.ok) {
      throw new Error("Unable to calculate route. Please try again.");
    }

    const data = await response.json();

    if (data.status !== "OK") {
      if (data.status === "ZERO_RESULTS") {
        throw new Error("No route found between these locations.");
      }
      throw new Error("Unable to calculate route. Please try again.");
    }

    // Extract route data
    const primaryRoute = data.routes[0];
    const primaryLeg = primaryRoute.legs[0];

    // Extract all routes for safe route scoring
    const allRoutes = data.routes.map((route) => {
      const leg = route.legs[0];
      return {
        polyline: route.overview_polyline.points,
        distance: {
          text: leg.distance.text,
          value: leg.distance.value,
        },
        duration: {
          text: leg.duration.text,
          value: leg.duration.value,
        },
        startAddress: leg.start_address,
        endAddress: leg.end_address,
        bounds: route.bounds,
      };
    });

    return {
      polyline: primaryRoute.overview_polyline.points,
      distance: {
        text: primaryLeg.distance.text,
        value: primaryLeg.distance.value,
      },
      duration: {
        text: primaryLeg.duration.text,
        value: primaryLeg.duration.value,
      },
      startAddress: primaryLeg.start_address,
      endAddress: primaryLeg.end_address,
      bounds: primaryRoute.bounds,
      routes: allRoutes,
    };
  }
}

module.exports = DirectionsService;
