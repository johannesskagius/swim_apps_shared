// FIX: Define a simple AuthService to abstract Firebase Auth details.
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  String? get currentUserId => _firebaseAuth.currentUser?.uid;
}