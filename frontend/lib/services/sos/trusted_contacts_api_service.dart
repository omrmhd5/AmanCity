import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/sos/trusted_app_contact.dart';

class TrustedContactsApiService {
  static const _base = '${AppConfig.backendUrl}/users';

  static Future<String?> _idToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// Returns all trusted contacts for the current user (all statuses).
  static Future<List<TrustedAppContact>> getContacts() async {
    try {
      final token = await _idToken();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse('$_base/trusted-contacts'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => TrustedAppContact.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Searches users by name or phone.
  static Future<List<TrustedAppContact>> searchUsers(String query) async {
    try {
      final token = await _idToken();
      if (token == null) return [];
      final uri = Uri.parse(
        '$_base/search',
      ).replace(queryParameters: {'q': query});
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map(
              (e) => TrustedAppContact.fromJson({
                ...(e as Map<String, dynamic>),
                'status': 'pending_sent', // placeholder before request is sent
              }),
            )
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Sends a contact request to [toUserId].
  static Future<bool> sendRequest(String toUserId) async {
    try {
      final token = await _idToken();
      if (token == null) return false;
      final res = await http.post(
        Uri.parse('$_base/trusted-contacts/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'toUserId': toUserId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Accepts or declines an incoming contact request from [fromUserId].
  static Future<bool> respondToRequest(
    String fromUserId, {
    required bool accept,
  }) async {
    try {
      final token = await _idToken();
      if (token == null) return false;
      final res = await http.patch(
        Uri.parse('$_base/trusted-contacts/$fromUserId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'accept': accept}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Removes a contact relationship by [contactUserId].
  static Future<bool> removeContact(String contactUserId) async {
    try {
      final token = await _idToken();
      if (token == null) return false;
      final res = await http.delete(
        Uri.parse('$_base/trusted-contacts/$contactUserId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
