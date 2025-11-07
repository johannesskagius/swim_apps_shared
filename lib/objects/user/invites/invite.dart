import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/objects/user/invites/swimmer_invite.dart';

import 'coach_invite.dart';

// Using enums is safer and cleaner than "magic strings"
enum InviteRole { coach, swimmer }
enum InviteStatus { pending, accepted, declined }

/// A base class for all club invitations.
abstract class Invite {
  final String? id;
  final String inviterId;
  final String inviterName;
  final String clubId;
  final String inviteeEmail;
  final String? inviteeName; // Optional name from the invite form
  final DateTime sentAt;
  final InviteRole role;
  final InviteStatus status;

  Invite({
    this.id,
    required this.inviterId,
    required this.inviterName,
    required this.clubId,
    required this.inviteeEmail,
    required this.sentAt,
    required this.role,
    this.inviteeName,
    this.status = InviteStatus.pending, // Default to pending
  });

  /// Factory constructor to deserialize JSON into the correct subclass
  /// based on the 'role' field in the data.
  factory Invite.fromJson(Map<String, dynamic> json) {
    final roleString = json['role'] as String;

    if (roleString == InviteRole.coach.name) {
      return CoachInvite.fromJson(json);
    }
    if (roleString == InviteRole.swimmer.name) {
      return SwimmerInvite.fromJson(json);
    }
    throw ArgumentError('Unknown invite role: $roleString');
  }

  /// Base toJson method that subclasses will use.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'clubId': clubId,
      'inviteeEmail': inviteeEmail,
      'inviteeName': inviteeName,
      'sentAt': Timestamp.fromDate(sentAt),
      'role': role.name, // Store the enum's name as a string
      'status': status.name, // Store the enum's name as a string
    };
  }

  /// Helper for subclasses to safely parse the status string from JSON.
  static InviteStatus statusFromString(String? status) {
    return InviteStatus.values.firstWhere(
          (e) => e.name == status,
      orElse: () => InviteStatus.pending, // Default if null or invalid
    );
  }
}