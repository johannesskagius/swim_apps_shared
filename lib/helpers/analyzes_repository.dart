import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';

class AnalyzesRepository {
  final FirebaseFirestore _db;

  AnalyzesRepository(this._db);

  CollectionReference<RaceAnalysis> get _racesRef =>
      _db.collection('racesAnalyzes').withConverter<RaceAnalysis>(
            fromFirestore: (DocumentSnapshot<Map<String, dynamic>> snapshot, _) =>
                RaceAnalysis.fromFirestore(snapshot),
            toFirestore: (race, _) => race.toJson(),
          );

  CollectionReference<OffTheBlockAnalysisData> get _offTheBlockRef => _db
      .collection('offTheBlockAnalyzes')
      .withConverter<OffTheBlockAnalysisData>(
        fromFirestore: (snapshot, _) =>
            OffTheBlockAnalysisData.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (analysis, _) => analysis.toMap(),
      );

  /// Adds a new 'Off The Block' analysis to Firestore.
  Future<DocumentReference<OffTheBlockAnalysisData>> saveOffTheBlock(
      OffTheBlockAnalysisData analysisData) {
    return _offTheBlockRef.add(analysisData);
  }

  /// Fetches a list of 'Off The Block' analyses for a specific swimmer.
  Future<List<OffTheBlockAnalysisData>> getOffTheBlockAnalysesForUser(
      String userId) async {
    final snapshot = await _offTheBlockRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetches a stream of 'Off The Block' analyses for a specific swimmer.
  Stream<List<OffTheBlockAnalysisData>> getStreamOfOffTheBlockAnalysesForUser(
      String userId) {
    return _offTheBlockRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches a stream of 'Off The Block' analyses for a specific club.
  Stream<List<OffTheBlockAnalysisData>> getStreamOfOffTheBlockAnalysesForClub(
      String clubId) {
    return _offTheBlockRef
        .where('clubId', isEqualTo: clubId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Fetches a single 'Off The Block' analysis by its document ID.
  Future<OffTheBlockAnalysisData> getOffTheBlockAnalysis(
      String analysisId) async {
    final doc = await _offTheBlockRef.doc(analysisId).get();
    return doc.data()!;
  }

  /// Updates an existing 'Off The Block' analysis in Firestore.
  Future<void> updateOffTheBlockAnalysis(OffTheBlockAnalysisData analysis) {
    return _offTheBlockRef.doc(analysis.id).update(analysis.toMap());
  }

  /// Deletes an 'Off The Block' analysis from Firestore.
  Future<void> deleteOffTheBlockAnalysis(String analysisId) {
    return _offTheBlockRef.doc(analysisId).delete();
  }

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

  /// Updates an existing race in Firestore.
  Future<void> updateRace(RaceAnalysis race) {
    return _racesRef.doc(race.id).update(race.toJson());
  }

  /// Deletes a race from Firestore.
  Future<void> deleteRace(String raceId) {
    return _racesRef.doc(raceId).delete();
  }
}
