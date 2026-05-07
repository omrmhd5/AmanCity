const { verifyIdToken } = require("../service/notificationService");
const User = require("../model/User");

/**
 * Middleware to verify Firebase ID token and attach authenticated user to req.user.
 * Non-blocking: if no token or verification fails, req.user is set to null and next() is called.
 * This allows both authenticated and unauthenticated requests to proceed.
 */
async function authMiddleware(req, res, next) {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      req.user = null;
      return next();
    }

    const token = authHeader.substring(7); // Remove "Bearer " prefix

    try {
      // Verify Firebase ID token
      const decodedToken = await verifyIdToken(token);

      // Look up user by Firebase UID
      const user = await User.findOne({ firebaseUid: decodedToken.uid });
      req.user = user; // May be null if user not found in DB
    } catch (error) {
      // Token verification failed or user lookup failed
      req.user = null;
    }
  } catch (error) {
    req.user = null;
  }

  next();
}

module.exports = authMiddleware;
