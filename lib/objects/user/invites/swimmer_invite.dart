import 'package:cloud_firestore/cloud_firestore.dart';

import 'invite.dart';

class SwimmerInvite extends Invite {

  final String? groupId; // You might want to assign a group upon invite

  SwimmerInvite({
    super.id,
    required super.inviterId,
    required super.inviterName,
    required super.clubId,
    required super.inviteeEmail,
    required super.sentAt,
    super.inviteeName,
    super.status,
    this.groupId,
  }) : super(
    role: InviteRole.swimmer, // Hard-code the role
  );

  /// Factory for deserialization
  factory SwimmerInvite.fromJson(Map<String, dynamic> json) {
    return SwimmerInvite(
      id: json['id'] as String?,
      inviterId: json['inviterId'] as String,
      inviterName: json['inviterName'] as String,
      clubId: json['clubId'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      inviteeName: json['inviteeName'] as String?,
      sentAt: (json['sentAt'] as Timestamp).toDate(),
      status: Invite.statusFromString(json['status'] as String?),
      groupId: json['groupId'] as String?,
    );
  }

  /// We must override toJson to include our extra field
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['groupId'] = groupId;
    return json;
  }
}