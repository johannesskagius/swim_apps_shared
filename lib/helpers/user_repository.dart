import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:swim_apps_shared/helpers/base_repository.dart';

import '../auth_service.dart';
import '../src/objects/swimmer.dart';
import '../src/objects/user.dart';
import '../src/objects/user_types.dart';

class UserRepository extends BaseRepository {
  final FirebaseFirestore _db;
  final AuthService _authService;
  final FirebaseCrashlytics _crashlytics;

  UserRepository(
    this._db, {
    required AuthService authService,
    FirebaseCrashlytics? crashlytics,
  }) : _authService = authService,
       _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  CollectionReference get usersCollection => _db.collection('users');

  CollectionReference get _coachesCollection => _db.collection('coaches');

  /// Helper function to map a QuerySnapshot to a list of AppUser objects.
  /// This reduces code duplication in stream-based methods.
  List<AppUser> _mapSnapshotToUsers(QuerySnapshot snapshot) {
    final users = <AppUser>[];
    for (final doc in snapshot.docs) {
      try {
        // Refactored to use a helper for safer parsing
        final user = _parseUserDoc(doc);
        if (user != null) {
          users.add(user);
        }
      } catch (e, s) {
        // Log non-fatal parsing errors to Crashlytics to monitor data integrity issues.
        final errorMessage = "Error parsing user ${doc.id} in a stream: $e";
        debugPrint(errorMessage);
        debugPrintStack(stackTrace: s);
        _crashlytics.recordError(e, s, reason: errorMessage);
      }
    }
    return users;
  }

  /// Safely parses a DocumentSnapshot into an AppUser.
  /// Returns null if data is invalid, and logs the issue.
  AppUser? _parseUserDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is! Map<String, dynamic>) {
      // This indicates a data integrity issue, worth logging to Crashlytics.
      final errorMessage =
          "⚠️ Skipped user ${doc.id} — data type ${raw.runtimeType} is not a Map.";
      debugPrint(errorMessage);
      _crashlytics.recordError(
        Exception(errorMessage),
        null,
        reason: 'Invalid data type in Firestore',
      );
      return null;
    }
    return AppUser.fromJson(doc.id, raw);
  }

  // --- STREAM: Current User Profile ---
  Stream<AppUser?> myProfileStream() {
    return _authService.authStateChanges.asyncMap((user) {
      if (user != null) {
        return getUserDocument(user.uid);
      } else {
        return null;
      }
    });
  }

  // --- STREAM: Users by Club ---
  Stream<List<AppUser>> getUsersByClub(String clubId) {
    return usersCollection
        .where('clubId', isEqualTo: clubId)
        .snapshots()
        .map(_mapSnapshotToUsers)
        .handleError((error, stackTrace) {
          // Catch and log errors from the stream itself (e.g., permission denied).
          debugPrint("Error in getUsersByClub stream: $error");
          _crashlytics.recordError(
            error,
            stackTrace,
            reason: 'Stream failure in getUsersByClub',
          );
          return <AppUser>[];
        });
  }

  // --- STREAM: Users created by me ---
  Stream<List<AppUser>> getUsersCreatedByMe() {
    final myId = _authService.currentUserId;
    if (myId == null) return Stream.value([]);

    return usersCollection
        .where('coachCreatorId', isEqualTo: myId)
        .snapshots()
        .map(_mapSnapshotToUsers)
        .handleError((error, stackTrace) {
          // Catch and log errors from the stream itself.
          debugPrint("Error in getUsersCreatedByMe stream: $error");
          _crashlytics.recordError(
            error,
            stackTrace,
            reason: 'Stream failure in getUsersCreatedByMe',
          );
          return <AppUser>[];
        });
  }

  // --- CREATE: Swimmer ---
  Future<Swimmer> createSwimmer({
    String? clubId,
    String? lastName,
    required String name,
    required String email,
  }) async {
    final newDocRef = usersCollection.doc();
    final newSwimmer = Swimmer(
      id: newDocRef.id,
      name: name,
      email: email,
      registerDate: DateTime.now(),
      updatedAt: DateTime.now(),
      creatorId: _authService.currentUserId,
      clubId: clubId,
      lastName: lastName,
    )..userType = UserType.swimmer;

    // A try-catch block is added to handle potential Firestore write errors.
    try {
      await newDocRef.set(newSwimmer.toJson());
      return newSwimmer;
    } catch (e, s) {
      debugPrint("Error creating swimmer document: $e");
      // This is a critical failure, so we rethrow to let the caller handle it.
      _crashlytics.recordError(e, s, reason: 'Failed to create swimmer');
      throw Exception("Failed to create swimmer: $e");
    }
  }

  // --- UPDATE: Profile ---
  Future<void> updateMyProfile({required AppUser appUser}) async {
    // Added try-catch for robust error handling during updates.
    try {
      await usersCollection.doc(appUser.id).update(appUser.toJson());
    } catch (e, s) {
      debugPrint("Error updating user profile ${appUser.id}: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to update user profile');
      // Rethrow to allow the UI to show an error message.
      throw Exception("Failed to update profile: $e");
    }
  }

  // --- GET: Single User ---
  Future<AppUser?> getUserDocument(String uid) async {
    if (uid.isEmpty) {
      debugPrint("Error: UID cannot be empty when fetching user document.");
      return null;
    }

    try {
      final DocumentSnapshot userDoc = await usersCollection.doc(uid).get();

      // Added a check to ensure the document exists before processing.
      if (!userDoc.exists) {
        debugPrint("No user document found for UID: $uid");
        return null;
      }

      // Re-using the safe parsing helper function.
      return _parseUserDoc(userDoc);
    } catch (e, s) {
      debugPrint("Error fetching user document for UID $uid: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to fetch user document');
      return null;
    }
  }

  // --- GET: Batch by IDs ---
  Future<List<AppUser>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final users = <AppUser>[];
      // Firestore 'whereIn' queries are limited to 30 elements per query now.
      // This logic correctly handles batching for larger lists.
      for (var i = 0; i < userIds.length; i += 30) {
        final chunk = userIds.sublist(
          i,
          i + 30 > userIds.length ? userIds.length : i + 30,
        );
        final QuerySnapshot snapshot = await usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          try {
            // Using the safe parser for each document in the batch.
            final user = _parseUserDoc(doc);
            if (user != null) {
              users.add(user);
            }
          } catch (e, s) {
            final errorMessage = "Error parsing user ${doc.id} in batch: $e";
            debugPrint(errorMessage);
            _crashlytics.recordError(e, s, reason: errorMessage);
          }
        }
      }
      return users;
    } catch (e, s) {
      debugPrint("Error fetching users by IDs: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to fetch users by IDs');
      return [];
    }
  }

  // --- GET: All swimmers created by coach ---
  Future<List<Swimmer>> getAllSwimmersFromCoach({
    required String coachId,
  }) async {
    try {
      final QuerySnapshot snapshot = await usersCollection
          .where('userType', isEqualTo: UserType.swimmer.name)
          .where('coachCreatorId', isEqualTo: coachId)
          .orderBy('name')
          .get();

      final swimmers = <Swimmer>[];
      for (final doc in snapshot.docs) {
        final raw = doc.data();
        if (raw is! Map<String, dynamic>) {
          final msg =
              "⚠️ Skipped swimmer ${doc.id} — data type ${raw.runtimeType}.";
          debugPrint(msg);
          _crashlytics.recordError(
            Exception(msg),
            null,
            reason: 'Invalid data type for swimmer',
          );
          continue;
        }
        try {
          // It's crucial to wrap individual JSON parsing in its own try-catch.
          swimmers.add(Swimmer.fromJson(doc.id, raw));
        } catch (e, s) {
          final errorMessage = "Error parsing swimmer ${doc.id}: $e";
          debugPrint(errorMessage);
          _crashlytics.recordError(e, s, reason: errorMessage);
        }
      }
      return swimmers;
    } catch (e, s) {
      debugPrint("Error fetching swimmers from coach: $e");
      _crashlytics.recordError(
        e,
        s,
        reason: 'Failed to fetch swimmers from coach',
      );
      return [];
    }
  }

  // --- CREATE / UPDATE ---
  Future<void> createAppUser({required AppUser newUser}) async {
    try {
      await usersCollection.doc(newUser.id).set(newUser.toJson());
    } catch (e, s) {
      debugPrint("Error creating app user ${newUser.id}: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to create app user');
      throw Exception("Failed to create user: $e");
    }
  }

  Future<void> updateUser(AppUser updatedUser) async {
    try {
      await usersCollection.doc(updatedUser.id).set(updatedUser.toJson());
    } catch (e, s) {
      debugPrint("Error updating user ${updatedUser.id}: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to update user');
      throw Exception("Failed to update user: $e");
    }
  }

  // --- GET: Coach (legacy collection) ---
  Future<AppUser?> getCoach(String coachId) async {
    try {
      final doc = await _coachesCollection.doc(coachId).get();

      // Added an explicit check for document existence. This prevents crashes
      // if the coach document is not found, which is a possible scenario.
      if (!doc.exists) {
        debugPrint("Legacy coach document not found for ID: $coachId");
        return null;
      }

      final raw = doc.data();
      if (raw is! Map<String, dynamic>) {
        final msg =
            "⚠️ Skipped coach ${doc.id} — invalid type ${raw.runtimeType}.";
        debugPrint(msg);
        _crashlytics.recordError(
          Exception(msg),
          null,
          reason: 'Invalid data type for legacy coach',
        );
        return null;
      }

      // The fromJson method itself could throw an error if the data is malformed.
      // This is now caught by the outer try-catch block.
      return AppUser.fromJson(doc.id, raw);
    } catch (e, s) {
      debugPrint("Error getting coach $coachId: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to get legacy coach');
      return null;
    }
  }

  // --- GET: My Profile Shortcut ---
  Future<AppUser?> getMyProfile() async {
    final myUid = _authService.currentUserId;
    if (myUid != null) {
      // This method already has robust error handling, so we can call it safely.
      return await getUserDocument(myUid);
    }
    return null;
  }
}
