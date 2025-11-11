import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swim_apps_shared/objects/planned/swim_groups.dart';
import 'package:swim_apps_shared/objects/swim_club.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';


void main() {
  // ------------------------------------------------------------------
  // Setup
  // ------------------------------------------------------------------
  late FakeFirebaseFirestore fakeFirestore;
  late SwimClubRepository repository;

  // Re-initialize a fresh fake database and repository before each test
  // This ensures tests don't interfere with each other.
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = SwimClubRepository(fakeFirestore);
  });

  // ------------------------------------------------------------------
  // Club Tests
  // ------------------------------------------------------------------
  group('Club Tests', () {
    test('addClub: should add a club and return its ID', () async {
      // Arrange
      // ⭐️ UPDATED: Instantiate with all required fields.
      // The 'id' here is just a placeholder for the object,
      // Firestore will assign a new one.
      final club = SwimClub(
        id: 'temp-id',
        name: 'Wave Riders',
        creatorId: 'coach123',
        createdAt: DateTime.now(),
      );

      // Act
      final clubId = await repository.addClub(club: club);

      // Assert
      expect(clubId, isNotEmpty);
      final doc = await fakeFirestore.collection('swimClubs').doc(clubId).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], 'Wave Riders');
      expect(doc.data()?['creatorId'], 'coach123');
    });

    test('getClub: should fetch a club by its ID', () async {
      // Arrange: Manually add a club to the fake database
      // ⭐️ UPDATED: Use the model's toJson() for accuracy.
      final newClub = SwimClub(
        id: 'temp-id',
        name: 'Test Club',
        creatorId: 'coach123',
        createdAt: DateTime.now(),
      );
      final docRef = await fakeFirestore
          .collection('swimClubs')
          .add(newClub.toJson());

      // Act
      final fetchedClub = await repository.getClub(docRef.id);

      // Assert
      expect(fetchedClub, isNotNull);
      expect(fetchedClub?.id, docRef.id);
      expect(fetchedClub?.name, 'Test Club');
    });

    test('getClub: should return null for a non-existent ID', () async {
      // ... (no change)
    });

    test('getClubByCreatorId: should fetch a club by its creator ID', () async {
      // Arrange
      // ⭐️ UPDATED: Use the model's toJson() for accuracy.
      final newClub = SwimClub(
        id: 'temp-id',
        name: 'Sharks',
        creatorId: 'unique-coach-id',
        createdAt: DateTime.now(),
      );
      await fakeFirestore
          .collection('swimClubs')
          .add(newClub.toJson());

      // Act
      final fetchedClub = await repository.getClubByCreatorId('unique-coach-id');

      // Assert
      expect(fetchedClub, isNotNull);
      expect(fetchedClub?.name, 'Sharks');
    });
  });

  // ------------------------------------------------------------------
  // Group Tests
  // ------------------------------------------------------------------
  group('Group Tests', () {
    late String testClubId;

    // Before each test in *this group*, create a club to add groups to
    setUp(() async {
      final docRef = await fakeFirestore
          .collection('swimClubs')
          .add({'creatorId': 'coach123', 'name': 'Test Club'});
      testClubId = docRef.id;
    });

    test('addGroup: should add a group to the subcollection', () async {
      // Arrange
      final group = SwimGroup(name: 'Seniors', coachId: 'c1', swimmerIds: []);

      // Act
      final groupId = await repository.addGroup(testClubId, group);

      // Assert
      expect(groupId, isNotEmpty);
      final doc = await fakeFirestore
          .collection('swimClubs')
          .doc(testClubId)
          .collection('groups')
          .doc(groupId)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], 'Seniors');
    });

    test('getGroups: should fetch all groups for a club', () async {
      // Arrange
      await repository.addGroup(testClubId, SwimGroup(name: 'Seniors', coachId: 'c1', swimmerIds: []));
      await repository.addGroup(testClubId, SwimGroup(name: 'Juniors', coachId: 'c2', swimmerIds: []));

      // Act
      final groups = await repository.getGroups(testClubId);

      // Assert
      expect(groups.length, 2);
      expect(groups.any((g) => g.name == 'Seniors'), isTrue);
    });

    test('updateGroup: should update an existing group', () async {
      // Arrange
      final group = SwimGroup(name: 'Old Name', coachId: 'c1', swimmerIds: []);
      final groupId = await repository.addGroup(testClubId, group);

      // Act
      final updatedGroup = group.copyWith(id: groupId, name: 'New Name');
      await repository.updateGroup(testClubId, updatedGroup);

      // Assert
      final doc = await fakeFirestore
          .collection('swimClubs')
          .doc(testClubId)
          .collection('groups')
          .doc(groupId)
          .get();
      expect(doc.data()?['name'], 'New Name');
    });

    test('deleteGroup: should delete a group from the subcollection', () async {
      // Arrange
      final groupId = await repository.addGroup(testClubId, SwimGroup(name: 'To Delete', coachId: 'c1', swimmerIds: []));

      // Act
      await repository.deleteGroup(testClubId, groupId);

      // Assert
      final doc = await fakeFirestore
          .collection('swimClubs')
          .doc(testClubId)
          .collection('groups')
          .doc(groupId)
          .get();
      expect(doc.exists, isFalse);
    });
  });
}