import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../objects/user/invites/app_invite.dart';
import '../objects/user/invites/invite.dart';
import '../objects/user/invites/invite_type.dart';

class InviteRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'invites';

  InviteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  /// 📩 Send an invite (coach → swimmer, etc.)
  Future<void> sendInvite(AppInvite invite) async {
    await _collection.doc(invite.id).set(invite.toJson());
  }

  /// ✅ Accept an invite
  Future<void> acceptInvite(String inviteId, String acceptedUserId) async {
    await _collection.doc(inviteId).update({
      'accepted': true,
      'acceptedUserId': acceptedUserId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🚫 Revoke or delete an invite
  Future<void> revokeInvite(String inviteId) async {
    await _collection.doc(inviteId).update({'accepted': false});
  }

  /// 🔍 Get all invites sent by a user
  Future<List<AppInvite>> getInvitesByInviter(String inviterId,
      {bool? accepted}) async {
    Query<Map<String, dynamic>> query =
    _collection.where('inviterId', isEqualTo: inviterId);
    if (accepted != null) {
      query = query.where('accepted', isEqualTo: accepted);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => AppInvite.fromJson(d.id, d.data()))
        .toList();
  }

  /// 🔍 Get all invites received by a specific email
  Future<List<AppInvite>> getInvitesByInviteeEmail(String email,
      {bool? accepted}) async {
    Query<Map<String, dynamic>> query =
    _collection.where('inviteeEmail', isEqualTo: email);
    if (accepted != null) {
      query = query.where('accepted', isEqualTo: accepted);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => AppInvite.fromJson(d.id, d.data()))
        .toList();
  }

  /// 🔍 Get all accepted swimmers for a given coach
  Future<List<AppInvite>> getAcceptedSwimmersForCoach(String coachId) async {
    final snapshot = await _collection
        .where('inviterId', isEqualTo: coachId)
        .where('type', isEqualTo: InviteType.coachToSwimmer.name)
        .where('accepted', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((d) => AppInvite.fromJson(d.id, d.data()))
        .toList();
  }

  /// 🔍 Get all accepted coaches for a given swimmer
  Future<List<AppInvite>> getAcceptedCoachesForSwimmer(String swimmerId) async {
    final snapshot = await _collection
        .where('acceptedUserId', isEqualTo: swimmerId)
        .where('type', isEqualTo: InviteType.coachToSwimmer.name)
        .where('accepted', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((d) => AppInvite.fromJson(d.id, d.data()))
        .toList();
  }

  /// 🔎 Check if a link (invite) exists between two users
  Future<bool> isLinked({
    required String inviterId,
    required String acceptedUserId,
  }) async {
    final snapshot = await _collection
        .where('inviterId', isEqualTo: inviterId)
        .where('acceptedUserId', isEqualTo: acceptedUserId)
        .where('accepted', isEqualTo: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// 🔁 Stream accepted invites (for live UI updates)
  Stream<List<AppInvite>> streamAcceptedInvitesForCoach(String coachId) {
    return _collection
        .where('inviterId', isEqualTo: coachId)
        .where('accepted', isEqualTo: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => AppInvite.fromJson(d.id, d.data())).toList());
  }

  /// ⭐️ ADDED: Creates a new invite document.
  Future<void> addInvitation(Invite invite) async {
    try {
      await _firestore.collection('invites').doc(invite.id).set(invite.toJson());
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firestore Error adding invite: ${e.message}');
      rethrow;
    }
  }

  /// ⭐️ ADDED: Finds a specific pending invite.
  Future<Invite?> findPendingInviteByEmail(String clubId, String email) async {
    try {
      final snapshot = await _firestore
          .collection('invites')
          .where('clubId', isEqualTo: clubId)
          .where('inviteeEmail', isEqualTo: email)
          .where('status', isEqualTo: InviteStatus.pending.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Invite.fromJson(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('❌ Failed to find pending invite: $e');
      return null;
    }
  }
  Future<List<AppInvite>> getPendingInvitesByClub(String clubId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('app_invites')
          .where('clubId', isEqualTo: clubId)
          .where('accepted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppInvite.fromJson(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('❌ InviteRepository.getPendingInvitesByClub failed: $e');
      rethrow;
    }
  }
}
