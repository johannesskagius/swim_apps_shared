// completed_set_configuration.dart
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/equipment.dart';
import '../stroke.dart';

@immutable
class CompletedSetConfiguration {
  // Link back to the planned set
  final String sessionSetConfigId;

  // Optional snapshot of original (useful if planned set changes later)
  final String? originalSetTitle;
  final int?
  originalPlannedDistance; // meters/yards depending on distanceUnitUsed
  final DistanceUnit? originalDistanceUnit;
  final Stroke? originalStroke;
  final EquipmentType? originalEquipment;

  // ✅ Adjustments done by swimmer before completing
  final bool wasModified;
  final double? adjustedDistance; // meters/yards
  final Stroke? adjustedStroke;
  final EquipmentType? adjustedEquipment;
  final String? adjustmentNote;

  // … any existing fields you already had (splits, reps, etc.)

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
    // … add your existing required/optional fields here
  });

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
    );
  }

  /// Convenience when committing adjustments right before save
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
          ? (this.adjustmentNote ?? '')
          : adjustmentNote,
    );
  }

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
      // … include your existing fields too
    };
  }

  static CompletedSetConfiguration fromMap(Map<String, dynamic> map) {
    String? _nameToStroke(dynamic v) => v is String ? v : (v?.toString());
    String? _nameToEquipment(dynamic v) => v is String ? v : (v?.toString());

    Stroke? _strokeFrom(dynamic v) =>
        _nameToStroke(v) == null ? null : Stroke.fromString(_nameToStroke(v)!);
    EquipmentType? _equipFrom(dynamic v) => _nameToEquipment(v) == null
        ? null
        : EquipmentType.values.firstWhereOrNull((e) => e.name == v);

    DistanceUnit? _unitFrom(dynamic v) {
      if (v is String) {
        return DistanceUnit.values.firstWhere(
          (e) => e.name == v,
          orElse: () => DistanceUnit.meters,
        );
      }
      return null;
    }

    return CompletedSetConfiguration(
      sessionSetConfigId: (map['sessionSetConfigId'] ?? '') as String,
      originalSetTitle: map['originalSetTitle'] as String?,
      originalPlannedDistance: (map['originalPlannedDistance'] as num?)
          ?.toInt(),
      originalDistanceUnit: _unitFrom(map['originalDistanceUnit']),
      originalStroke: _strokeFrom(map['originalStroke']),
      originalEquipment: _equipFrom(map['originalEquipment']),
      wasModified: (map['wasModified'] as bool?) ?? false,
      adjustedDistance: (map['adjustedDistance'] as num?)?.toDouble(),
      adjustedStroke: _strokeFrom(map['adjustedStroke']),
      adjustedEquipment: _equipFrom(map['adjustedEquipment']),
      adjustmentNote: map['adjustmentNote'] as String?,
    );
  }
}
