import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../objects/swim_club.dart';

class ClubRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _clubsCollection;
  final FirebaseCrashlytics _crashlytics;

  // Dependency injection is used for Firestore and Crashlytics to improve testability.
  ClubRepository(this._firestore, [FirebaseCrashlytics? crashlytics])
      : _clubsCollection = _firestore.collection('swimClubs'),
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

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
    } on FirebaseException catch (e, s) {
      // Catching a specific FirebaseException is better than a generic 'catch (e)'.
      // This allows the calling code to handle specific Firestore-related errors.
      debugPrint('Error adding club to Firestore: ${e.message}');
      // Log the specific error to Crashlytics for monitoring.
      await _crashlytics.recordError(e, s, reason: 'Failed to add club');
      // Re-throwing the original exception to let the UI layer handle it.
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
    // Precondition check: An empty ID is an invalid argument, not a system error.
    // Returning null here is appropriate as it's a predictable outcome.
    if (clubId.isEmpty) {
      debugPrint("Error: clubId cannot be empty.");
      return null;
    }

    try {
      final DocumentSnapshot doc = await _clubsCollection.doc(clubId).get();

      if (!doc.exists) {
        // This is not an error, but an expected outcome if the club doesn't exist.
        // Logging it can help debug issues where an ID was expected to exist.
        debugPrint("No club document found for ID: $clubId");
        return null;
      }

      // Safely parse the data. If doc.data() is null or not a Map, it will throw,
      // which is caught below. This prevents crashes from malformed data in Firestore.
      return SwimClub.fromJson(doc.data() as Map<String, dynamic>, doc.id);

    } on FirebaseException catch (e, s) {
      // This block handles specific errors from Firestore (e.g., network issues, permission denied).
      debugPrint("Error getting club $clubId: ${e.message}");
      // Log this non-fatal error to Crashlytics to monitor API health and reliability.
      await _crashlytics.recordError(e, s, reason: 'Failed to get club document');
      // Propagate the error so the UI can display an appropriate error message
      // instead of just showing nothing.
      rethrow;
    } catch (e, s) {
      // This is a fallback for any other unexpected errors, such as a data parsing
      // failure in SwimClub.fromJson. This is critical for catching data consistency issues.
      debugPrint("An unexpected error occurred while processing club $clubId: $e");
      await _crashlytics.recordError(e, s, reason: 'Failed to parse club data');
      // Re-throwing ensures the caller knows the operation failed unexpectedly.
      rethrow;
    }
  }
}
