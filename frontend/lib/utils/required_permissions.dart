import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions the app requests (onboarding + gate in main.dart).
/// Phone/device contacts are not used — calls use tel: without extra permission.
const List<Permission> requiredAppPermissions = [
  Permission.locationWhenInUse,
  Permission.camera,
  Permission.microphone,
  Permission.photos,
  Permission.notification,
];
