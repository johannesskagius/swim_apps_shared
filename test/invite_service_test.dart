import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:swim_apps_shared/repositories/invite_repository.dart';
import 'package:swim_apps_shared/objects/user/invites/app_invite.dart';
import 'package:swim_apps_shared/objects/user/invites/app_enums.dart';
import 'package:swim_apps_shared/objects/user/invites/invite_service.dart';
import 'package:swim_apps_shared/objects/user/invites/invite_type.dart';

// 👇 Generates mocks automatically when you run build_runner
@GenerateMocks([FirebaseAuth, User, InviteRepository])
import 'invite_service_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockInviteRepository mockRepo;
  late InviteService inviteService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockRepo = MockInviteRepository();
    fakeFirestore = FakeFirebaseFirestore();

    inviteService = InviteService(
      inviteRepository: mockRepo,
      auth: mockAuth,
      firestore: fakeFirestore, // ✅ inject fake Firestore
    );
  });

  group('InviteService', () {
    test('sendInvite should call repository with correct data', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('coach_123');
      when(mockUser.email).thenReturn('coach@example.com');

      await inviteService.sendInvite(
        email: 'swimmer@example.com',
        type: InviteType.coachToSwimmer,
        app: App.swimAnalyzer,
        clubId: 'club123',
        relatedEntityId: 'groupA',
      );

      // ✅ Capture and verify in one go
      final verification = verify(mockRepo.sendInvite(captureAny));
      verification.called(1);
      final capturedInvite = verification.captured.first as AppInvite;

      // 🔍 Assertions
      expect(capturedInvite.inviterId, 'coach_123');
      expect(capturedInvite.inviterEmail, 'coach@example.com');
      expect(capturedInvite.inviteeEmail, 'swimmer@example.com');
      expect(capturedInvite.app, App.swimAnalyzer);
      expect(capturedInvite.clubId, 'club123');
      expect(capturedInvite.relatedEntityId, 'groupA');
      expect(capturedInvite.accepted, isFalse);
    });

    test('sendInvite should throw if no logged-in user', () async {
      when(mockAuth.currentUser).thenReturn(null);

      expect(
            () => inviteService.sendInvite(
          email: 'swimmer@example.com',
          type: InviteType.coachToSwimmer,
          app: App.swimAnalyzer,
        ),
        throwsA(isA<Exception>()),
      );

      verifyNever(mockRepo.sendInvite(any));
    });

    test('acceptInvite should call repository with correct args', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('user_999');

      await inviteService.acceptInvite('invite_123');

      verify(mockRepo.acceptInvite('invite_123', 'user_999')).called(1);
    });

    test('acceptInvite should throw if no logged-in user', () async {
      when(mockAuth.currentUser).thenReturn(null);

      expect(
            () => inviteService.acceptInvite('invite_123'),
        throwsA(isA<Exception>()),
      );

      verifyNever(mockRepo.acceptInvite(any, any));
    });

    test('revokeInvite should call repository', () async {
      await inviteService.revokeInvite('invite_123');
      verify(mockRepo.revokeInvite('invite_123')).called(1);
    });

    test('getMyAcceptedSwimmers should call repository with coach UID', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('coach_555');
      when(mockRepo.getAcceptedSwimmersForCoach(any)).thenAnswer((_) async => []);

      await inviteService.getMyAcceptedSwimmers();

      verify(mockRepo.getAcceptedSwimmersForCoach('coach_555')).called(1);
    });

    test('getMyAcceptedSwimmers should throw if no logged-in coach', () async {
      when(mockAuth.currentUser).thenReturn(null);

      expect(
            () => inviteService.getMyAcceptedSwimmers(),
        throwsA(isA<Exception>()),
      );
    });

    test('getMyAcceptedCoaches should call repository with swimmer UID', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('swimmer_888');
      when(mockRepo.getAcceptedCoachesForSwimmer(any)).thenAnswer((_) async => []);

      await inviteService.getMyAcceptedCoaches();

      verify(mockRepo.getAcceptedCoachesForSwimmer('swimmer_888')).called(1);
    });

    test('getMyAcceptedCoaches should throw if no logged-in swimmer', () async {
      when(mockAuth.currentUser).thenReturn(null);

      expect(
            () => inviteService.getMyAcceptedCoaches(),
        throwsA(isA<Exception>()),
      );
    });

    test('hasLinkWith should call repository correctly', () async {
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('coach_123');

      when(mockRepo.isLinked(
        inviterId: anyNamed('inviterId'),
        acceptedUserId: anyNamed('acceptedUserId'),
      )).thenAnswer((_) async => true);

      final result = await inviteService.hasLinkWith('swimmer_456');

      expect(result, isTrue);

      verify(mockRepo.isLinked(
        inviterId: 'coach_123',
        acceptedUserId: 'swimmer_456',
      )).called(1);
    });

    test('hasLinkWith should throw if no logged-in user', () async {
      when(mockAuth.currentUser).thenReturn(null);

      expect(
            () => inviteService.hasLinkWith('swimmer_456'),
        throwsA(isA<Exception>()),
      );

      verifyNever(mockRepo.isLinked(
        inviterId: anyNamed('inviterId'),
        acceptedUserId: anyNamed('acceptedUserId'),
      ));
    });
  });
}
