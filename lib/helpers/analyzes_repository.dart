import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/src/objects/race.dart';

class AnalyzesRepository {
  final FirebaseFirestore _db;

  AnalyzesRepository(this._db);

  CollectionReference<RaceAnalysis> get _racesRef => _db
      .collection('racesAnalyzes')
      .withConverter<RaceAnalysis>(
    fromFirestore: (snapshots, _) => RaceAnalysis.fromFirestore(snapshots),
    toFirestore: (race, _) => race.toJson(),
  );

  /// Fetches a list of races for a specific swimmer.
  Future<List<RaceAnalysis>> getRacesForUser(String userId) async {
    final snapshot = await _racesRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('raceDate', descending: true) // Sort by date
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetches a stream of races for a specific swimmer.
  Stream<List<RaceAnalysis>> getStreamOfRacesForUser(String userId) {
    return _racesRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('raceDate', descending: true) // Sort by date
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches a single race by its document ID.
  Future<RaceAnalysis> getRace(String raceId) async {
    final doc = await _racesRef.doc(raceId).get();
    return doc.data()!;
  }

  /// Adds a new race to Firestore.
  Future<void> addRace(RaceAnalysis race) {
    return _racesRef.add(race);
  }
}