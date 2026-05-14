import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

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

  Future<User?> signUpWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _syncUserToBackend(user, name: name.trim(), phone: phone.trim());
      await user.sendEmailVerification();
      await _auth.signOut(); // counteract Firebase's auto-login after signup
      return user;
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<User?> signInWithGoogle() async {
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

      // Sync to backend only on first sign-in
      if (cred.additionalUserInfo?.isNewUser ?? false) {
        await _syncUserToBackend(
          user,
          name: user.displayName ?? '',
          phone: user.phoneNumber ?? '',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _friendlyErrorMessage(e.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
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
    } catch (_) {
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
