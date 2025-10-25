import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../objects/user/swimmer_focus_profile.dart';

/// A repository for managing swimmer focus profiles in Firestore.
///
/// This class handles all database operations for SwimmerFocusProfile data,
/// including creating, reading, updating, and deleting profiles. It incorporates
/// robust error handling and logging to ensure stability and maintainability.
class SwimmerFocusProfileRepository {
  final FirebaseFirestore _db;
  final FirebaseCrashlytics _crashlytics;

  /// Creates an instance of the repository.
  ///
  /// Requires a [FirebaseFirestore] instance and an optional [FirebaseCrashlytics]
  /// instance for error reporting. If Crashlytics is not provided, a default
  /// instance will be used.
  SwimmerFocusProfileRepository(this._db, [FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  /// Provides a typed reference to the 'swimmerFocusProfile' collection
  /// for improved type safety and to prevent common data casting errors.
  CollectionReference<SwimmerFocusProfile> get _profilesCollection =>
      _db.collection('swimmerFocusProfile').withConverter<SwimmerFocusProfile>(
        fromFirestore: (snapshot, _) =>
            SwimmerFocusProfile.fromJson(snapshot.data()!),
        toFirestore: (profile, _) => profile.toJson(),
      );

  /// Saves or updates a swimmer's focus profile.
  ///
  /// It uses `SetOptions(merge: true)` to perform an upsert operation, which
  /// creates the document if it doesn't exist or updates it if it does.
  ///
  /// Throws a [FirebaseException] if the database operation fails, which should
  /// be caught and handled by the caller (e.g., showing a user-facing error).
  Future<void> saveProfile(SwimmerFocusProfile profile) async {
    try {
      await _profilesCollection.doc(profile.id).set(profile, SetOptions(merge: true));
    } on FirebaseException catch (e, s) {
      // Log the specific error to Crashlytics for debugging.
      await _crashlytics.recordError(
        e,
        s,
        reason: 'Failed to save swimmer focus profile for id: ${profile.id}',
      );
      // Re-throw the exception to allow the UI layer to handle it,
      // for instance, by showing an error message to the user.
      rethrow;
    }
  }

  /// Retrieves all focus profiles associated with a specific coach.
  ///
  /// Returns a list of [SwimmerFocusProfile] objects. If a document fails
  /// to parse (e.g., due to corrupt or outdated data), it is filtered out,
  /// and the error is logged to Crashlytics.
  ///
  /// Returns an empty list if the coach has no profiles or if an error occurs.
  Future<List<SwimmerFocusProfile>> getProfilesForCoach(String coachId) async {
    try {
      final snapshot = await _profilesCollection.where('coachId', isEqualTo: coachId).get();
      // Using a separate parsing function to handle potential data corruption
      // for individual documents without failing the entire operation.
      return _parseProfilesFromSnapshot(snapshot.docs);
    } on FirebaseException catch (e, s) {
      // If the query itself fails (e.g., due to network issues or permission errors),
      // log the error and return an empty list to prevent the app from crashing.
      await _crashlytics.recordError(
        e,
        s,
        reason: 'Failed to fetch profiles for coach id: $coachId',
      );
      return [];
    }
  }

  /// Retrieves a single focus profile for a given swimmer ID.
  ///
  /// Returns a [SwimmerFocusProfile] if the document is found and parsed
  /// successfully. Returns `null` if the document does not exist.
  ///
  /// Throws a [FirebaseException] if the database operation fails.
  Future<SwimmerFocusProfile?> getProfileForSwimmer(String swimmerId) async {
    try {
      final doc = await _profilesCollection.doc(swimmerId).get();
      // The withConverter handles the parsing, so we just need to return the data.
      // If doc.exists is false, doc.data() will be null.
      return doc.data();
    } on FirebaseException catch (e, s) {
      // Log the failure and re-throw so the caller can decide how to proceed.
      await _crashlytics.recordError(
        e,
        s,
        reason: 'Failed to fetch profile for swimmer id: $swimmerId',
      );
      rethrow;
    }
  }

  /// Deletes a swimmer's focus profile.
  ///
  /// Throws a [FirebaseException] if the database operation fails, allowing the
  /// caller to handle the error (e.g., by retrying or notifying the user).
  Future<void> deleteProfile(String swimmerId) async {
    try {
      await _profilesCollection.doc(swimmerId).delete();
    } on FirebaseException catch (e, s) {
      // Log the error and re-throw to let the caller handle the UI response.
      await _crashlytics.recordError(
        e,
        s,
        reason: 'Failed to delete profile for swimmer id: $swimmerId',
      );
      rethrow;
    }
  }

  /// A helper function to safely parse a list of document snapshots.
  ///
  /// This function isolates parsing logic. If an individual document is malformed
  /// and fails parsing, the error is logged to Crashlytics, and the document
  /// is excluded from the final list, increasing the resilience of the app.
  List<SwimmerFocusProfile> _parseProfilesFromSnapshot(
      List<QueryDocumentSnapshot<SwimmerFocusProfile>> docs) {
    final List<SwimmerFocusProfile> profiles = [];
    for (final doc in docs) {
      try {
        // The .data() method on a snapshot from a collection with a converter
        // automatically runs the fromFirestore function.
        profiles.add(doc.data());
      } catch (e, s) {
        // This catch block handles potential data corruption issues, for example,
        // if fromJson fails due to missing fields or wrong data types.
        // This is a non-fatal error, so we log it and continue.
        _crashlytics.recordError(
          e,
          s,
          reason: 'Failed to parse a swimmer focus profile with id: ${doc.id}',
        );
      }
    }
    return profiles;
  }
}
