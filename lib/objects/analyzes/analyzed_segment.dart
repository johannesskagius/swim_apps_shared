class AnalyzedSegment {
  final int sequence;
  final String checkPoint;
  final double distanceMeters;
  final int totalTimeMillis;
  final int splitTimeMillis;
  final int? dolphinKicks;
  final int? strokes;
  final int? breaths;
  final double? strokeFrequency;
  final double? strokeLengthMeters;

  AnalyzedSegment({
    required this.sequence,
    required this.checkPoint,
    required this.distanceMeters,
    required this.totalTimeMillis,
    required this.splitTimeMillis,
    this.dolphinKicks,
    this.strokes,
    this.breaths,
    this.strokeFrequency,
    this.strokeLengthMeters,
  });

  /// Converts this object into a Map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'sequence': sequence,
      'checkPoint': checkPoint,
      'distanceMeters': distanceMeters,
      'totalTimeMillis': totalTimeMillis,
      'splitTimeMillis': splitTimeMillis,
      'dolphinKicks': dolphinKicks,
      'strokes': strokes,
      'breaths': breaths,
      'strokeFrequency': strokeFrequency,
      'strokeLengthMeters': strokeLengthMeters,
    };
  }

  /// Creates an AnalyzedSegment from a map (typically from Firestore).
  factory AnalyzedSegment.fromMap(Map<String, dynamic> map) {
    return AnalyzedSegment(
      sequence: map['sequence'] as int,
      checkPoint: map['checkPoint'] as String,
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      totalTimeMillis: map['totalTimeMillis'] as int,
      splitTimeMillis: map['splitTimeMillis'] as int,
      dolphinKicks: map['dolphinKicks'] as int?,
      strokes: map['strokes'] as int?,
      breaths: map['breaths'] as int?,
      strokeFrequency: (map['strokeFrequency'] as num?)?.toDouble(),
      strokeLengthMeters: (map['strokeLengthMeters'] as num?)?.toDouble(),
    );
  }
}