import 'package:cloud_firestore/cloud_firestore.dart';
// Removed: Firebase Crashlytics import is no longer needed.
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../objects/swim_club.dart';

class ClubRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _clubsCollection;

  // --- Refactoring for Simplicity ---
  // The constructor no longer accepts or initializes FirebaseCrashlytics.
  // This makes the repository more focused and easier to instantiate, especially in tests.
  ClubRepository(this._firestore)
      : _clubsCollection = _firestore.collection('swimClubs');

  /// Adds a new club to Firestore.
  ///
  /// Returns the ID of the newly created club document.
  /// Throws a [FirebaseException] if the operation fails, allowing the caller
  /// to implement specific UI feedback (e.g., showing a SnackBar with the error).
  Future<String> addClub({required SwimClub club}) async {
    try {
      // Use toJson but exclude the 'id' field, as Firestore generates it automatically.
      final data = club.toJson()..remove('id');
      final DocumentReference docRef = await _clubsCollection.add(data);
      return docRef.id;
    } on FirebaseException catch (e) {
      // --- Error Handling Improvement ---
      // The error is still caught specifically, and a descriptive message is printed
      // to the debug console for development purposes. The Crashlytics logging is removed.
      debugPrint('🔥 Firestore Error adding club: ${e.message}');
      // Re-throwing the original exception remains crucial to let the UI layer handle it.
      rethrow;
    }
  }

  /// Fetches a club's details from Firestore by its ID.
  ///
  /// Returns a [SwimClub] object on success.
  /// Returns null if the clubId is empty or if the document does not exist.
  /// Throws a [FirebaseException] for Firestore-related errors or other exceptions
  /// during data parsing, allowing the caller to differentiate between a "not found"
  /// state and a system error.
  Future<SwimClub?> getClub(String clubId) async {
    // Precondition check: An empty ID is an invalid argument.
    if (clubId.isEmpty) {
      debugPrint("⚠️ Error: clubId cannot be empty.");
      return null;
    }

    try {
      final DocumentSnapshot doc = await _clubsCollection.doc(clubId).get();

      if (!doc.exists) {
        // This is not an error but an expected outcome if the club doesn't exist.
        debugPrint("No club document found for ID: $clubId");
        return null;
      }

      // Safely parse the data. If doc.data() is null or not a Map, it will throw an
      // exception, which is caught below. This prevents crashes from malformed data.
      return SwimClub.fromJson(doc.data() as Map<String, dynamic>, doc.id);

    } on FirebaseException catch (e) {
      // --- Error Handling Improvement ---
      // This block handles specific errors from Firestore (e.g., network issues).
      // The error is logged to the console, and the exception is re-thrown.
      debugPrint("🔥 Firestore Error getting club $clubId: ${e.message}");
      rethrow;
    } catch (e, s) {
      // --- Error Handling Improvement ---
      // This is a critical fallback for any other unexpected errors, such as a data parsing
      // failure in SwimClub.fromJson. This is important for catching data consistency issues.
      // The error is logged to the console with its stack trace for easier debugging.
      debugPrint("An unexpected error occurred while processing club $clubId: $e\n$s");
      rethrow;
    }
  }
}
