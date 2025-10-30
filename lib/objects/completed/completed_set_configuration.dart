import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/objects/completed/completed_set_item.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/equipment.dart';
import '../planned/swim_set_config.dart';
import '../stroke.dart';

@immutable
class CompletedSetConfiguration {
  // 🔗 Link back to the planned set
  final String sessionSetConfigId;

  // 📘 Optional snapshot of original (useful if planned set changes later)
  final String? originalSetTitle;
  final int? originalPlannedDistance; // meters/yards depending on distanceUnitUsed
  final DistanceUnit? originalDistanceUnit;
  final Stroke? originalStroke;
  final EquipmentType? originalEquipment;

  // ✅ The completed items inside this set (NEW)
  final List<CompletedSetItem> completedSetItems;

  // 🧩 Adjustments done by swimmer before completing
  final bool wasModified;
  final double? adjustedDistance; // meters/yards
  final Stroke? adjustedStroke;
  final EquipmentType? adjustedEquipment;
  final String? adjustmentNote;

  // 🕒 Extra optional tracking fields
  final int? actualRepetitions;
  final Duration? actualDuration;

  const CompletedSetConfiguration({
    required this.sessionSetConfigId,
    this.originalSetTitle,
    this.originalPlannedDistance,
    this.originalDistanceUnit,
    this.originalStroke,
    this.originalEquipment,
    this.completedSetItems = const [], // ✅ NEW default empty list
    this.wasModified = false,
    this.adjustedDistance,
    this.adjustedStroke,
    this.adjustedEquipment,
    this.adjustmentNote,
    this.actualRepetitions,
    this.actualDuration,
  });

  // --------------------------------------------------------------------------
  // 🔁 Copy helpers
  // --------------------------------------------------------------------------

  CompletedSetConfiguration copyWith({
    String? sessionSetConfigId,
    String? originalSetTitle,
    int? originalPlannedDistance,
    DistanceUnit? originalDistanceUnit,
    Stroke? originalStroke,
    EquipmentType? originalEquipment,
    List<CompletedSetItem>? completedSetItems,
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
      completedSetItems: completedSetItems ?? this.completedSetItems,
      wasModified: wasModified ?? this.wasModified,
      adjustedDistance: adjustedDistance ?? this.adjustedDistance,
      adjustedStroke: adjustedStroke ?? this.adjustedStroke,
      adjustedEquipment: adjustedEquipment ?? this.adjustedEquipment,
      adjustmentNote: adjustmentNote ?? this.adjustmentNote,
      actualRepetitions: actualRepetitions ?? this.actualRepetitions,
      actualDuration: actualDuration ?? this.actualDuration,
    );
  }

  /// Convenience for marking an in-progress adjustment
  CompletedSetConfiguration copyWithAdjustments({
    double? adjustedDistance,
    Stroke? adjustedStroke,
    EquipmentType? adjustedEquipment,
    String? adjustmentNote,
  }) {
    final hasAny = adjustedDistance != null ||
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

  // --------------------------------------------------------------------------
  // 🏗️ Factory: Convert planned → completed
  // --------------------------------------------------------------------------
  factory CompletedSetConfiguration.fromSessionSetConfiguration(
      SessionSetConfiguration sessionConfig) {
    final swimSet = sessionConfig.swimSet;

    // Extract planned attributes
    final int? plannedDistance = swimSet?.totalSetDistance?.toInt();
    final EquipmentType? mainEquipment = null; // placeholder if SwimSet lacks equipment

    return CompletedSetConfiguration(
      sessionSetConfigId: sessionConfig.sessionSetConfigId,
      // 🧭 Original metadata
      originalSetTitle: swimSet?.type?.name ??
          sessionConfig.rawSetTypeHeaderFromText ??
          'Unnamed Set',
      originalPlannedDistance: plannedDistance,
      originalEquipment: mainEquipment,
      completedSetItems: const [], // ✅ start empty
      actualRepetitions: sessionConfig.repetitions,
      wasModified: false,
      adjustedDistance: null,
      adjustedStroke: null,
      adjustedEquipment: null,
      adjustmentNote: sessionConfig.notesForThisInstanceOfSet,
      actualDuration: null,
    );
  }

  // --------------------------------------------------------------------------
  // 🧾 Serialization
  // --------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'sessionSetConfigId': sessionSetConfigId,
      'originalSetTitle': originalSetTitle,
      'originalPlannedDistance': originalPlannedDistance,
      'originalDistanceUnit': originalDistanceUnit?.name,
      'originalStroke': originalStroke?.name,
      'originalEquipment': originalEquipment?.name,
      'completedSetItems':
      completedSetItems.map((item) => item.toMap()).toList(), // ✅ new field
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
    Stroke? _strokeFrom(dynamic v) =>
        v is String ? Stroke.fromString(v) : null;
    EquipmentType? _equipFrom(dynamic v) => v is String
        ? EquipmentType.values.firstWhereOrNull((e) => e.name == v)
        : null;

    DistanceUnit? _unitFrom(dynamic v) {
      if (v is String) {
        return DistanceUnit.values.firstWhereOrNull((e) => e.name == v) ??
            DistanceUnit.meters;
      }
      return null;
    }

    final List<dynamic> itemsRaw = (map['completedSetItems'] ?? []) as List<dynamic>;
    final items = itemsRaw
        .map((e) => e is Map<String, dynamic>
        ? CompletedSetItem.fromMap(e)
        : null)
        .nonNulls
        .toList();

    return CompletedSetConfiguration(
      sessionSetConfigId: (map['sessionSetConfigId'] ?? '') as String,
      originalSetTitle: map['originalSetTitle'] as String?,
      originalPlannedDistance:
      (map['originalPlannedDistance'] as num?)?.toInt(),
      originalDistanceUnit: _unitFrom(map['originalDistanceUnit']),
      originalStroke: _strokeFrom(map['originalStroke']),
      originalEquipment: _equipFrom(map['originalEquipment']),
      completedSetItems: items, // ✅ added
      wasModified: (map['wasModified'] as bool?) ?? false,
      adjustedDistance: (map['adjustedDistance'] as num?)?.toDouble(),
      adjustedStroke: _strokeFrom(map['adjustedStroke']),
      adjustedEquipment: _equipFrom(map['adjustedEquipment']),
      adjustmentNote: map['adjustmentNote'] as String?,
      actualRepetitions: (map['actualRepetitions'] as num?)?.toInt(),
      actualDuration: map['actualDurationSeconds'] != null
          ? Duration(seconds: map['actualDurationSeconds'] as int)
          : null,
    );
  }

  // --------------------------------------------------------------------------
  // ⚖️ Helpers
  // --------------------------------------------------------------------------
  bool get hasAdjustments => wasModified;

  String get summaryText {
    if (!wasModified) return "";
    final parts = <String>[];
    if (adjustedDistance != null) {
      parts.add("${adjustedDistance!.toInt()}${originalDistanceUnit?.short ?? 'm'}");
    }
    if (adjustedStroke != null) parts.add(adjustedStroke!.name);
    if (adjustedEquipment != null) parts.add(adjustedEquipment!.name);
    if (adjustmentNote != null && adjustmentNote!.isNotEmpty) {
      parts.add("\"$adjustmentNote\"");
    }
    return parts.join(" • ");
  }

  @override
  String toString() =>
      'CompletedSetConfiguration(id: $sessionSetConfigId, items: ${completedSetItems.length}, wasModified: $wasModified)';
}
