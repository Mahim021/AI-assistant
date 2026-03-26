import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  // ─── Current user ─────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email / Password ─────────────────────────────────────────────────────

  /// Sign in with email and password. Throws [AuthException] on failure.
  static Future<UserCredential> signInWithEmail(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e.code));
    }
  }

  /// Create account with email/password and set the display name.
  static Future<UserCredential> signUpWithEmail(
      String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e.code));
    }
  }

  // ─── Google ───────────────────────────────────────────────────────────────

  /// Opens the Google account picker showing all accounts on the device.
  /// Returns null if the user cancelled. Throws [AuthException] on failure.
  static Future<UserCredential?> signInWithGoogle({bool signUp = false}) async {
    try {
      // Force the account chooser to appear every time
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user dismissed picker

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (!signUp && isNew) {
        // New user tried to sign in — remove the auto-created account and reject
        await userCredential.user?.delete();
        await _googleSignIn.signOut();
        throw AuthException(
            'No account found with this Google account. Please sign up first.');
      }

      if (signUp && !isNew) {
        // Existing user tried to sign up — sign them back out and reject
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw AuthException(
            'An account already exists with this Google account. Please sign in instead.');
      }

      return userCredential;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e.code));
    } catch (e) {
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  // ─── Password reset ───────────────────────────────────────────────────────

  /// Sends a password-reset email via Firebase. Throws [AuthException] on failure.
  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFromCode(e.code));
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ─── Error mapping ────────────────────────────────────────────────────────

  static String _messageFromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method for this email.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

/// Typed error thrown by [AuthService] methods.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
