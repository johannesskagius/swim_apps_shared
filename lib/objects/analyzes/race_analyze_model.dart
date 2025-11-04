import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/objects/pool_length.dart';
import 'package:swim_apps_shared/objects/stroke.dart';
import '../analyzed_segment.dart';
import 'analyze_base.dart';

/// Represents a full race analysis, ready to be stored in Firestore.
/// Contains both high-level summary statistics and standardized per-25m data.
class RaceAnalysis with AnalyzableBase {
  String? eventName;
  String? raceName;
  DateTime? raceDate;
  PoolLength? poolLength;
  Stroke? stroke;
  int? distance;
  List<AnalyzedSegment> segments;

  // --- OVERALL RACE SUMMARY STATS ---
  int finalTime; // Total race time in milliseconds
  double totalDistance; // Sum of all segment distances
  int totalStrokes;
  double averageSpeedMetersPerSecond;
  double averageStrokeFrequency;
  double averageStrokeLengthMeters;

  // --- STANDARDIZED INTERVAL STATS ---
  List<int> splits25m;
  List<int> splits50m;
  List<double> speedPer25m;
  List<int> strokesPer25m;
  List<double> frequencyPer25m;
  List<double> strokeLengthPer25m;

  /// Optimization: cache for expensive computed metrics (not stored in Firestore)
  final Map<String, dynamic> _extraData = {};

  RaceAnalysis({
    String? id,
    String? coachId,
    String? swimmerId,
    String? swimmerName,
    this.eventName,
    this.raceName,
    this.raceDate,
    this.poolLength,
    this.stroke,
    this.distance,
    required this.segments,
    required this.finalTime,
    required this.totalDistance,
    required this.totalStrokes,
    required this.averageSpeedMetersPerSecond,
    required this.averageStrokeFrequency,
    required this.averageStrokeLengthMeters,
    required this.splits25m,
    required this.splits50m,
    required this.speedPer25m,
    required this.strokesPer25m,
    required this.frequencyPer25m,
    required this.strokeLengthPer25m,
  }) {
    // ✅ Assign mixin fields manually
    this.id = id;
    this.coachId = coachId;
    this.swimmerId = swimmerId;
    this.swimmerName = swimmerName;
  }

  /// Converts this object into a Firestore-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      ...analyzableBaseToJson(),
      'eventName': eventName,
      'raceName': raceName,
      if (raceDate != null) 'raceDate': Timestamp.fromDate(raceDate!),
      if (poolLength != null) 'poolLength': poolLength!.name,
      if (stroke != null) 'stroke': stroke!.name,
      'distance': distance,
      'segments': segments.map((s) => s.toJson()).toList(),
      'finalTime': finalTime,
      'totalDistance': totalDistance,
      'totalStrokes': totalStrokes,
      'averageSpeedMetersPerSecond': averageSpeedMetersPerSecond,
      'averageStrokeFrequency': averageStrokeFrequency,
      'averageStrokeLengthMeters': averageStrokeLengthMeters,
      'splits25m': splits25m,
      'splits50m': splits50m,
      'speedPer25m': speedPer25m,
      'strokesPer25m': strokesPer25m,
      'frequencyPer25m': frequencyPer25m,
      'strokeLengthPer25m': strokeLengthPer25m,
    };
  }

  /// Creates a RaceAnalysis object from a Firestore document.
  factory RaceAnalysis.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data()!;
    final race = RaceAnalysis(
      id: doc.id,
      eventName: data['eventName'],
      raceName: data['raceName'],
      raceDate:
      data['raceDate'] != null ? (data['raceDate'] as Timestamp).toDate() : null,
      poolLength: PoolLength.values.byName(data['poolLength'] ?? 'unknown'),
      stroke: Stroke.values.byName(data['stroke'] ?? 'unknown'),
      distance: data['distance'],
      segments: (data['segments'] as List<dynamic>)
          .map((s) => AnalyzedSegment.fromMap(s as Map<String, dynamic>))
          .toList(),
      finalTime: data['finalTime'],
      totalDistance: (data['totalDistance'] as num).toDouble(),
      totalStrokes: data['totalStrokes'],
      averageSpeedMetersPerSecond:
      (data['averageSpeedMetersPerSecond'] as num).toDouble(),
      averageStrokeFrequency:
      (data['averageStrokeFrequency'] as num).toDouble(),
      averageStrokeLengthMeters:
      (data['averageStrokeLengthMeters'] as num).toDouble(),
      splits25m: List<int>.from(data['splits25m']),
      splits50m: List<int>.from(data['splits50m']),
      speedPer25m: List<double>.from(data['speedPer25m']),
      strokesPer25m: List<int>.from(data['strokesPer25m']),
      frequencyPer25m: List<double>.from(data['frequencyPer25m']),
      strokeLengthPer25m: List<double>.from(data['strokeLengthPer25m']),
    );
    race.loadAnalyzableBase(data, doc.id);
    return race;
  }

  // --- 🧠 Cached data helpers ---
  /// Stores a precomputed or UI-only value in memory (not persisted to Firestore).
  void setExtraData(String key, dynamic value) {
    _extraData[key] = value;
  }

  /// Retrieves a cached value of type [T] from memory.
  T? getExtraData<T>(String key) {
    if (_extraData.containsKey(key)) {
      return _extraData[key] as T?;
    }
    return null;
  }
}
