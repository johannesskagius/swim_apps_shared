import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';

/// Represents a full race analysis, ready to be stored in Firestore.
/// This class contains both high-level summary statistics for the entire race
/// and standardized per-25m data for detailed analysis over time.
class RaceAnalysis {
  final String? id;
  String? eventName;
  String? raceName;
  DateTime? raceDate;
  PoolLength? poolLength; // Changed to PoolLength enum
  Stroke? stroke;
  int? distance;
  String? coachId;
  String? swimmerId;
  List<AnalyzedSegment> segments;

  // --- OVERALL RACE SUMMARY STATS ---
  int finalTime; // Total race time in milliseconds
  double totalDistance; // Sum of all segment distances
  final int totalStrokes;
  final double averageSpeedMetersPerSecond;
  final double averageStrokeFrequency; // Weighted by time
  final double averageStrokeLengthMeters; // Weighted by distance

  // --- STANDARDIZED INTERVAL STATS ---
  final List<int> splits25m; // Interpolated split times at each 25m mark
  final List<int> splits50m; // Interpolated split times at each 50m mark
  final List<double> speedPer25m; // Speed for each 25m interval (m/s)
  final List<int> strokesPer25m; // Strokes for each 25m interval
  final List<double> frequencyPer25m; // Frequency for each 25m interval
  final List<double> strokeLengthPer25m; // Stroke length for each 25m interval

  /// The main constructor, which takes all fields.
  RaceAnalysis({
    this.id,
    required this.eventName,
    required this.raceName,
    required this.raceDate,
    required this.poolLength,
    required this.stroke,
    required this.distance,
    required this.segments,
    this.coachId,
    this.swimmerId,
    // Overall stats
    required this.finalTime,
    required this.totalDistance,
    required this.totalStrokes,
    required this.averageSpeedMetersPerSecond,
    required this.averageStrokeFrequency,
    required this.averageStrokeLengthMeters,
    // Per-25m stats
    required this.splits25m,
    required this.splits50m,
    required this.speedPer25m,
    required this.strokesPer25m,
    required this.frequencyPer25m,
    required this.strokeLengthPer25m,
  });

  /// Factory constructor to create a Race from raw segments, with automatic
  /// calculation of all summary and interval statistics.
  factory RaceAnalysis.fromSegments({
    String? id,
    required String eventName,
    required String raceName,
    required DateTime raceDate,
    required PoolLength poolLength, // Changed to PoolLength enum
    required Stroke stroke,
    required int distance,
    required List<AnalyzedSegment> segments,
    String? coachId,
    String? swimmerId,
  }) {
    // --- Overall Summary Calculations ---
    final finalTime =
        segments.map((s) => s.splitTimeMillis).fold(0, (a, b) => a + b);
    final totalDistance =
        segments.map((s) => s.distanceMeters).fold(0.0, (a, b) => a + b);
    final totalStrokes =
        segments.map((s) => s.strokes ?? 0).fold(0, (a, b) => a + b);

    final averageSpeed = (totalDistance > 0 && finalTime > 0)
        ? (totalDistance / (finalTime / 1000.0))
        : 0.0;

    double totalWeightedFreq = 0;
    double totalWeightedLength = 0;
    int totalTimeForFreq = 0;
    double totalDistForLength = 0;

    for (final segment in segments) {
      if (segment.strokeFrequency != null) {
        totalWeightedFreq += segment.strokeFrequency! * segment.splitTimeMillis;
        totalTimeForFreq += segment.splitTimeMillis;
      }
      if (segment.strokeLengthMeters != null) {
        totalWeightedLength +=
            segment.strokeLengthMeters! * segment.distanceMeters;
        totalDistForLength += segment.distanceMeters;
      }
    }
    final avgFreq =
        (totalTimeForFreq > 0) ? totalWeightedFreq / totalTimeForFreq : 0.0;
    final avgLength = (totalDistForLength > 0)
        ? totalWeightedLength / totalDistForLength
        : 0.0;

    // --- Standardized Interval Calculations ---
    final splits25m = _calculateStandardizedSplits(segments, 25);
    final splits50m = _calculateStandardizedSplits(segments, 50);
    final speedPer25m = _calculateSpeedPer25m(splits25m);
    final otherMetrics = _calculateMetricsPer25m(segments, splits25m.length);

    return RaceAnalysis(
      id: id,
      eventName: eventName,
      raceName: raceName,
      raceDate: raceDate,
      poolLength: poolLength,
      stroke: stroke,
      distance: distance,
      segments: segments,
      coachId: coachId,
      swimmerId: swimmerId,
      finalTime: finalTime,
      totalDistance: totalDistance,
      totalStrokes: totalStrokes,
      averageSpeedMetersPerSecond: averageSpeed,
      averageStrokeFrequency: avgFreq,
      averageStrokeLengthMeters: avgLength,
      splits25m: splits25m,
      splits50m: splits50m,
      speedPer25m: speedPer25m,
      strokesPer25m: List<int>.from(otherMetrics['strokes']!),
      frequencyPer25m: List<double>.from(otherMetrics['frequencies']!),
      strokeLengthPer25m: List<double>.from(otherMetrics['lengths']!),
    );
  }

  // --- CALCULATION HELPERS ---
  /// Calculates speed for each 25m interval based on split times.
  static List<double> _calculateSpeedPer25m(List<int> splits25m) {
    if (splits25m.isEmpty) return [];
    final List<double> speeds = [];
    int previousSplitTime = 0;
    for (final splitTime in splits25m) {
      final intervalTime = splitTime - previousSplitTime;
      final speed = (intervalTime > 0) ? (25.0 / (intervalTime / 1000.0)) : 0.0;
      speeds.add(speed);
      previousSplitTime = splitTime;
    }
    return speeds;
  }

  /// Calculates strokes, frequency, and length per 25m by finding which
  /// segment contains the midpoint of each 25m interval.
  static Map<String, List<dynamic>> _calculateMetricsPer25m(
    List<AnalyzedSegment> segments,
    int numIntervals,
  ) {
    if (segments.isEmpty) {
      return {'strokes': [], 'frequencies': [], 'lengths': []};
    }

    final List<int> strokes = [];
    final List<double> frequencies = [];
    final List<double> lengths = [];

    double cumulativeDistance = 0;
    int segmentIndex = 0;

    for (int i = 0; i < numIntervals; i++) {
      final double midpointDistance = (i * 25.0) + 12.5;

      // Advance segmentIndex to find the segment containing the midpoint
      while (segmentIndex < segments.length - 1 &&
          (cumulativeDistance + segments[segmentIndex].distanceMeters) <
              midpointDistance) {
        cumulativeDistance += segments[segmentIndex].distanceMeters;
        segmentIndex++;
      }

      final segment = segments[segmentIndex];
      strokes.add(segment.strokes ?? 0);
      frequencies.add(segment.strokeFrequency ?? 0.0);
      lengths.add(segment.strokeLengthMeters ?? 0.0);
    }
    return {'strokes': strokes, 'frequencies': frequencies, 'lengths': lengths};
  }

  /// Calculates split times at standardized intervals (e.g., every 25m)
  /// by interpolating from the variable-length segments.
  static List<int> _calculateStandardizedSplits(
    List<AnalyzedSegment> segments,
    int intervalDistance,
  ) {
    if (segments.isEmpty || intervalDistance <= 0) return [];

    final List<int> splits = [];
    double targetDistance = intervalDistance.toDouble();
    double cumulativeDistance = 0;
    int cumulativeTime = 0;
    int segmentIndex = 0;
    final double totalRaceDistance =
        segments.map((s) => s.distanceMeters).fold(0.0, (a, b) => a + b);

    while (targetDistance <= totalRaceDistance + 0.1) {
      // Epsilon for floating point
      while (segmentIndex < segments.length &&
          (cumulativeDistance + segments[segmentIndex].distanceMeters) <
              targetDistance) {
        cumulativeDistance += segments[segmentIndex].distanceMeters;
        cumulativeTime += segments[segmentIndex].splitTimeMillis;
        segmentIndex++;
      }

      if (segmentIndex >= segments.length) break;

      final currentSegment = segments[segmentIndex];
      final double distanceIntoSegment = targetDistance - cumulativeDistance;

      if (currentSegment.distanceMeters == 0) {
        if (distanceIntoSegment == 0) splits.add(cumulativeTime);
        targetDistance += intervalDistance;
        continue;
      }

      final double fractionOfSegment =
          distanceIntoSegment / currentSegment.distanceMeters;
      final int timeForFraction =
          (fractionOfSegment * currentSegment.splitTimeMillis).round();
      splits.add(cumulativeTime + timeForFraction);

      targetDistance += intervalDistance;
    }
    return splits;
  }

  /// Converts this object into a Map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'raceName': raceName,
      if (raceDate != null) 'raceDate': Timestamp.fromDate(raceDate!),
      if (poolLength != null) 'poolLength': poolLength!.name,
      // Convert enum to its string name
      if (stroke != null) 'stroke': stroke!.name,
      'distance': distance,
      'segments': segments.map((s) => s.toJson()).toList(),
      'coachId': coachId,
      'swimmerId': swimmerId,
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

  /// Creates a Race object from a Firestore document.
  factory RaceAnalysis.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return RaceAnalysis(
      id: doc.id,
      eventName: data['eventName'] as String?,
      raceName: data['raceName'] as String?,
      raceDate:
          data['raceDate'] != null ? (data['raceDate'] as Timestamp).toDate() : null,
      poolLength: PoolLength.values.byName(
        data['poolLength'] as String? ?? 'unknown',
      ),
      stroke: Stroke.values.byName(data['stroke'] as String? ?? 'unknown'),
      distance: data['distance'] as int,
      segments: (data['segments'] as List<dynamic>)
          .map((s) => AnalyzedSegment.fromMap(s as Map<String, dynamic>))
          .toList(),
      coachId: data['coachId'] as String?,
      swimmerId: data['swimmerId'] as String?,
      finalTime: data['finalTime'] as int,
      totalDistance: (data['totalDistance'] as num).toDouble(),
      totalStrokes: data['totalStrokes'] as int,
      averageSpeedMetersPerSecond:
          (data['averageSpeedMetersPerSecond'] as num).toDouble(),
      averageStrokeFrequency:
          (data['averageStrokeFrequency'] as num).toDouble(),
      averageStrokeLengthMeters:
          (data['averageStrokeLengthMeters'] as num).toDouble(),
      splits25m: List<int>.from(data['splits25m'] as List),
      splits50m: List<int>.from(data['splits50m'] as List),
      speedPer25m: List<double>.from(data['speedPer25m'] as List),
      strokesPer25m: List<int>.from(data['strokesPer25m'] as List),
      frequencyPer25m: List<double>.from(data['frequencyPer25m'] as List),
      strokeLengthPer25m:
          List<double>.from(data['strokeLengthPer25m'] as List),
    );
  }
}
