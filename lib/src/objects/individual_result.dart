import 'package:flutter/foundation.dart';

class IndividualItemResult {
  String
  setItemId; // Corresponds to the ID of a SetItem in CheckPoint.testSetItems
  // OR, if testSetItems don't have IDs, use index or description.
  int
  repetitionNumber; // If the SetItem was repeated (e.g., 8x100, this is rep 1, rep 2, etc.)
  Duration? timeTaken; // e.g., for a 100m sprint
  int?
  distanceCovered; // e.g., for a T-30 test where the SetItem is "swim for 30 min"
  int? strokeCount;
  double? heartRateBPM;
  String? notes; // Notes for this specific item/repetition

  IndividualItemResult({
    required this.setItemId, // Or a way to identify which test item this result is for
    this.repetitionNumber = 1,
    this.timeTaken,
    this.distanceCovered,
    this.strokeCount,
    this.heartRateBPM,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'setItemId': setItemId,
      'repetitionNumber': repetitionNumber,
      'timeTaken_ms': timeTaken?.inMilliseconds,
      'distanceCovered': distanceCovered,
      'strokeCount': strokeCount,
      'heartRateBPM': heartRateBPM,
      'notes': notes,
    };
  }

  /// Creates an IndividualItemResult instance from a JSON map.
  factory IndividualItemResult.fromJson(Map<String, dynamic> json) {
    Duration? parseTimeTaken(dynamic ms) {
      if (ms == null) return null;
      if (ms is int) {
        return Duration(milliseconds: ms);
      }
      // You could add more robust parsing if ms might be a string representation of int
      throw FormatException("Invalid format for timeTaken_ms: $ms");
    }

    return IndividualItemResult(
      setItemId: json['setItemId'] as String,
      repetitionNumber: json['repetitionNumber'] as int? ?? 1,
      // Default if null or missing
      timeTaken: parseTimeTaken(json['timeTaken_ms']),
      distanceCovered: json['distanceCovered'] as int?,
      strokeCount: json['strokeCount'] as int?,
      heartRateBPM: json['heartRateBPM'] as double?,
      // JSON numbers can be int or double
      notes: json['notes'] as String?,
    );
  }

  /// Creates a copy of this IndividualItemResult but with the given fields replaced with the new values.
  IndividualItemResult copyWith({
    String? setItemId,
    int? repetitionNumber,
    Duration? timeTaken, // Direct Duration for copyWith
    ValueGetter<Duration?>? getTimeTaken, // For explicit null setting
    int? distanceCovered,
    ValueGetter<int?>? getDistanceCovered,
    int? strokeCount,
    ValueGetter<int?>? getStrokeCount,
    double? heartRateBPM,
    ValueGetter<double?>? getHeartRateBPM,
    String? notes,
    ValueGetter<String?>? getNotes,
  }) {
    final actualTimeTaken = getTimeTaken != null
        ? getTimeTaken()
        : (timeTaken ?? this.timeTaken);
    final actualDistanceCovered = getDistanceCovered != null
        ? getDistanceCovered()
        : (distanceCovered ?? this.distanceCovered);
    final actualStrokeCount = getStrokeCount != null
        ? getStrokeCount()
        : (strokeCount ?? this.strokeCount);
    final actualHeartRateBPM = getHeartRateBPM != null
        ? getHeartRateBPM()
        : (heartRateBPM ?? this.heartRateBPM);
    final actualNotes = getNotes != null ? getNotes() : (notes ?? this.notes);

    return IndividualItemResult(
      setItemId: setItemId ?? this.setItemId,
      repetitionNumber: repetitionNumber ?? this.repetitionNumber,
      timeTaken: actualTimeTaken,
      distanceCovered: actualDistanceCovered,
      strokeCount: actualStrokeCount,
      heartRateBPM: actualHeartRateBPM,
      notes: actualNotes,
    );
  }
}