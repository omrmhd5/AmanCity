const express = require("express");
const router = express.Router();
const UserController = require("../controller/userController");

router.post("/", UserController.registerUser);
router.put("/fcm-token", UserController.updateFcmToken);
router.put("/location", UserController.updateLocation);

module.exports = router;
