import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../services/auth/auth_service.dart';

class AuthorityDashboard {
  final AuthorityStats stats;
  final List<TypeBreakdown> topTypes;
  final List<AreaBreakdown> topAreas;
  final List<AuthorityIncident> recentIncidents;
  final List<AuthoritySosSession> activeSos;

  const AuthorityDashboard({
    required this.stats,
    required this.topTypes,
    required this.topAreas,
    required this.recentIncidents,
    required this.activeSos,
  });

  factory AuthorityDashboard.fromJson(Map<String, dynamic> json) {
    return AuthorityDashboard(
      stats: AuthorityStats.fromJson(json['stats'] ?? {}),
      topTypes: (json['topTypes'] as List? ?? [])
          .map((e) => TypeBreakdown.fromJson(e))
          .toList(),
      topAreas: (json['topAreas'] as List? ?? [])
          .map((e) => AreaBreakdown.fromJson(e))
          .toList(),
      recentIncidents: (json['recentIncidents'] as List? ?? [])
          .map((e) => AuthorityIncident.fromJson(e))
          .toList(),
      activeSos: (json['activeSos'] as List? ?? [])
          .map((e) => AuthoritySosSession.fromJson(e))
          .toList(),
    );
  }
}

class AuthorityStats {
  final int total;
  final int last24h;
  final int last7d;
  final int human;
  final int osint;
  final int bulkIncidents;

  const AuthorityStats({
    required this.total,
    required this.last24h,
    required this.last7d,
    required this.human,
    required this.osint,
    required this.bulkIncidents,
  });

  factory AuthorityStats.fromJson(Map<String, dynamic> json) {
    return AuthorityStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      last24h: (json['last24h'] as num?)?.toInt() ?? 0,
      last7d: (json['last7d'] as num?)?.toInt() ?? 0,
      human: (json['human'] as num?)?.toInt() ?? 0,
      osint: (json['osint'] as num?)?.toInt() ?? 0,
      bulkIncidents: (json['bulkIncidents'] as num?)?.toInt() ?? 0,
    );
  }
}

class TypeBreakdown {
  final String type;
  final int count;
  const TypeBreakdown({required this.type, required this.count});
  factory TypeBreakdown.fromJson(Map<String, dynamic> json) => TypeBreakdown(
    type: json['type'] ?? 'Unknown',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

class AreaBreakdown {
  final String area;
  final int count;
  const AreaBreakdown({required this.area, required this.count});
  factory AreaBreakdown.fromJson(Map<String, dynamic> json) => AreaBreakdown(
    area: json['area'] ?? 'Unknown',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

class AuthorityIncident {
  final String id;
  final String title;
  final String type;
  final String source;
  final String location;
  final String? city;
  final double? osintConfidence;
  final DateTime timestamp;

  const AuthorityIncident({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    required this.location,
    this.city,
    this.osintConfidence,
    required this.timestamp,
  });

  factory AuthorityIncident.fromJson(Map<String, dynamic> json) {
    return AuthorityIncident(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'Unknown',
      source: json['source'] ?? 'Human',
      location: json['location'] ?? 'Unknown',
      city: json['city'],
      osintConfidence: (json['osintConfidence'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isOsint => source == 'OSINT_Twitter';
}

class AuthoritySosSession {
  final String sessionId;
  final String userName;
  final String userPhone;
  final double lat;
  final double lng;
  final DateTime createdAt;

  const AuthoritySosSession({
    required this.sessionId,
    required this.userName,
    required this.userPhone,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  factory AuthoritySosSession.fromJson(Map<String, dynamic> json) {
    return AuthoritySosSession(
      sessionId: json['sessionId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userPhone: json['userPhone'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AuthorityApiService {
  AuthorityApiService._();
  static final AuthorityApiService instance = AuthorityApiService._();

  Future<AuthorityDashboard> fetchDashboard() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) throw 'Not authenticated.';

    final uri = Uri.parse('${AppConfig.backendUrl}/authority/dashboard');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return AuthorityDashboard.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 403) {
      throw 'Access denied. Authority users only.';
    } else {
      throw 'Failed to load dashboard (${response.statusCode}).';
    }
  }

  Future<String?> fetchCurrentUserRole() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse('${AppConfig.backendUrl}/users/me');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
