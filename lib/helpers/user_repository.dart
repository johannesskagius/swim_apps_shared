import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../auth_service.dart';
import '../src/objects/swimmer.dart';
import '../src/objects/user.dart';
import '../src/objects/user_types.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final AuthService _authService;

  UserRepository(this._db, {required AuthService authService})
      : _authService = authService;

  CollectionReference get usersCollection => _db.collection('users');

  CollectionReference get _coachesCollection => _db.collection('coaches');

  /// Returns a stream of the current user's profile.
  /// This is a new, robust method for the initial auth flow in your main app.
  Stream<AppUser?> myProfileStream() {
    return _authService.authStateChanges.asyncMap((user) {
      if (user != null) {
        return getUserDocument(user.uid);
      } else {
        return null;
      }
    });
  }

  /// Returns a stream of all users belonging to a specific club.
  ///
  /// This is essential for the "Manage Club" page to display a list of all
  /// members (coaches and swimmers).
  Stream<List<AppUser>> getUsersByClub(String clubId) {
    return usersCollection
        .where('clubId', isEqualTo: clubId)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          return AppUser.fromJson(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
        }).toList();
      } catch (e) {
        debugPrint("Error mapping users by club: $e");
        return <AppUser>[];
      }
    }).handleError((error) {
      debugPrint("Error in getUsersByClub stream: $error");
      return <AppUser>[];
    });
  }

  /// Returns a stream of all users created by the currently logged-in user.
  Stream<List<AppUser>> getUsersCreatedByMe() {
    final myId = _authService.currentUserId;
    if (myId == null) {
      // If there's no user logged in, return a stream with an empty list.
      return Stream.value([]);
    }

    return usersCollection
        .where('coachCreatorId', isEqualTo: myId)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          return AppUser.fromJson(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
        }).toList();
      } catch (e) {
        debugPrint("Error mapping users created by me: $e");
        return <AppUser>[];
      }
    }).handleError((error) {
      debugPrint("Error in getUsersCreatedByMe stream: $error");
      return <AppUser>[];
    });
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

    // Create the Swimmer object using the new ID.
    final newSwimmer = Swimmer(
      id: newDocRef.id,
      name: name,
      email: email,
      registerDate: DateTime.now(),
      updatedAt: DateTime.now(),
      // FIX 5: Reliably get the creator's ID from the injected service.
      creatorId: _authService.currentUserId,
      clubId: clubId,
      lastName: lastName,
    );

    newSwimmer.userType = UserType.swimmer;

    // Set the document data in Firestore.
    await newDocRef.set(newSwimmer.toJson());

    // Return the created object to be used immediately in the UI.
    return newSwimmer;
  }

  ///Updates userProfile
  Future<void> updateMyProfile({required AppUser appUser}) async {
    await usersCollection.doc(appUser.id).update(appUser.toJson());
  }

  Future<AppUser?> getUserDocument(String uid) async {
    if (uid.isEmpty) {
      debugPrint("Error: UID cannot be empty when fetching user document.");
      return null;
    }
    try {
      final DocumentSnapshot userDoc = await usersCollection.doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        return AppUser.fromJson(
          userDoc.id,
          userDoc.data() as Map<String, dynamic>,
        );
      } else {
        debugPrint("No user document found for UID: $uid");
        return null;
      }
    } catch (e) {
      debugPrint(
        "Error fetching and converting user document for UID $uid: $e",
      );
      return null;
    }
  }

  Future<List<AppUser>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }
    try {
      List<AppUser> users = [];
      // Batch requests in chunks of 30, as 'whereIn' has a limit.
      for (var i = 0; i < userIds.length; i += 30) {
        final chunk = userIds.sublist(
          i,
          i + 30 > userIds.length ? userIds.length : i + 30,
        );
        if (chunk.isEmpty) continue;

        final QuerySnapshot snapshot = await usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        users.addAll(
          snapshot.docs.map(
                (doc) =>
                AppUser.fromJson(doc.id, doc.data() as Map<String, dynamic>),
          ),
        );
      }
      return users;
    } catch (e) {
      debugPrint("Error fetching users by IDs: $e");
      return [];
    }
  }

  Future<List<Swimmer>> getAllSwimmersFromCoach({
    required String coachId,
  }) async {
    try {
      final QuerySnapshot snapshot = await usersCollection
          .where('userType', isEqualTo: UserType.swimmer.name)
          .where('coachCreatorId', isEqualTo: coachId)
          .orderBy('name')
          .get();
      return snapshot.docs
          .map(
            (doc) =>
            Swimmer.fromJson(doc.id, doc.data() as Map<String, dynamic>),
      )
          .toList();
    } catch (e) {
      debugPrint("Error fetching all swimmers from coach: $e");
      return [];
    }
  }

  Future<void> createAppUser({required AppUser newUser}) async {
    await usersCollection.doc(newUser.id).set(newUser.toJson());
  }

  Future<AppUser?> getCoach(String coachId) async {
    try {
      DocumentSnapshot doc = await _coachesCollection.doc(coachId).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting coach $coachId: $e");
      return null;
    }
  }

  Future<void> updateUser(AppUser updatedUser) async {
    await usersCollection.doc(updatedUser.id).set(updatedUser.toJson());
  }

  Future<AppUser?> getMyProfile() async {
    String? myUid = _authService.currentUserId;
    if(myUid != null) {
      return await getUserDocument(myUid);
    }
    return null;
  }
}
