import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/repositories/invite_repository.dart';
import 'package:swim_apps_shared/objects/user/invites/app_enums.dart';
import 'package:swim_apps_shared/objects/user/invites/app_invite.dart';
import 'package:swim_apps_shared/objects/user/invites/invite_type.dart';

class InviteService {
  final InviteRepository _inviteRepository;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  InviteService({
    InviteRepository? inviteRepository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _inviteRepository = inviteRepository ?? InviteRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // --------------------------------------------------------------------------
  // ✉️ INVITE CREATION
  // --------------------------------------------------------------------------

  /// 📩 Send an invite from the current user to another email.
  Future<void> sendInvite({
    required String email,
    required InviteType type,
    required App app,
    String? relatedEntityId,
    String? clubId,
  }) async {
    final inviter = _auth.currentUser;
    if (inviter == null) throw Exception('No logged-in user.');

    final inviteId = 'invite_${DateTime.now().millisecondsSinceEpoch}';

    final invite = AppInvite(
      id: inviteId,
      inviterId: inviter.uid,
      inviterEmail: inviter.email ?? '',
      inviteeEmail: email.trim().toLowerCase(),
      type: type,
      app: app,
      createdAt: DateTime.now(),
      accepted: false,
      acceptedUserId: null,
      clubId: clubId,
      relatedEntityId: relatedEntityId,
      acceptedAt: null,
    );

    await _inviteRepository.sendInvite(invite);
  }

  // --------------------------------------------------------------------------
  // 🧩 NEW: INVITE + PRE-CREATE USER PROFILE
  // --------------------------------------------------------------------------

  /// 📬 Sends an invite **and** immediately creates a "pending" user profile
  /// under `/users/{email}`. This allows the club roster to show invited users
  /// even if they haven't signed up yet.
  Future<void> sendInviteAndCreatePendingUser({
    required String email,
    required InviteType type,
    required App app,
    required String inviterId,
    required String clubId,
    String? message,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // 1️⃣ Create the invite first
    await sendInvite(
      email: normalizedEmail,
      type: type,
      app: app,
      clubId: clubId,
      relatedEntityId: clubId,
    );

    // 2️⃣ Pre-create pending user document
    final docId = normalizedEmail.replaceAll('.', ','); // safer Firestore key
    final pendingUserRef = _firestore.collection('users').doc(docId);

    final role = type == InviteType.clubInvite ? 'coach' : 'swimmer';

    await pendingUserRef.set({
      'email': normalizedEmail,
      'role': role,
      'status': 'pending', // pending | active
      'createdAt': FieldValue.serverTimestamp(),
      'invitedBy': inviterId,
      'clubId': clubId,
      'app': app.name,
      if (message != null && message.isNotEmpty) 'inviteMessage': message,
    }, SetOptions(merge: true));

    debugPrint('✅ Pending user created for $normalizedEmail ($role)');
  }

  // --------------------------------------------------------------------------
  // ✅ ACCEPT / REVOKE
  // --------------------------------------------------------------------------

  Future<void> acceptInvite(String inviteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');
    await _inviteRepository.acceptInvite(inviteId, user.uid);
  }

  Future<void> revokeInvite(String inviteId) async {
    await _inviteRepository.revokeInvite(inviteId);
  }

  // --------------------------------------------------------------------------
  // 🔍 LOOKUPS
  // --------------------------------------------------------------------------

  Future<List<AppInvite>> getMyAcceptedSwimmers() async {
    final coach = _auth.currentUser;
    if (coach == null) throw Exception('No logged-in coach.');
    return _inviteRepository.getAcceptedSwimmersForCoach(coach.uid);
  }

  Future<List<AppInvite>> getMyAcceptedCoaches() async {
    final swimmer = _auth.currentUser;
    if (swimmer == null) throw Exception('No logged-in swimmer.');
    return _inviteRepository.getAcceptedCoachesForSwimmer(swimmer.uid);
  }

  Future<bool> hasLinkWith(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');
    return _inviteRepository.isLinked(
      inviterId: user.uid,
      acceptedUserId: otherUserId,
    );
  }

  // --------------------------------------------------------------------------
  // 🏢 CLUB / EMAIL CONTEXTUAL QUERIES
  // --------------------------------------------------------------------------

  Future<List<AppInvite>> getPendingInvitesByClub(String clubId) async {
    try {
      return await _inviteRepository.getPendingInvitesByClub(clubId);
    } catch (e) {
      debugPrint('❌ Failed to fetch pending invites by club: $e');
      rethrow;
    }
  }

  Future<AppInvite?> getInviteByEmail(String email) async {
    try {
      final normalized = email.trim().toLowerCase();
      final invites = await _inviteRepository.getInvitesByEmail(normalized);

      if (invites.isEmpty) return null;
      invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return invites.firstWhere(
            (i) => !i.accepted,
        orElse: () => invites.first,
      );
    } catch (e, st) {
      debugPrint('❌ Failed to fetch invite by email: $e\n$st');
      rethrow;
    }
  }

  Future<String?> getAppForInviteEmail(String email) async {
    final invite = await getInviteByEmail(email);
    if (invite == null) return null;
    return invite.app.name;
  }
}
