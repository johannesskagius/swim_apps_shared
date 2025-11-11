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
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');


  /// 🔍 Fetch a single invite by its Firestore document ID.
  /// Returns an [AppInvite] if found, or `null` if not found.
  Future<AppInvite?> getInviteById(String inviteId) async {
    try {
      final doc = await _firestore.collection('invites').doc(inviteId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // ✅ Matches: factory AppInvite.fromJson(String id, Map<String, dynamic> json)
      return AppInvite.fromJson(doc.id, data);
    } catch (e, st) {
      debugPrint('❌ Error fetching invite by ID: $e\n$st');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // ✉️ SEND INVITE (Firestore first, email optional)
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

    // 🔹 Map Dart enum to backend key
    String inviteTypeKey;
    switch (type) {
      case InviteType.coachToSwimmer:
        inviteTypeKey = 'coach_invite';
        break;
      case InviteType.clubInvite:
        inviteTypeKey = 'club_invite';
        break;
      default:
        inviteTypeKey = 'generic_invite';
    }

    // 1️⃣ Create invite record directly in Firestore
    final invite = AppInvite(
      id: 'invite_${DateTime.now().millisecondsSinceEpoch}',
      inviterId: inviter.uid,
      inviterEmail: inviter.email ?? '',
      inviteeEmail: normalizedEmail,
      type: type,
      app: app,
      clubId: clubId,
      relatedEntityId: groupId,
      createdAt: DateTime.now(),
      accepted: false,
      acceptedUserId: null,
    );

    await _inviteRepository.sendInvite(invite);
    debugPrint('📄 Invite document created in Firestore for $normalizedEmail');

    // 2️⃣ Trigger email asynchronously (optional)
    try {
      final callable = _functions.httpsCallable('sendInviteEmail');
      await callable.call({
        'email': normalizedEmail,
        'senderId': inviter.uid,
        'senderName': inviter.displayName ?? inviter.email ?? 'A Swimify coach',
        'clubId': clubId,
        'groupId': groupId,
        'type': inviteTypeKey,
        'clubName': clubName,
        'app': app.name,
      });
      debugPrint('📧 Invite email sent via Cloud Function');
    } catch (e) {
      debugPrint('⚠️ Email sending failed (invite still stored): $e');
      // Don’t rethrow — Firestore record is already valid
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

    // Create invite + send email (best-effort)
    await sendInvite(
      email: normalizedEmail,
      type: type,
      app: app,
      clubId: clubId,
      clubName: clubName,
    );

    // Pre-create pending user locally in Firestore
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
// ✅ ACCEPT / REVOKE INVITES (via Cloud Functions)
// --------------------------------------------------------------------------

  /// Accepts an invite by calling the backend `respondToInvite` function.
  /// This ensures Firestore, user linking, and club membership are updated atomically.
  Future<void> acceptInvite(String inviteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');

    try {
      final callable = _functions.httpsCallable('respondToInvite');
      final result = await callable.call({
        'inviteId': inviteId,
        'action': 'accept',
        'userId': user.uid,
      });

      final data = Map<String, dynamic>.from(result.data ?? {});
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to accept invite.');
      }

      debugPrint('✅ Invite $inviteId accepted successfully by ${user.uid}');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('❌ Error in acceptInvite: $e\n$st');
      rethrow;
    }
  }

  /// Revokes (declines) an invite via the same backend function.
  /// Use this when the user explicitly declines or cancels an invitation.
  Future<void> revokeInvite(String inviteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');

    try {
      final callable = _functions.httpsCallable('respondToInvite');
      final result = await callable.call({
        'inviteId': inviteId,
        'action': 'decline',
        'userId': user.uid,
      });

      final data = Map<String, dynamic>.from(result.data ?? {});
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to decline invite.');
      }

      debugPrint('🚫 Invite $inviteId declined successfully by ${user.uid}');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FirebaseFunctionsException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('❌ Error in revokeInvite: $e\n$st');
      rethrow;
    }
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
