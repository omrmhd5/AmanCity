const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

class GeocodingService {
  /**
   * Convert coordinates to human-readable address and city
   * @param {number} latitude
   * @param {number} longitude
   * @returns {Promise<{text: string|null, city: string|null}>}
   */
  static async reverseGeocode(latitude, longitude) {
    if (!GOOGLE_API_KEY) {
      return { text: null, city: null };
    }

    try {
      const url =
        `https://maps.googleapis.com/maps/api/geocode/json?` +
        `latlng=${latitude},${longitude}&key=${GOOGLE_API_KEY}`;

      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`Geocoding API returned status ${response.status}`);
      }

      const data = await response.json();

      if (data.status !== "OK" || !data.results || data.results.length === 0) {
        return { text: null, city: null };
      }

      // Get formatted address from first result
      const text = data.results[0].formatted_address || null;

      // Extract city (administrative_area_level_2)
      const cityComponent = data.results[0].address_components?.find((comp) =>
        comp.types.includes("administrative_area_level_2"),
      );
      const city = cityComponent?.short_name || null;

      return { text, city };
    } catch (error) {
      return { text: null, city: null };
    }
  }
}

module.exports = GeocodingService;
