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
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  UserRepository(this._db, {required AuthService authService})
      : _authService = authService;

  CollectionReference get usersCollection => _db.collection('users');
  CollectionReference get _coachesCollection => _db.collection('coaches');

  /// Stream of current user's profile.
  Stream<AppUser?> myProfileStream() {
    return _authService.authStateChanges.asyncMap((user) {
      if (user != null) {
        return getUserDocument(user.uid);
      } else {
        return null;
      }
    });
  }

  /// Maps Firestore snapshots safely into a list of AppUser objects.
  Stream<List<AppUser>> _mapToUserList(Stream<QuerySnapshot> stream) {
    return stream.map((snapshot) {
      return _parseUserDocuments(snapshot.docs);
    }).handleError((e, s) {
      debugPrint("Error in user stream: $e");
      _crashlytics.recordError(e, s,
          reason: 'A Firestore stream in UserRepository failed.');
      return <AppUser>[];
    });
  }

  /// Safely parses Firestore user documents.
  List<AppUser> _parseUserDocuments(List<QueryDocumentSnapshot> docs) {
    final users = <AppUser>[];
    for (final doc in docs) {
      try {
        final raw = doc.data();
        if (raw is! Map<String, dynamic>) {
          debugPrint(
              "⚠️ Unexpected Firestore data type for user ${doc.id}: ${raw.runtimeType}");
          continue;
        }
        users.add(AppUser.fromJson(doc.id, raw));
      } catch (e, s) {
        debugPrint("Failed to parse user document ${doc.id}: $e");
        _crashlytics.recordError(e, s,
            reason: 'Failed to parse a user document with ID: ${doc.id}');
      }
    }
    return users;
  }

  Stream<List<AppUser>> getUsersByClub(String clubId) {
    if (clubId.isEmpty) {
      debugPrint("getUsersByClub called with an empty clubId.");
      return Stream.value([]);
    }
    final stream =
    usersCollection.where('clubId', isEqualTo: clubId).snapshots();
    return _mapToUserList(stream);
  }

  Stream<List<AppUser>> getUsersCreatedByMe() {
    final myId = _authService.currentUserId;
    if (myId == null) {
      return Stream.value([]);
    }
    final stream = usersCollection
        .where('coachCreatorId', isEqualTo: myId)
        .snapshots();
    return _mapToUserList(stream);
  }

  Future<Swimmer> createSwimmer({
    String? clubId,
    String? lastName,
    required String name,
    required String email,
  }) async {
    final newDocRef = usersCollection.doc();
    final creatorId = _authService.currentUserId;

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

    try {
      await newDocRef.set(newSwimmer.toJson());
      return newSwimmer;
    } catch (e, s) {
      debugPrint("Error creating swimmer in Firestore: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to create swimmer.');
      throw Exception('Failed to save the new swimmer. Please try again.');
    }
  }

  Future<void> updateMyProfile({required AppUser appUser}) async {
    try {
      await usersCollection.doc(appUser.id).update(appUser.toJson());
    } catch (e, s) {
      debugPrint("Error updating user profile for ${appUser.id}: $e");
      _crashlytics.recordError(e, s,
          reason: 'Failed to update user profile.');
      throw Exception('Failed to update profile.');
    }
  }

  Future<AppUser?> getUserDocument(String uid) async {
    if (uid.isEmpty) {
      debugPrint("Error: UID cannot be empty when fetching user document.");
      return null;
    }
    try {
      final DocumentSnapshot userDoc = await usersCollection.doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final raw = userDoc.data();
        if (raw is! Map<String, dynamic>) {
          debugPrint(
              "⚠️ Unexpected Firestore data type for userDoc $uid: ${raw.runtimeType}");
          return null;
        }
        try {
          return AppUser.fromJson(userDoc.id, raw);
        } catch (e, s) {
          debugPrint("Error parsing user document for UID $uid: $e");
          _crashlytics.recordError(e, s,
              reason: 'Data parsing failed for user document with UID: $uid');
          return null;
        }
      } else {
        debugPrint("No user document found for UID: $uid");
        return null;
      }
    } catch (e, s) {
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
        users.addAll(_parseUserDocuments(snapshot.docs));
      }
      return users;
    } catch (e, s) {
      debugPrint("Error fetching users by IDs: $e");
      _crashlytics.recordError(e, s, reason: 'Failed to fetch users by IDs.');
      return [];
    }
  }

  Future<List<Swimmer>> _fetchSwimmers(Query query, String errorContext) async {
    try {
      final snapshot = await query.get();
      final swimmers = <Swimmer>[];
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          if (raw is! Map<String, dynamic>) {
            debugPrint(
                "⚠️ Unexpected Firestore data type for swimmer ${doc.id}: ${raw.runtimeType}");
            continue;
          }
          swimmers.add(Swimmer.fromJson(doc.id, raw));
        } catch (e, s) {
          debugPrint(
              "Failed to parse swimmer document ${doc.id} in $errorContext: $e");
          _crashlytics.recordError(e, s,
              reason: 'Failed to parse swimmer ${doc.id}');
        }
      }
      return swimmers;
    } catch (e, s) {
      debugPrint("Error fetching swimmers for $errorContext: $e");
      _crashlytics.recordError(e, s,
          reason: 'Failed to fetch swimmers for $errorContext');
      return [];
    }
  }

  Future<List<Swimmer>> getAllSwimmersFromCoach({
    required String coachId,
  }) async {
    final query = usersCollection
        .where('userType', isEqualTo: UserType.swimmer.name)
        .where('coachCreatorId', isEqualTo: coachId)
        .orderBy('name');
    return _fetchSwimmers(query, 'coach $coachId');
  }

  Future<List<Swimmer>> getSwimmersForClub({
    required String clubId,
  }) async {
    final query = usersCollection
        .where('clubId', isEqualTo: clubId)
        .where('userType', isEqualTo: UserType.swimmer.name)
        .orderBy('name');
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
    final user = await getUserDocument(coachId);
    if (user != null && user.userType == UserType.coach) {
      return user;
    } else if (user != null) {
      debugPrint("User $coachId was found but is not a coach.");
      _crashlytics.log(
          'Attempted to fetch user $coachId as a coach, but they are a ${user.userType}.');
    }
    return null;
  }

  Future<void> updateUser(AppUser updatedUser) async {
    try {
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
      return await getUserDocument(myUid);
    }
    return null;
  }
}
