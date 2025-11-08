import 'package:firebase_auth/firebase_auth.dart';
import 'package:swim_apps_shared/repositories/invite_repository.dart';
import 'package:swim_apps_shared/objects/user/invites/app_enums.dart';
import 'package:swim_apps_shared/objects/user/invites/app_invite.dart';
import 'package:swim_apps_shared/objects/user/invites/invite_type.dart';
import 'package:flutter/foundation.dart';

class InviteService {
  final InviteRepository _inviteRepository;
  final FirebaseAuth _auth;

  InviteService({
    InviteRepository? inviteRepository,
    FirebaseAuth? auth,
  })  : _inviteRepository = inviteRepository ?? InviteRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  /// 📩 Send an invite from the current user to another email
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

  /// ✅ Accept an invite
  Future<void> acceptInvite(String inviteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');

    await _inviteRepository.acceptInvite(inviteId, user.uid);
  }

  /// 🚫 Revoke an invite (e.g. coach removes swimmer)
  Future<void> revokeInvite(String inviteId) async {
    await _inviteRepository.revokeInvite(inviteId);
  }

  /// 👥 Load all swimmers for the logged-in coach
  Future<List<AppInvite>> getMyAcceptedSwimmers() async {
    final coach = _auth.currentUser;
    if (coach == null) throw Exception('No logged-in coach.');
    return _inviteRepository.getAcceptedSwimmersForCoach(coach.uid);
  }

  /// 🧭 Load all coaches for the logged-in swimmer
  Future<List<AppInvite>> getMyAcceptedCoaches() async {
    final swimmer = _auth.currentUser;
    if (swimmer == null) throw Exception('No logged-in swimmer.');
    return _inviteRepository.getAcceptedCoachesForSwimmer(swimmer.uid);
  }

  /// 🔎 Verify if user is linked (e.g., for data access)
  Future<bool> hasLinkWith(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');
    return _inviteRepository.isLinked(
      inviterId: user.uid,
      acceptedUserId: otherUserId,
    );
  }

  // --------------------------------------------------------------------------
  // 🏢 CLUB / CONTEXTUAL INVITE QUERIES (delegated to repository)
  // --------------------------------------------------------------------------

  /// 📋 Fetches all *pending* invites associated with a specific club.
  Future<List<AppInvite>> getPendingInvitesByClub(String clubId) async {
    try {
      return await _inviteRepository.getPendingInvitesByClub(clubId);
    } catch (e) {
      debugPrint('❌ Failed to fetch pending invites by club: $e');
      rethrow;
    }
  }
}
