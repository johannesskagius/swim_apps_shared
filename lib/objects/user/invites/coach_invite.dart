import 'package:cloud_firestore/cloud_firestore.dart';

import 'invite.dart';

class CoachInvite extends Invite {

  CoachInvite({
    super.id,
    required super.inviterId,
    required super.inviterName,
    required super.clubId,
    required super.inviteeEmail,
    required super.sentAt,
    super.inviteeName,
    super.status,
  }) : super(
    role: InviteRole.coach, // Hard-code the role
  );

  /// Factory for deserialization
  factory CoachInvite.fromJson(Map<String, dynamic> json) {
    return CoachInvite(
      id: json['id'] as String?,
      inviterId: json['inviterId'] as String,
      inviterName: json['inviterName'] as String,
      clubId: json['clubId'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      inviteeName: json['inviteeName'] as String?,
      sentAt: (json['sentAt'] as Timestamp).toDate(),
      status: Invite.statusFromString(json['status'] as String?),
    );
  }
}