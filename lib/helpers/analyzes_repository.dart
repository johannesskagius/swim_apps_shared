import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/src/objects/race.dart';

class AnalyzesRepository {
  final FirebaseFirestore _db;

  AnalyzesRepository(this._db);

  CollectionReference<Race> get _racesRef => _db
      .collection('analyzes')
      .withConverter<Race>(
    fromFirestore: (snapshots, _) => Race.fromFirestore(snapshots),
    toFirestore: (race, _) => race.toJson(),
  );

  /// Fetches a list of races for a specific swimmer.
  Future<List<Race>> getRacesForUser(String userId) async {
    final snapshot = await _racesRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('raceDate', descending: true) // Sort by date
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetches a single race by its document ID.
  Future<Race> getRace(String raceId) async {
    final doc = await _racesRef.doc(raceId).get();
    return doc.data()!;
  }

  /// Adds a new race to Firestore.
  Future<void> addRace(Race race) {
    return _racesRef.add(race);
  }
}