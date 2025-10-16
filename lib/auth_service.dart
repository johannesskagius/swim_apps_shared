
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Creates a new user in Firebase Auth and sends them a password reset email.
  ///
  /// This is designed for a coach creating a swimmer account.
  ///
  /// IMPORTANT: Calling `createUserWithEmailAndPassword` has a significant side effect:
  /// it signs out the currently authenticated user (the coach) and signs in the
  /// newly created user. The UI calling this method is responsible for
  /// re-authenticating the coach after this operation completes.
  ///
  /// The robust, long-term solution is to create a Cloud Function using the
  /// Firebase Admin SDK to create users, which does not affect the current
  /// user's authentication state.
  ///
  /// Returns the created `User` object on success, or `null` on failure.
  Future<User?> createSwimmerAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create the user account in Firebase Auth. This will sign out the coach.
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return null;
      }

      // 2. Update the new user's profile with their display name.
      await user.updateDisplayName(displayName);

      // 3. Send the password reset email, which acts as an invitation for
      // the swimmer to set their own password and take control of their account.
      await _firebaseAuth.sendPasswordResetEmail(email: email);

      // The new user is now signed in. The calling code must now handle
      // signing the coach back in.
      return user;
    } on FirebaseAuthException catch (e) {
      // Provide more specific feedback for common errors.
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already in use by another account.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password is too weak.');
      }
      // Re-throw for other unexpected errors.
      rethrow;
    }
  }
}
