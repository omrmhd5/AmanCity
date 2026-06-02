import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class SocialSignInResult {
  final User user;
  final bool isNewUser;
  final String suggestedName;

  const SocialSignInResult({
    required this.user,
    required this.isNewUser,
    required this.suggestedName,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static final ValueNotifier<bool> socialProfileCompletionRequired =
      ValueNotifier(false);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns a fresh Firebase ID token for API calls.
  Future<String?> getIdToken() async {
    return _auth.currentUser?.getIdToken();
  }

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      if (!user.emailVerified) {
        await _auth.signOut();
        throw 'Please verify your email before logging in. Check your inbox for a verification link.';
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }
  }

  Future<User?> signUpWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    late User user;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = cred.user!;
      await user.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }

    // Sync to backend — non-fatal, errors are logged
    await _syncUserToBackend(user, name: name.trim(), phone: phone.trim());

    // Send verification email — non-fatal
    try {
      await user.sendEmailVerification();
    } catch (e) {
      // Silently fail — user can resend from login screen
    }

    // Always sign out after registration so the user must verify first
    try {
      await _auth.signOut();
    } catch (e) {
      // Silently fail — user is already considered signed out
    }

    return user;
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<SocialSignInResult?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user!;
      final isNewUser = cred.additionalUserInfo?.isNewUser ?? false;

      return SocialSignInResult(
        user: user,
        isNewUser: isNewUser,
        suggestedName: user.displayName ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Apple Sign-In
  // ---------------------------------------------------------------------------

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<SocialSignInResult?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      final cred = await _auth.signInWithCredential(oauthCredential);
      final user = cred.user!;
      final isNewUser = cred.additionalUserInfo?.isNewUser ?? false;

      final fullName = [
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      return SocialSignInResult(
        user: user,
        isNewUser: isNewUser,
        suggestedName: fullName.isNotEmpty
            ? fullName
            : (user.displayName ?? ''),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw 'Apple Sign-In failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }
  }

  Future<void> completeSocialProfile({
    required User user,
    required String phone,
    String name = '',
  }) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw 'Please enter your phone number.';
    }

    await _syncUserToBackend(
      user,
      name: name.trim().isNotEmpty ? name.trim() : (user.displayName ?? ''),
      phone: normalizedPhone,
    );

    final token = await user.getIdToken();
    final response = await http.put(
      Uri.parse('${AppConfig.backendUrl}/users/phone'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'phone': normalizedPhone}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      throw (data?['message'] ?? 'Failed to save phone number.').toString();
    }

    socialProfileCompletionRequired.value = false;
  }

  Future<void> cancelSocialProfileCompletion({
    bool deleteCurrentUser = false,
  }) async {
    final user = _auth.currentUser;
    if (deleteCurrentUser && user != null) {
      try {
        await user.delete();
      } on FirebaseAuthException {
        // Best-effort rollback; still sign out local session below.
      }
    }

    await signOut();
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } finally {
      socialProfileCompletionRequired.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Backend sync
  // ---------------------------------------------------------------------------

  Future<void> _syncUserToBackend(
    User user, {
    String name = '',
    String phone = '',
  }) async {
    try {
      final token = await user.getIdToken();
      await http.post(
        Uri.parse('${AppConfig.backendUrl}/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': user.email ?? '',
        }),
      );
    } catch (e) {
      // Non-fatal — user is still authenticated locally
    }
  }

  /// Maps Firebase error codes to user-friendly messages
  String _friendlyErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in or use a different email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This login method is not available.';
      case 'invalid-credential':
        return 'Login credentials are invalid or expired. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
