import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final FirebaseFunctions _functions;

  InviteService({
    InviteRepository? inviteRepository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _inviteRepository = inviteRepository ?? InviteRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  // --------------------------------------------------------------------------
  // ✉️ SEND INVITE (delegates Firestore + email to Cloud Function)
  // --------------------------------------------------------------------------

  Future<void> sendInvite({
    required String email,
    required InviteType type,
    required App app,
    String? clubId,
    String? groupId,
    String? clubName,
  }) async {
    final inviter = _auth.currentUser;
    if (inviter == null) throw Exception('No logged-in user.');

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final callable = _functions.httpsCallable('sendInviteEmail');
      final result = await callable.call({
        'email': normalizedEmail,
        'senderId': inviter.uid,
        'senderName': inviter.displayName ?? inviter.email ?? 'A Swimify coach',
        'clubId': clubId,
        'groupId': groupId,
        'type': type.name,
        'clubName': clubName,
        'app': app.name,
      });

      final data = Map<String, dynamic>.from(result.data ?? {});
      if (data['success'] == true) {
        debugPrint('✅ Invite sent successfully to $normalizedEmail (ID: ${data['inviteId']})');
      } else {
        throw Exception(data['message'] ?? 'Failed to send invite');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('❌ Error sending invite: $e\n$st');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // 🧩 SEND INVITE + CREATE PENDING USER
  // --------------------------------------------------------------------------

  Future<void> sendInviteAndCreatePendingUser({
    required String email,
    required InviteType type,
    required App app,
    required String inviterId,
    required String clubId,
    String? clubName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Send via Cloud Function
    await sendInvite(
      email: normalizedEmail,
      type: type,
      app: app,
      clubId: clubId,
      clubName: clubName,
    );

    // Locally pre-create pending user in Firestore
    final safeDocId = normalizedEmail.replaceAll('.', ',');
    final ref = _firestore.collection('users').doc(safeDocId);

    final role = type == InviteType.clubInvite ? 'coach' : 'swimmer';

    await ref.set({
      'email': normalizedEmail,
      'role': role,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'invitedBy': inviterId,
      'clubId': clubId,
      'app': app.name,
    }, SetOptions(merge: true));

    debugPrint('✅ Pending user created locally for $normalizedEmail');
  }

  // --------------------------------------------------------------------------
  // ✅ ACCEPT / REVOKE INVITES
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
      return invites.firstWhere((i) => !i.accepted, orElse: () => invites.first);
    } catch (e, st) {
      debugPrint('❌ Failed to fetch invite by email: $e\n$st');
      rethrow;
    }
  }

  Future<String?> getAppForInviteEmail(String email) async {
    final invite = await getInviteByEmail(email);
    return invite?.app.name;
  }
}
