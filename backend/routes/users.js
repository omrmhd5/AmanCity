const express = require("express");
const router = express.Router();
const UserController = require("../controller/userController");

router.post("/", UserController.registerUser);
router.put("/fcm-token", UserController.updateFcmToken);
router.put("/location", UserController.updateLocation);
router.put("/phone", UserController.updatePhone);
router.put("/profile", UserController.updateUserProfile);

// GET /api/users/me — return the current user's profile (including role)
router.get("/me", UserController.getUserProfile);

// GET /api/users/search?q=<query> — find users by name or phone
router.get("/search", UserController.searchUsers);

// GET /api/users/trusted-contacts — list my contacts (all statuses)
router.get("/trusted-contacts", UserController.getTrustedContacts);

// POST /api/users/trusted-contacts/request — send a contact request { toUserId }
router.post("/trusted-contacts/request", UserController.sendContactRequest);

// PATCH /api/users/trusted-contacts/:contactId/respond — accept/decline { accept: true|false }
router.patch("/trusted-contacts/:contactId/respond", UserController.respondToContactRequest);

// DELETE /api/users/trusted-contacts/:contactId — remove a contact
router.delete("/trusted-contacts/:contactId", UserController.removeTrustedContact);

// DEV-ONLY: test FCM pipeline — GET /api/users/debug-fcm?lat=xx&lng=xx
router.get("/debug-fcm", UserController.debugFcm);

module.exports = router;
