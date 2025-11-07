import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/objects/user/invites/app_enums.dart';
import 'package:swim_apps_shared/objects/user/invites/app_invite.dart';
import 'package:swim_apps_shared/objects/user/invites/invite_type.dart';

void main() {
  group('AppInvite', () {
    final now = DateTime.now();

    test('toJson and fromJson should be symmetrical (DateTime case)', () {
      final invite = AppInvite(
        id: 'invite_1',
        inviterId: 'coach_123',
        inviterEmail: 'coach@club.com',
        inviteeEmail: 'swimmer@example.com',
        type: InviteType.coachToSwimmer,
        app: App.swimAnalyzer,
        createdAt: now,
        accepted: false,
        clubId: 'club_abc',
        relatedEntityId: 'group_1',
      );

      final json = invite.toJson();
      final fromJson = AppInvite.fromJson(invite.id, json);

      expect(fromJson.id, invite.id);
      expect(fromJson.inviterId, invite.inviterId);
      expect(fromJson.inviterEmail, invite.inviterEmail);
      expect(fromJson.inviteeEmail, invite.inviteeEmail);
      expect(fromJson.type, invite.type);
      expect(fromJson.app, invite.app);
      expect(fromJson.createdAt.toIso8601String().substring(0, 19),
          invite.createdAt.toIso8601String().substring(0, 19));
      expect(fromJson.accepted, invite.accepted);
      expect(fromJson.clubId, invite.clubId);
      expect(fromJson.relatedEntityId, invite.relatedEntityId);
      expect(fromJson.acceptedAt, isNull);
    });

    test('fromJson should handle Timestamp for createdAt and acceptedAt', () {
      final timestamp = Timestamp.fromDate(now);
      final json = {
        'inviterId': 'coach_999',
        'inviterEmail': 'coach@club.com',
        'inviteeEmail': 'swimmer@example.com',
        'type': 'coachToSwimmer',
        'app': 'swimSuite',
        'createdAt': timestamp,
        'acceptedAt': timestamp,
        'accepted': true,
        'acceptedUserId': 'swimmer_123',
      };

      final invite = AppInvite.fromJson('invite_2', json);

      expect(invite.createdAt, isA<DateTime>());
      expect(invite.acceptedAt, isA<DateTime>());
      expect(invite.accepted, isTrue);
      expect(invite.app, App.swimSuite);
      expect(invite.type, InviteType.coachToSwimmer);
      expect(invite.inviterId, 'coach_999');
    });

    test('fromJson should fallback inviterEmail to empty string', () {
      final json = {
        'inviterId': 'coach_123',
        'inviteeEmail': 'swimmer@example.com',
        'type': 'coachToSwimmer',
        'app': 'swimAnalyzer',
        'createdAt': now.toIso8601String(),
      };

      final invite = AppInvite.fromJson('invite_3', json);
      expect(invite.inviterEmail, '');
      expect(invite.accepted, isFalse); // default
    });

    test('copyWith should return a new instance with updated fields', () {
      final invite = AppInvite(
        id: 'invite_4',
        inviterId: 'coach_123',
        inviterEmail: 'coach@club.com',
        inviteeEmail: 'swimmer@example.com',
        type: InviteType.coachToSwimmer,
        app: App.swimAnalyzer,
        createdAt: now,
        accepted: false,
      );

      final updated = invite.copyWith(
        accepted: true,
        acceptedUserId: 'swimmer_999',
        clubId: 'club_xyz',
      );

      expect(updated.accepted, isTrue);
      expect(updated.acceptedUserId, 'swimmer_999');
      expect(updated.clubId, 'club_xyz');
      expect(updated.id, invite.id); // unchanged
      expect(updated.inviteeEmail, invite.inviteeEmail); // unchanged
    });

    test('fromJson should parse string acceptedAt', () {
      final acceptedAt = now.toIso8601String();
      final json = {
        'inviterId': 'coach_123',
        'inviterEmail': 'coach@club.com',
        'inviteeEmail': 'swimmer@example.com',
        'type': 'coachToSwimmer',
        'app': 'swimAnalyzer',
        'createdAt': now.toIso8601String(),
        'acceptedAt': acceptedAt,
        'accepted': true,
      };

      final invite = AppInvite.fromJson('invite_5', json);
      expect(invite.acceptedAt?.toIso8601String().substring(0, 19),
          acceptedAt.substring(0, 19));
    });
  });
}
