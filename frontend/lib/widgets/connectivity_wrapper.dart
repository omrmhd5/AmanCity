import 'package:flutter/material.dart';
import '../services/core/connectivity_service.dart';
import '../screens/no_internet_screen.dart';
import '../screens/server_unavailable_screen.dart';

/// Wraps [child] and replaces it with the appropriate offline screen
/// whenever the device has no internet or the backend server is unreachable.
///
/// Onboarding and permissions screens are excluded via [ConnectivityService.setBypass].
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ConnectivityStatus>(
      valueListenable: ConnectivityService.instance.notifier,
      builder: (context, status, _) {
        if (status == ConnectivityStatus.noInternet) {
          return const NoInternetScreen();
        }
        if (status == ConnectivityStatus.serverDown) {
          return const ServerUnavailableScreen();
        }
        return child;
      },
    );
  }
}
