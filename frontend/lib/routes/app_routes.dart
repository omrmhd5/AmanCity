import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/core/home_screen.dart';
import '../screens/incidents/report_incident_screen.dart';
import '../screens/authority/authority_home_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String reportIncident = '/report-incident';
  static const String authorityHome = '/authority-home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case reportIncident:
        return MaterialPageRoute(builder: (_) => const ReportIncidentScreen());
      case authorityHome:
        return MaterialPageRoute(builder: (_) => const AuthorityHomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
