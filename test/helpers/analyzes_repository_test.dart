
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swim_apps_shared/helpers/analyzes_repository.dart';
import 'package:swim_apps_shared/src/objects/race.dart';
import 'package:swim_apps_shared/src/objects/stroke.dart';
import 'package:swim_apps_shared/src/objects/pool_length.dart';

void main() {
  group('AnalyzesRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AnalyzesRepository analyzesRepository;

    // Sample data for testing
    final swimmerId1 = 'swimmer1';
    final swimmerId2 = 'swimmer2';

    final race1 = RaceAnalysis.fromSegments(
      eventName: 'Test Meet',
      raceName: '100 Free',
      raceDate: DateTime(2023, 10, 28, 10, 0),
      poolLength: PoolLength.m25,
      stroke: Stroke.freestyle,
      distance: 100,
      segments: [], // Keep segments empty for simplicity in these tests
      swimmerId: swimmerId1,
    );

    final race2 = RaceAnalysis.fromSegments(
      eventName: 'Test Meet',
      raceName: '50 Back',
      raceDate: DateTime(2023, 10, 29, 11, 0), // Newer race
      poolLength: PoolLength.m50,
      stroke: Stroke.backstroke,
      distance: 50,
      segments: [],
      swimmerId: swimmerId1,
    );

    final raceForOtherSwimmer = RaceAnalysis.fromSegments(
      eventName: 'Rival Meet',
      raceName: '100 Fly',
      raceDate: DateTime(2023, 10, 30),
      poolLength: PoolLength.m25,
      stroke: Stroke.butterfly,
      distance: 100,
      segments: [],
      swimmerId: swimmerId2,
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      analyzesRepository = AnalyzesRepository(fakeFirestore);
    });

    test('addRace and getRace should work correctly', () async {
      // Add a race and get the auto-generated document reference
      final docRef = await fakeFirestore.collection('racesAnalyzes').add(race1.toJson());

      // Use the ID from the reference to fetch the race
      final fetchedRace = await analyzesRepository.getRace(docRef.id);

      // Verify the fetched data
      expect(fetchedRace.raceName, race1.raceName);
      expect(fetchedRace.swimmerId, race1.swimmerId);
      expect(fetchedRace.raceDate, race1.raceDate);
    });

    test('getRacesForUser should fetch only the correct user s races, sorted by date', () async {
      // Add races to the fake database
      await fakeFirestore.collection('racesAnalyzes').add(race1.toJson());
      await fakeFirestore.collection('racesAnalyzes').add(race2.toJson());
      await fakeFirestore.collection('racesAnalyzes').add(raceForOtherSwimmer.toJson());

      // Fetch races for swimmer1
      final races = await analyzesRepository.getRacesForUser(swimmerId1);

      // Verify the results
      expect(races.length, 2);
      expect(races.every((race) => race.swimmerId == swimmerId1), isTrue);

      // Check for descending order by date
      expect(races[0].raceDate, race2.raceDate); // race2 is newer
      expect(races[1].raceDate, race1.raceDate);
    });

    test('getStreamOfRacesForUser should return a stream that updates', () async {
      // Fetch the stream for swimmer1
      final stream = analyzesRepository.getStreamOfRacesForUser(swimmerId1);

      // Expect the stream to initially be empty
      expect(await stream.first, isEmpty);

      // Add the first race
      await analyzesRepository.addRace(race1);

      // Expect the stream to emit a list with one race
      await expectLater(
        stream,
        emits(
          (List<RaceAnalysis> races) => races.length == 1 && races.first.raceName == race1.raceName,
        ),
      );

      // Add the second race
      await analyzesRepository.addRace(race2);

      // Expect the stream to emit an updated list with two races, sorted correctly
      await expectLater(
        stream,
        emits(
              (List<RaceAnalysis> races) =>
          races.length == 2 && races.first.raceName == race2.raceName, // race2 is newer
        ),
      );
    });

    test('getStreamOfRacesForUser should not emit for other users races', () async {
      // Get the stream for swimmer1
      final stream = analyzesRepository.getStreamOfRacesForUser(swimmerId1);

      // Expect it to be empty initially
      expect(await stream.first, isEmpty);

      // Add a race for a different swimmer
      await analyzesRepository.addRace(raceForOtherSwimmer);

      // Let a short moment pass to ensure no new events are emitted
      await Future.delayed(Duration(milliseconds: 100));

      // Re-check the stream. It should still be empty for swimmer1
      // We check this by expecting the stream to emit an empty list if we were to listen again.
      expect(await stream.first, isEmpty);
    });
  });
}
