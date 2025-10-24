import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';

import 'base_repository.dart';

class AnalyzesRepository extends BaseRepository {
  final FirebaseFirestore _db;
  final FirebaseCrashlytics _crashlytics;

  AnalyzesRepository(this._db, {FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  // --- Collection References with Robust Converters ---

  /// Helper to create a collection reference with a converter that handles
  /// data parsing errors gracefully.
  CollectionReference<T> _getCollection<T>({
    required String path,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromFirestore,
    required Map<String, Object?> Function(T, SetOptions?) toFirestore,
  }) {
    return _db
        .collection(path)
        .withConverter<T>(
          fromFirestore: (snapshot, _) {
            // This try-catch block handles potential errors during data parsing.
            try {
              if (!snapshot.exists || snapshot.data() == null) {
                // This is a valid case, but good to be aware of if an ID was expected to exist.
                throw Exception(
                  "Document ${snapshot.id} in '$path' does not exist or has null data.",
                );
              }
              return fromFirestore(snapshot);
            } catch (e, s) {
              final errorMsg =
                  "Failed to parse document ${snapshot.id} in '$path'. Error: $e";
              debugPrint("🔥 $errorMsg");
              // Report the parsing error to Crashlytics as a non-fatal issue.
              _crashlytics.recordError(e, s, reason: errorMsg, fatal: false);
              // FIX: Rethrow the error to be caught by the calling method,
              // which will then skip this individual document.
              rethrow;
            }
          },
          toFirestore: toFirestore,
        );
  }

  // --- Race Analyses ---
  CollectionReference<RaceAnalysis> get _racesRef =>
      _getCollection<RaceAnalysis>(
        path: 'racesAnalyzes',
        fromFirestore: (snapshot) => RaceAnalysis.fromFirestore(snapshot),
        toFirestore: (race, _) => race.toJson(),
      );

  // --- Off The Block Analyses ---
  CollectionReference<OffTheBlockAnalysisData> get _offTheBlockRef =>
      _getCollection<OffTheBlockAnalysisData>(
        path: 'offTheBlockAnalyzes',
        fromFirestore: (snapshot) =>
            OffTheBlockAnalysisData.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (analysis, _) => analysis.toMap(),
      );

  // --- CRUD Methods for Off The Block Analyses ---

  /// Generic helper to execute a Firestore query and handle potential errors.
  Future<List<T>> _fetchFromQuery<T>(
    Query<T> query,
    String operationDescription,
  ) async {
    try {
      final snapshot = await query.get();
      // FIX: Safely parse each document, skipping any that fail.
      final List<T> results = [];
      for (final doc in snapshot.docs) {
        try {
          results.add(doc.data());
        } catch (e) {
          // The error has already been logged by the converter.
          debugPrint(
            "Skipping document ${doc.id} in '$operationDescription' due to parsing error.",
          );
        }
      }
      return results;
    } catch (e, s) {
      debugPrint("🔥 Error during '$operationDescription': $e");
      _crashlytics.recordError(
        e,
        s,
        reason: operationDescription,
        fatal: false,
      );
      return [];
    }
  }

  Future<DocumentReference<OffTheBlockAnalysisData>> saveOffTheBlock(
    OffTheBlockAnalysisData analysisData,
  ) {
    return _offTheBlockRef.add(analysisData);
  }

  Future<List<OffTheBlockAnalysisData>> getOffTheBlockAnalysesForUser(
    String userId,
  ) {
    final query = _offTheBlockRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('date', descending: true);
    return _fetchFromQuery(
      query,
      'getOffTheBlockAnalysesForUser for user $userId',
    );
  }

  Stream<List<OffTheBlockAnalysisData>> getStreamOfOffTheBlockAnalysesForUser(
    String userId,
  ) {
    return _offTheBlockRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        // FIX: Safely map documents in the stream.
        .map((snapshot) {
          final List<OffTheBlockAnalysisData> results = [];
          for (final doc in snapshot.docs) {
            try {
              results.add(doc.data());
            } catch (e) {
              debugPrint(
                "Skipping document ${doc.id} in stream due to parsing error.",
              );
            }
          }
          return results;
        });
  }

  Stream<List<OffTheBlockAnalysisData>> getStreamOfOffTheBlockAnalysesForClub(
    String clubId,
  ) {
    return _offTheBlockRef
        .where('clubId', isEqualTo: clubId)
        .orderBy('date', descending: true)
        .snapshots()
        // FIX: Safely map documents in the stream.
        .map((snapshot) {
          final List<OffTheBlockAnalysisData> results = [];
          for (final doc in snapshot.docs) {
            try {
              results.add(doc.data());
            } catch (e) {
              debugPrint(
                "Skipping document ${doc.id} in stream due to parsing error.",
              );
            }
          }
          return results;
        });
  }

  Future<List<OffTheBlockAnalysisData>> getOffTheBlockAnalysesByIds({
    required List<String> analysisIds,
  }) async {
    if (analysisIds.isEmpty) return [];

    try {
      final chunks = _splitList(analysisIds, 30);
      List<OffTheBlockAnalysisData> allAnalyses = [];

      for (final chunk in chunks) {
        final query = _offTheBlockRef.where(
          FieldPath.documentId,
          whereIn: chunk,
        );
        final snapshot = await query.get();
        // FIX: Safely parse each document.
        for (final doc in snapshot.docs) {
          try {
            allAnalyses.add(doc.data());
          } catch (e) {
            debugPrint(
              "Skipping document ${doc.id} in batch fetch due to parsing error.",
            );
          }
        }
      }

      final analysisMap = {for (var a in allAnalyses) a.id: a};
      return analysisIds
          .map((id) => analysisMap[id])
          .whereType<OffTheBlockAnalysisData>()
          .toList();
    } catch (e, s) {
      final reason = 'getOffTheBlockAnalysesByIds failed';
      debugPrint("🔥 Error: $reason. $e");
      _crashlytics.recordError(e, s, reason: reason, fatal: false);
      return [];
    }
  }

  List<List<T>> _splitList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  Future<OffTheBlockAnalysisData?> getOffTheBlockAnalysis(
    String analysisId,
  ) async {
    try {
      final doc = await _offTheBlockRef.doc(analysisId).get();
      return doc.data();
    } catch (e, s) {
      final reason = 'getOffTheBlockAnalysis for ID $analysisId failed';
      debugPrint("🔥 Error: $reason. $e");
      _crashlytics.recordError(e, s, reason: reason, fatal: false);
      return null;
    }
  }

  Future<void> updateOffTheBlockAnalysis(OffTheBlockAnalysisData analysis) =>
      _offTheBlockRef.doc(analysis.id).update(analysis.toMap());

  Future<void> deleteOffTheBlockAnalysis(String analysisId) =>
      _offTheBlockRef.doc(analysisId).delete();

  // --- CRUD Methods for Race Analyses ---

  Future<List<RaceAnalysis>> getRacesForUser(String userId) {
    final query = _racesRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('raceDate', descending: true);
    return _fetchFromQuery(query, 'getRacesForUser for user $userId');
  }

  Stream<List<RaceAnalysis>> getStreamOfRacesForUser(String userId) {
    return _racesRef
        .where('swimmerId', isEqualTo: userId)
        .orderBy('raceDate', descending: true)
        .snapshots()
        // FIX: Safely map documents in the stream.
        .map((snapshot) {
          final List<RaceAnalysis> results = [];
          for (final doc in snapshot.docs) {
            try {
              results.add(doc.data());
            } catch (e) {
              debugPrint(
                "Skipping race document ${doc.id} in stream due to parsing error.",
              );
            }
          }
          return results;
        });
  }

  Future<RaceAnalysis?> getRace(String raceId) async {
    try {
      final doc = await _racesRef.doc(raceId).get();
      return doc.data();
    } catch (e, s) {
      final reason = 'getRace for ID $raceId failed';
      debugPrint("🔥 Error: $reason. $e");
      _crashlytics.recordError(e, s, reason: reason, fatal: false);
      return null;
    }
  }

  Future<void> addRace(RaceAnalysis race) => _racesRef.add(race);

  Future<void> updateRace(RaceAnalysis race) =>
      _racesRef.doc(race.id).update(race.toJson());

  Future<void> deleteRace(String raceId) => _racesRef.doc(raceId).delete();
}
