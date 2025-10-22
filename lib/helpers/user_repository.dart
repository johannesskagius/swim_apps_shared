import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../auth_service.dart';
import '../src/objects/swimmer.dart';
import '../src/objects/user.dart';
import '../src/objects/user_types.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final AuthService _authService;
  // Added a private instance of FirebaseCrashlytics for error reporting.
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  UserRepository(this._db, {required AuthService authService})
      : _authService = authService;

  CollectionReference get usersCollection => _db.collection('users');

  // This collection seems to be unused in favor of 'users', but the getter is kept.
  CollectionReference get _coachesCollection => _db.collection('coaches');

  /// Returns a stream of the current user's profile.
  /// This is a new, robust method for the initial auth flow in your main app.
  Stream<AppUser?> myProfileStream() {
    return _authService.authStateChanges.asyncMap((user) {
      if (user != null) {
        // Now safely handles potential errors from getUserDocument.
        return getUserDocument(user.uid);
      } else {
        // If there is no authenticated user, emit null.
        return null;
      }
    });
  }

  /// Refactored Logic: A generic stream transformer to handle snapshot mapping.
  /// This reduces code duplication and centralizes the error handling logic
  /// for converting Firestore snapshots into a list of `AppUser` objects.
  Stream<List<AppUser>> _mapToUserList(Stream<QuerySnapshot> stream) {
    return stream.map((snapshot) {
      // Use a separate function to safely parse the documents.
      return _parseUserDocuments(snapshot.docs);
    }).handleError((e, s) {
      // Catch any errors from the stream itself (e.g., permission denied).
      debugPrint("Error in user stream: $e");
      // Report the error to Crashlytics for monitoring.
      _crashlytics.recordError(e, s,
          reason: 'A Firestore stream in UserRepository failed.');
      // Return an empty list as a safe fallback for the UI.
      return <AppUser>[];
    });
  }

  /// Refactored Logic: A helper function to parse a list of documents.
  /// This isolates the parsing logic, making it reusable and easier to test.
  /// It includes robust error handling for each document.
  List<AppUser> _parseUserDocuments(List<QueryDocumentSnapshot> docs) {
    final users = <AppUser>[];
    for (final doc in docs) {
      try {
        // Attempt to parse each document.
        users.add(AppUser.fromJson(
          doc.id,
          doc.data() as Map<String, dynamic>,
        ));
      } catch (e, s) {
        // If a single document fails to parse, log the error and continue.
        // This prevents one bad document from breaking the entire list.
        debugPrint(
            "Failed to parse user document ${doc.id}: $e");
        _crashlytics.recordError(e, s,
            reason: 'Failed to parse a user document with ID: ${doc.id}');
      }
    }
    return users;
  }

  /// Returns a stream of all users belonging to a specific club.
  /// This is essential for the "Manage Club" page to display a list of all
  /// members (coaches and swimmers).
  Stream<List<AppUser>> getUsersByClub(String clubId) {
    // Input validation to prevent unnecessary Firestore queries.
    if (clubId.isEmpty) {
      debugPrint("getUsersByClub called with an empty clubId.");
      return Stream.value([]);
    }

    final stream = usersCollection
        .where('clubId', isEqualTo: clubId)
        .snapshots();
    // Use the refactored stream transformer to handle mapping and errors.
    return _mapToUserList(stream);
  }

  /// Returns a stream of all users created by the currently logged-in user.
  Stream<List<AppUser>> getUsersCreatedByMe() {
    final myId = _authService.currentUserId;
    if (myId == null) {
      // If there's no user logged in, return a stream with an empty list.
      return Stream.value([]);
    }

    final stream = usersCollection
        .where('coachCreatorId', isEqualTo: myId)
        .snapshots();
    // Re-use the same stream transformer for consistency and robustness.
    return _mapToUserList(stream);
  }

  ///Creates a new swimmer with optional
  ///name & email are musts!
  Future<Swimmer> createSwimmer({
    String? clubId,
    String? lastName,
    required String name,
    required String email,
  }) async {
    // Generate a new document reference with a unique ID from Firestore.
    final newDocRef = usersCollection.doc();
    final creatorId = _authService.currentUserId;

    // Defensive check: A user must be logged in to create another user.
    if (creatorId == null) {
      throw Exception(
          'No authenticated user found. Cannot create a new swimmer.');
    }

    final newSwimmer = Swimmer(
      id: newDocRef.id,
      name: name,
      email: email,
      registerDate: DateTime.now(),
      updatedAt: DateTime.now(),
      creatorId: creatorId,
      clubId: clubId,
      lastName: lastName,
    );

    newSwimmer.userType = UserType.swimmer;

    // Set the document data in Firestore. Added try-catch for network/permission errors.
    try {
      await newDocRef.set(newSwimmer.toJson());
      // Return the created object to be used immediately in the UI.
      return newSwimmer;
    } catch (e, s) {
      debugPrint("Error creating swimmer in Firestore: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to create swimmer.');
      // Re-throw the exception to let the caller handle the UI update (e.g., show an error message).
      throw Exception('Failed to save the new swimmer. Please try again.');
    }
  }

  ///Updates userProfile
  Future<void> updateMyProfile({required AppUser appUser}) async {
    try {
      await usersCollection.doc(appUser.id).update(appUser.toJson());
    } catch (e, s) {
      debugPrint("Error updating user profile for ${appUser.id}: $e");
      _crashlytics.recordError(e, s,
          reason: 'Failed to update user profile.');
      // Propagate the error so the UI layer can inform the user.
      throw Exception('Failed to update profile.');
    }
  }

  Future<AppUser?> getUserDocument(String uid) async {
    // Early exit if UID is invalid, preventing a pointless Firestore read.
    if (uid.isEmpty) {
      debugPrint("Error: UID cannot be empty when fetching user document.");
      return null;
    }
    try {
      final DocumentSnapshot userDoc = await usersCollection.doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        // The parsing logic itself is wrapped in a try-catch.
        // If `AppUser.fromJson` fails due to bad data, we can handle it gracefully.
        try {
          return AppUser.fromJson(
            userDoc.id,
            userDoc.data() as Map<String, dynamic>,
          );
        } catch (e, s) {
          debugPrint("Error parsing user document for UID $uid: $e");
          _crashlytics.recordError(e, s,
              reason: 'Data parsing failed for user document with UID: $uid');
          return null;
        }
      } else {
        // This is not an error, but a valid case where the user doesn't exist.
        // Logged for debugging purposes.
        debugPrint("No user document found for UID: $uid");
        return null;
      }
    } catch (e, s) {
      // This catches errors from the `.get()` call itself (e.g., network issues, permissions).
      debugPrint("Error fetching user document for UID $uid: $e");
      _crashlytics.recordError(e, s,
          reason: 'Firestore fetch failed for user document with UID: $uid');
      return null;
    }
  }

  Future<List<AppUser>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }
    try {
      // The batching logic is sound. This try-catch will handle any
      // errors during the batched `get()` calls.
      final users = <AppUser>[];
      for (var i = 0; i < userIds.length; i += 30) {
        final chunk = userIds.sublist(
          i,
          i + 30 > userIds.length ? userIds.length : i + 30,
        );
        if (chunk.isEmpty) continue;

        final QuerySnapshot snapshot = await usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        // Use the robust parsing helper function here as well.
        users.addAll(_parseUserDocuments(snapshot.docs));
      }
      return users;
    } catch (e, s) {
      debugPrint("Error fetching users by IDs: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to fetch users by IDs.');
      return [];
    }
  }

  /// A generic helper to fetch and parse swimmers based on a query.
  /// This reduces duplication between `getAllSwimmersFromCoach` and `getSwimmersForClub`.
  Future<List<Swimmer>> _fetchSwimmers(Query query, String errorContext) async {
    try {
      final snapshot = await query.get();
      final swimmers = <Swimmer>[];
      for (final doc in snapshot.docs) {
        try {
          swimmers.add(Swimmer.fromJson(doc.id, doc.data() as Map<String, dynamic>));
        } catch (e, s) {
          debugPrint("Failed to parse swimmer document ${doc.id} in $errorContext: $e");
          _crashlytics.recordError(e, s, reason: 'Failed to parse swimmer ${doc.id}');
        }
      }
      return swimmers;
    } catch (e, s) {
      debugPrint("Error fetching swimmers for $errorContext: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to fetch swimmers for $errorContext');
      return [];
    }
  }


  Future<List<Swimmer>> getAllSwimmersFromCoach({
    required String coachId,
  }) async {
    // Build the query.
    final query = usersCollection
        .where('userType', isEqualTo: UserType.swimmer.name)
        .where('coachCreatorId', isEqualTo: coachId)
        .orderBy('name');
    // Use the generic fetch function.
    return _fetchSwimmers(query, 'coach $coachId');
  }

  /// Fetches a list of swimmers for a specific club.
  Future<List<Swimmer>> getSwimmersForClub({
    required String clubId,
  }) async {
    // Build the query.
    final query = usersCollection
        .where('clubId', isEqualTo: clubId)
        .where('userType', isEqualTo: UserType.swimmer.name)
        .orderBy('name');
    // Use the generic fetch function.
    return _fetchSwimmers(query, 'club $clubId');
  }

  Future<void> createAppUser({required AppUser newUser}) async {
    try {
      await usersCollection.doc(newUser.id).set(newUser.toJson());
    } catch (e, s) {
      debugPrint("Error creating app user ${newUser.id}: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to create app user.');
      throw Exception('Failed to create the user profile.');
    }
  }

  Future<AppUser?> getCoach(String coachId) async {
    // Reusing the robust `getUserDocument` is safer and more consistent
    // than having a separate implementation for fetching a coach,
    // assuming coaches are also stored in the 'users' collection.
    // If 'coaches' is a separate, legacy collection, the old logic can be kept but improved.
    // For now, let's assume all users are in 'users'.
    final user = await getUserDocument(coachId);

    // Optional: Add a check to ensure the fetched user is actually a coach.
    if (user != null && user.userType == UserType.coach) {
      return user;
    } else if (user != null) {
      // This is a logic issue: we requested a coach but got a different user type.
      debugPrint("User $coachId was found but is not a coach.");
      // Reporting this can help identify data inconsistencies.
      _crashlytics.log('Attempted to fetch user $coachId as a coach, but they are a ${user.userType}.');
    }
    return null;
  }

  Future<void> updateUser(AppUser updatedUser) async {
    // This is an alias for updateMyProfile, let's add robust error handling here too.
    try {
      // Using `set` with merge:true can be safer than `update` if you're not sure
      // all fields exist. However, `update` is fine if the model is complete.
      // Let's stick to the original `set` for consistency with `createAppUser`.
      await usersCollection.doc(updatedUser.id).set(updatedUser.toJson());
    } catch (e, s) {
      debugPrint("Error updating user ${updatedUser.id}: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to update user.');
      throw Exception('Failed to update user data.');
    }
  }

  Future<AppUser?> getMyProfile() async {
    String? myUid = _authService.currentUserId;
    if (myUid != null) {
      // This now benefits from the improved error handling in getUserDocument.
      return await getUserDocument(myUid);
    }
    return null;
  }
}
