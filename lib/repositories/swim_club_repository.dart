import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/objects/planned/swim_groups.dart';
// ⭐️ Import the new 'Invite' superclass
import 'package:swim_apps_shared/objects/swim_club.dart';

import '../objects/user/invites/invite.dart';

class SwimClubRepository {
  final FirebaseFirestore _db; // ⭐️ Defined _db
  final CollectionReference _clubsCollection;

  /// Injects the Firestore instance for testability.
  SwimClubRepository(FirebaseFirestore firestore)
    : _db = firestore,
      // ⭐️ Assign _db
      _clubsCollection = firestore.collection('swimClubs');

  /// ➕ Adds a new club to Firestore.
  Future<String> addClub({required SwimClub club}) async {
    try {
      final DocumentReference docRef = await _clubsCollection.add(
        club.toJson(),
      );
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firestore Error adding club: ${e.message}');
      rethrow;
    }
  }

  /// ⭐️ UPDATED: Fetches all pending invites from the 'invites' collection.
  Future<List<Invite>> getPendingInvitations(String clubId) async {
    try {
      final snapshot =
          await _db // Use the defined _db instance
              .collection('invites') // Query the 'invites' collection
              .where('clubId', isEqualTo: clubId)
              .where(
                'status',
                isEqualTo: InviteStatus.pending.name,
              ) // Filter by status
              .get();

      return snapshot.docs
          .map((doc) => Invite.fromJson(doc.data())) // Use Invite.fromJson
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get pending invites: $e');
      rethrow;
    }
  }

  /// ⭐️ UPDATED: Deletes a specific invite document from 'invites'.
  Future<void> deleteInvitation(String clubId, String invitationId) async {
    try {
      await _db // Use the defined _db instance
          .collection('invites') // Query the 'invites' collection
          .doc(invitationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Failed to delete invite: $e');
      rethrow;
    }
  }

  /// 🔹 Fetch a single SwimClub by its ID
  Future<SwimClub?> getClub(String clubId) async {
    if (clubId.isEmpty) {
      debugPrint("⚠️ Error: clubId cannot be empty.");
      return null;
    }

    try {
      final DocumentSnapshot doc = await _clubsCollection.doc(clubId).get();

      if (!doc.exists) {
        debugPrint("No club document found for ID: $clubId");
        return null;
      }

      return SwimClub.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } on FirebaseException catch (e) {
      debugPrint("🔥 Firestore Error getting club $clubId: ${e.message}");
      rethrow;
    } catch (e, s) {
      debugPrint("❌ Unexpected error while processing club $clubId: $e\n$s");
      rethrow;
    }
  }

  /// 🏊 Fetch all SwimGroups belonging to a specific SwimClub
  Future<List<SwimGroup>> getGroups(String clubId) async {
    if (clubId.isEmpty) {
      debugPrint("⚠️ getGroups called with empty clubId");
      return [];
    }

    try {
      final querySnapshot = await _clubsCollection
          .doc(clubId)
          .collection('groups')
          .get();

      final groups = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return SwimGroup.fromJson(doc.id, data);
      }).toList();

      debugPrint("✅ Fetched ${groups.length} groups for club $clubId");
      return groups;
    } on FirebaseException catch (e) {
      debugPrint(
        "🔥 Firestore Error fetching groups for club $clubId: ${e.message}",
      );
      rethrow;
    } catch (e, s) {
      debugPrint("❌ Unexpected error fetching groups for club $clubId: $e\n$s");
      rethrow;
    }
  }

  /// 🧩 Adds a new group inside a specific club’s subcollection.
  Future<String> addGroup(String clubId, SwimGroup group) async {
    if (clubId.isEmpty) throw ArgumentError('Club ID cannot be empty');
    try {
      final data = group.toJson()..remove('id');
      final ref = await _clubsCollection
          .doc(clubId)
          .collection('groups')
          .add(data);
      debugPrint("✅ Added group ${ref.id} to club $clubId");
      return ref.id;
    } on FirebaseException catch (e) {
      debugPrint(
        "🔥 Firestore Error adding group to club $clubId: ${e.message}",
      );
      rethrow;
    }
  }

  /// ✏️ Updates an existing group.
  Future<void> updateGroup(String clubId, SwimGroup group) async {
    if (clubId.isEmpty || group.id == null) {
      debugPrint("⚠️ updateGroup missing clubId or groupId");
      return;
    }

    try {
      await _clubsCollection
          .doc(clubId)
          .collection('groups')
          .doc(group.id)
          .update(group.toJson());
      debugPrint("✅ Updated group ${group.id} in club $clubId");
    } on FirebaseException catch (e) {
      debugPrint("🔥 Firestore Error updating group: ${e.message}");
      rethrow;
    }
  }

  /// ❌ Deletes a group from a club.
  Future<void> deleteGroup(String clubId, String groupId) async {
    if (clubId.isEmpty || groupId.isEmpty) {
      debugPrint("⚠️ deleteGroup missing clubId or groupId");
      return;
    }

    try {
      await _clubsCollection
          .doc(clubId)
          .collection('groups')
          .doc(groupId)
          .delete();
      debugPrint("🗑️ Deleted group $groupId from club $clubId");
    } on FirebaseException catch (e) {
      debugPrint("🔥 Firestore Error deleting group: ${e.message}");
      rethrow;
    }
  }

  /// 🔹 Fetches a club created by a specific coach (creatorId)
  Future<SwimClub?> getClubByCreatorId(String coachId) async {
    if (coachId.isEmpty) {
      debugPrint("⚠️ getClubByCreatorId called with empty coachId");
      return null;
    }

    try {
      final querySnapshot = await _clubsCollection
          .where('creatorId', isEqualTo: coachId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("ℹ️ No club found for coach $coachId");
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return SwimClub.fromJson(data, doc.id);
    } on FirebaseException catch (e) {
      debugPrint("🔥 Firestore Error getting club by creatorId: ${e.message}");
      rethrow;
    } catch (e, s) {
      debugPrint("❌ Unexpected error fetching club for coach $coachId: $e\n$s");
      rethrow;
    }
  }
}
