import 'package:flutter/foundation.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/equipment.dart';
import '../stroke.dart';

@immutable
class CompletedSetConfiguration {
  /// 🔗 Link to the planned SessionSetConfiguration this completion is based on
  final String sessionSetConfigId;

  /// 📝 Snapshot of the original set at the time it was completed
  final String? originalSetTitle;
  final int?
  originalPlannedDistance; // meters/yards depending on [originalDistanceUnit]
  final DistanceUnit? originalDistanceUnit;
  final Stroke? originalStroke;
  final EquipmentType? originalEquipment;

  /// 🧠 Adjustments the swimmer made before marking the session complete
  final bool wasModified;
  final double? adjustedDistance;
  final Stroke? adjustedStroke;
  final EquipmentType? adjustedEquipment;
  final String? adjustmentNote;

  /// 🕒 Timing & summary stats (optional, keep if you already had them)
  final int? actualRepetitions;
  final Duration? actualDuration;

  const CompletedSetConfiguration({
    required this.sessionSetConfigId,
    this.originalSetTitle,
    this.originalPlannedDistance,
    this.originalDistanceUnit,
    this.originalStroke,
    this.originalEquipment,
    this.wasModified = false,
    this.adjustedDistance,
    this.adjustedStroke,
    this.adjustedEquipment,
    this.adjustmentNote,
    this.actualRepetitions,
    this.actualDuration,
  });

  // ---------------------------------------------------------------------------
  // 🔁 COPY HELPERS
  // ---------------------------------------------------------------------------

  CompletedSetConfiguration copyWith({
    String? sessionSetConfigId,
    String? originalSetTitle,
    int? originalPlannedDistance,
    DistanceUnit? originalDistanceUnit,
    Stroke? originalStroke,
    EquipmentType? originalEquipment,
    bool? wasModified,
    double? adjustedDistance,
    Stroke? adjustedStroke,
    EquipmentType? adjustedEquipment,
    String? adjustmentNote,
    int? actualRepetitions,
    Duration? actualDuration,
  }) {
    return CompletedSetConfiguration(
      sessionSetConfigId: sessionSetConfigId ?? this.sessionSetConfigId,
      originalSetTitle: originalSetTitle ?? this.originalSetTitle,
      originalPlannedDistance:
          originalPlannedDistance ?? this.originalPlannedDistance,
      originalDistanceUnit: originalDistanceUnit ?? this.originalDistanceUnit,
      originalStroke: originalStroke ?? this.originalStroke,
      originalEquipment: originalEquipment ?? this.originalEquipment,
      wasModified: wasModified ?? this.wasModified,
      adjustedDistance: adjustedDistance ?? this.adjustedDistance,
      adjustedStroke: adjustedStroke ?? this.adjustedStroke,
      adjustedEquipment: adjustedEquipment ?? this.adjustedEquipment,
      adjustmentNote: adjustmentNote ?? this.adjustmentNote,
      actualRepetitions: actualRepetitions ?? this.actualRepetitions,
      actualDuration: actualDuration ?? this.actualDuration,
    );
  }

  /// ✏️ Convenience when saving adjustments from the edit modal
  CompletedSetConfiguration copyWithAdjustments({
    double? adjustedDistance,
    Stroke? adjustedStroke,
    EquipmentType? adjustedEquipment,
    String? adjustmentNote,
  }) {
    final hasAny =
        adjustedDistance != null ||
        adjustedStroke != null ||
        adjustedEquipment != null ||
        (adjustmentNote != null && adjustmentNote.isNotEmpty);

    return copyWith(
      wasModified: hasAny || wasModified,
      adjustedDistance: adjustedDistance ?? this.adjustedDistance,
      adjustedStroke: adjustedStroke ?? this.adjustedStroke,
      adjustedEquipment: adjustedEquipment ?? this.adjustedEquipment,
      adjustmentNote: (adjustmentNote ?? '').isEmpty
          ? this.adjustmentNote
          : adjustmentNote,
    );
  }

  // ---------------------------------------------------------------------------
  // 🗺️ SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'sessionSetConfigId': sessionSetConfigId,
      'originalSetTitle': originalSetTitle,
      'originalPlannedDistance': originalPlannedDistance,
      'originalDistanceUnit': originalDistanceUnit?.name,
      'originalStroke': originalStroke?.name,
      'originalEquipment': originalEquipment?.name,
      'wasModified': wasModified,
      'adjustedDistance': adjustedDistance,
      'adjustedStroke': adjustedStroke?.name,
      'adjustedEquipment': adjustedEquipment?.name,
      'adjustmentNote': adjustmentNote,
      'actualRepetitions': actualRepetitions,
      'actualDurationSeconds': actualDuration?.inSeconds,
    };
  }

  static CompletedSetConfiguration fromMap(Map<String, dynamic> map) {
    DistanceUnit? _distanceUnit(dynamic v) {
      if (v is String) {
        return DistanceUnit.values.firstWhere(
          (e) => e.name == v,
          orElse: () => DistanceUnit.meters,
        );
      }
      return null;
    }

    Stroke? _stroke(dynamic v) => v is String ? Stroke.fromString(v) : null;

    EquipmentType? _equipment(dynamic v) =>
        v is String ? EquipmentType.values.firstWhere((e)=> e.name == v) : null;

    return CompletedSetConfiguration(
      sessionSetConfigId: (map['sessionSetConfigId'] ?? '') as String,
      originalSetTitle: map['originalSetTitle'] as String?,
      originalPlannedDistance: (map['originalPlannedDistance'] as num?)
          ?.toInt(),
      originalDistanceUnit: _distanceUnit(map['originalDistanceUnit']),
      originalStroke: _stroke(map['originalStroke']),
      originalEquipment: _equipment(map['originalEquipment']),
      wasModified: (map['wasModified'] as bool?) ?? false,
      adjustedDistance: (map['adjustedDistance'] as num?)?.toDouble(),
      adjustedStroke: _stroke(map['adjustedStroke']),
      adjustedEquipment: _equipment(map['adjustedEquipment']),
      adjustmentNote: map['adjustmentNote'] as String?,
      actualRepetitions: (map['actualRepetitions'] as num?)?.toInt(),
      actualDuration: map['actualDurationSeconds'] != null
          ? Duration(seconds: map['actualDurationSeconds'] as int)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // ⚖️ HELPERS
  // ---------------------------------------------------------------------------

  /// Returns true if any field differs from the original plan
  bool get hasAdjustments => wasModified;

  /// Merged human-readable summary for UI
  String get summaryText {
    if (!wasModified) return "";
    final parts = <String>[];
    if (adjustedDistance != null) {
      parts.add(
        "${adjustedDistance!.toInt()}${originalDistanceUnit?.short ?? 'm'}",
      );
    }
    if (adjustedStroke != null) {
      parts.add(adjustedStroke!.name);
    }
    if (adjustedEquipment != null) {
      parts.add(adjustedEquipment!.name);
    }
    if (adjustmentNote != null && adjustmentNote!.isNotEmpty) {
      parts.add("\"$adjustmentNote\"");
    }
    return parts.join(" • ");
  }

  @override
  String toString() =>
      'CompletedSetConfiguration(id: $sessionSetConfigId, wasModified: $wasModified, adjustedDistance: $adjustedDistance, adjustedStroke: ${adjustedStroke?.name}, adjustedEquipment: ${adjustedEquipment?.name})';
}
