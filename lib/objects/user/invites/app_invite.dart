import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_enums.dart';
import 'invite_type.dart';

@immutable
class AppInvite {
  final String id;
  final String inviterId;
  final String inviterEmail;
  final String inviteeEmail;
  final InviteType type;
  final App app;
  final DateTime createdAt;
  final bool accepted;
  final String? acceptedUserId;
  final String? clubId;
  final String? relatedEntityId;
  final DateTime? acceptedAt;

  const AppInvite({
    required this.id,
    required this.inviterId,
    required this.inviterEmail,
    required this.inviteeEmail,
    required this.type,
    required this.app,
    required this.createdAt,
    required this.accepted,
    this.acceptedUserId,
    this.clubId,
    this.relatedEntityId,
    this.acceptedAt,
  });

  factory AppInvite.fromJson(String id, Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Unsupported date value type: ${v.runtimeType}');
    }

    DateTime? parseDateNullable(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return AppInvite(
      id: id,
      inviterId: json['inviterId'] as String,
      inviterEmail: json['inviterEmail'] as String? ?? '',
      inviteeEmail: json['inviteeEmail'] as String,
      type: InviteType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => InviteType.coachToSwimmer,
      ),
      app: App.values.firstWhere(
            (e) => e.name == json['app'],
        orElse: () => App.swimAnalyzer,
      ),
      createdAt: parseDate(json['createdAt']),
      accepted: json['accepted'] as bool? ?? false,
      acceptedUserId: json['acceptedUserId'] as String?,
      clubId: json['clubId'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      acceptedAt: parseDateNullable(json['acceptedAt']),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'inviterId': inviterId,
      'inviterEmail': inviterEmail,
      'inviteeEmail': inviteeEmail,
      'type': type.name,
      'app': app.name,
      'createdAt': createdAt,
      'accepted': accepted,
      'acceptedUserId': acceptedUserId,
      'clubId': clubId,
      'relatedEntityId': relatedEntityId,
      'acceptedAt': acceptedAt,
    };
  }

  AppInvite copyWith({
    String? inviterId,
    String? inviterEmail,
    String? inviteeEmail,
    InviteType? type,
    App? app,
    DateTime? createdAt,
    bool? accepted,
    String? acceptedUserId,
    String? clubId,
    String? relatedEntityId,
    DateTime? acceptedAt,
  }) {
    return AppInvite(
      id: id,
      inviterId: inviterId ?? this.inviterId,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      inviteeEmail: inviteeEmail ?? this.inviteeEmail,
      type: type ?? this.type,
      app: app ?? this.app,
      createdAt: createdAt ?? this.createdAt,
      accepted: accepted ?? this.accepted,
      acceptedUserId: acceptedUserId ?? this.acceptedUserId,
      clubId: clubId ?? this.clubId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
