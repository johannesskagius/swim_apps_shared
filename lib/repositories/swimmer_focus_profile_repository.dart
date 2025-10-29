import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Removed: The import for Firebase Crashlytics is no longer needed.
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../objects/user/swimmer_focus_profile.dart';

/// A repository for managing swimmer focus profiles in Firestore.
///
/// This class handles all database operations for SwimmerFocusProfile data,
/// including creating, reading, updating, and deleting profiles. It incorporates
/// robust error handling to ensure stability and maintainability.
class SwimmerFocusProfileRepository {
  final FirebaseFirestore _db;

  // --- Refactoring for Simplicity ---
  // The constructor no longer accepts or initializes FirebaseCrashlytics.
  // This makes the repository more focused and easier to instantiate, especially in tests.
  SwimmerFocusProfileRepository(this._db);

  /// Provides a typed reference to the 'swimmerFocusProfile' collection
  /// for improved type safety and to prevent common data casting errors.
  ///
  /// This converter includes basic error handling for parsing. A failure in `fromJson`
  /// will throw an exception, which is caught by the methods calling `.data()`.
  CollectionReference<SwimmerFocusProfile> get _profilesCollection =>
      _db.collection('swimmerFocusProfile').withConverter<SwimmerFocusProfile>(
        fromFirestore: (snapshot, _) {
          // This was identified as a potential crash point if snapshot.data() is null.
          // By adding a check, we make the converter more robust.
          final data = snapshot.data();
          if (data == null) {
            throw Exception(
              'Document ${snapshot.id} has null data and cannot be parsed.',
            );
          }
          return SwimmerFocusProfile.fromJson(data);
        },
        toFirestore: (profile, _) => profile.toJson(),
      );

  /// Saves or updates a swimmer's focus profile.
  ///
  /// It uses `SetOptions(merge: true)` to perform an upsert operation.
  /// Throws a [FirebaseException] if the database operation fails, which should
  /// be caught and handled by the caller.
  Future<void> saveProfile(SwimmerFocusProfile profile) async {
    try {
      await _profilesCollection
          .doc(profile.id)
          .set(profile, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // --- Error Handling Improvement ---
      // The error is still caught, and a descriptive message is printed to the
      // debug console. The Crashlytics logging is removed.
      debugPrint('🔥 Firestore Error saving profile for id ${profile.id}: $e');
      // Re-throwing the exception remains crucial to let the UI layer handle it.
      rethrow;
    }
  }

  /// Retrieves all focus profiles associated with a specific coach.
  ///
  /// Returns a list of [SwimmerFocusProfile] objects. If a document fails
  /// to parse, it is filtered out to ensure the app remains stable.
  /// Returns an empty list if the coach has no profiles or if a query error occurs.
  Future<List<SwimmerFocusProfile>> getProfilesForCoach(String coachId) async {
    try {
      final snapshot =
      await _profilesCollection.where('coachId', isEqualTo: coachId).get();
      // Using a separate parsing function to handle potential data corruption
      // for individual documents without failing the entire operation.
      return _parseProfilesFromSnapshot(snapshot.docs);
    } on FirebaseException catch (e, s) {
      // --- Error Handling Improvement ---
      // If the query itself fails, a descriptive error is printed to the console,
      // and an empty list is returned to prevent the app from crashing.
      debugPrint('🔥 Firestore Error fetching profiles for coach $coachId: $e\n$s');
      return [];
    }
  }

  /// Retrieves a single focus profile for a given swimmer ID.
  ///
  /// Returns a [SwimmerFocusProfile] if found, or `null` if the document
  /// does not exist. Throws an exception if the database operation fails.
  Future<SwimmerFocusProfile?> getProfileForSwimmer(String swimmerId) async {
    try {
      final doc = await _profilesCollection.doc(swimmerId).get();
      // The withConverter handles the parsing. If doc.exists is false, doc.data() is null.
      return doc.data();
    } on FirebaseException catch (e, s) {
      // --- Error Handling Improvement ---
      // Log the failure to the console and re-throw so the caller can handle it.
      debugPrint('🔥 Firestore Error fetching profile for swimmer $swimmerId: $e\n$s');
      rethrow;
    }
  }

  /// Deletes a swimmer's focus profile from Firestore.
  ///
  /// Throws a [FirebaseException] if the database operation fails.
  Future<void> deleteProfile(String swimmerId) async {
    try {
      await _profilesCollection.doc(swimmerId).delete();
    } on FirebaseException catch (e, s) {
      // --- Error Handling Improvement ---
      // Log the error to the console and re-throw to let the caller handle it.
      debugPrint('🔥 Firestore Error deleting profile for swimmer $swimmerId: $e\n$s');
      rethrow;
    }
  }

  /// A helper function to safely parse a list of document snapshots.
  ///
  /// This function isolates parsing logic. If an individual document is malformed
  /// and fails parsing, the error is printed to the console, and the document
  /// is excluded from the final list, increasing the app's resilience.
  List<SwimmerFocusProfile> _parseProfilesFromSnapshot(
      List<QueryDocumentSnapshot<SwimmerFocusProfile>> docs) {
    final List<SwimmerFocusProfile> profiles = [];
    for (final doc in docs) {
      try {
        // The .data() method automatically runs the `fromFirestore` converter.
        // A try-catch block here will handle any parsing failures from the converter.
        profiles.add(doc.data());
      } catch (e, s) {
        // --- Error Handling Improvement ---
        // This catches data corruption issues (e.g., fromJson fails).
        // Instead of logging to Crashlytics, we print a detailed error to the console.
        debugPrint(
          '⚠️ Failed to parse swimmer focus profile with id: ${doc.id}. Error: $e\n$s',
        );
      }
    }
    return profiles;
  }
}
