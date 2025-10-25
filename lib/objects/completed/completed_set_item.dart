import 'package:flutter/foundation.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/equipment.dart';
import '../intensity_zones.dart';
import '../planned/set_item.dart';
import '../stroke.dart';

@immutable
class CompletedSetItem {
  final String? id;
  final int? itemOrder;
  final int? actualDistance;
  final DistanceUnit? actualDistanceUnit;
  final Duration? actualInterval;
  final int? actualRepetitionInSetItem;
  final Stroke? actualStroke;
  final IntensityZone? actualIntensityZone;
  final List<EquipmentType>? actualEquipmentUsed;
  final String? swimmerNotesForItem;
  final String? plannedSetItemIdRef;

  const CompletedSetItem({
    this.id,
    this.itemOrder,
    this.actualDistance,
    this.actualDistanceUnit,
    this.actualInterval,
    this.actualRepetitionInSetItem = 1,
    this.actualStroke,
    this.actualIntensityZone,
    this.actualEquipmentUsed,
    this.swimmerNotesForItem,
    this.plannedSetItemIdRef,
  });

  /// Create from planned SetItem
  factory CompletedSetItem.fromSetItem(SetItem plannedItem, {int? order}) {
    return CompletedSetItem(
      itemOrder: order,
      actualDistance: plannedItem.itemDistance,
      actualDistanceUnit: plannedItem.distanceUnit,
      actualInterval: plannedItem.interval,
      actualRepetitionInSetItem: plannedItem.itemRepetition ?? 1,
      actualStroke: plannedItem.stroke,
      actualIntensityZone: plannedItem.intensityZone,
      actualEquipmentUsed: plannedItem.equipment,
    );
  }

  CompletedSetItem copyWith({
    String? id,
    int? itemOrder,
    int? actualDistance,
    DistanceUnit? actualDistanceUnit,
    Duration? actualInterval,
    int? actualRepetitionInSetItem,
    Stroke? actualStroke,
    IntensityZone? actualIntensityZone,
    List<EquipmentType>? actualEquipmentUsed,
    String? swimmerNotesForItem,
    String? plannedSetItemIdRef,
  }) {
    return CompletedSetItem(
      id: id ?? this.id,
      itemOrder: itemOrder ?? this.itemOrder,
      actualDistance: actualDistance ?? this.actualDistance,
      actualDistanceUnit: actualDistanceUnit ?? this.actualDistanceUnit,
      actualInterval: actualInterval ?? this.actualInterval,
      actualRepetitionInSetItem:
          actualRepetitionInSetItem ?? this.actualRepetitionInSetItem,
      actualStroke: actualStroke ?? this.actualStroke,
      actualIntensityZone: actualIntensityZone ?? this.actualIntensityZone,
      actualEquipmentUsed: actualEquipmentUsed ?? this.actualEquipmentUsed,
      swimmerNotesForItem: swimmerNotesForItem ?? this.swimmerNotesForItem,
      plannedSetItemIdRef: plannedSetItemIdRef ?? this.plannedSetItemIdRef,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (itemOrder != null) 'itemOrder': itemOrder,
      if (actualDistance != null) 'actualDistance': actualDistance,
      if (actualDistanceUnit != null)
        'actualDistanceUnit': actualDistanceUnit!.name,
      if (actualInterval != null)
        'actualIntervalSeconds': actualInterval!.inSeconds,
      'actualRepetitionInSetItem': actualRepetitionInSetItem,
      if (actualStroke != null) 'actualStroke': actualStroke!.name,
      if (actualIntensityZone != null)
        'actualIntensityZone': actualIntensityZone!.name,
      if (actualEquipmentUsed != null && actualEquipmentUsed!.isNotEmpty)
        'actualEquipmentUsed': actualEquipmentUsed!.map((e) => e.name).toList(),
      if (swimmerNotesForItem != null)
        'swimmerNotesForItem': swimmerNotesForItem,
      if (plannedSetItemIdRef != null)
        'plannedSetItemIdRef': plannedSetItemIdRef,
    };
  }

  factory CompletedSetItem.fromMap(Map<String, dynamic> map) {
    final rawEquipment = map['actualEquipmentUsed'];
    final safeEquipment = (rawEquipment is List)
        ? rawEquipment
              .whereType<String>()
              .map(
                (e) => EquipmentType.values.firstWhere(
                  (eq) => eq.name == e,
                  orElse: () =>
                      EquipmentType.none, // Add your default if needed
                ),
              )
              .toList()
        : <EquipmentType>[];

    return CompletedSetItem(
      id: map['id'] as String?,
      itemOrder: map['itemOrder'] as int?,
      actualDistance: map['actualDistance'] as int?,
      actualDistanceUnit: map['actualDistanceUnit'] != null
          ? DistanceUnit.values.byName(map['actualDistanceUnit'] as String)
          : null,
      actualInterval: map['actualIntervalSeconds'] != null
          ? Duration(seconds: map['actualIntervalSeconds'] as int)
          : null,
      actualRepetitionInSetItem: map['actualRepetitionInSetItem'] as int? ?? 1,
      actualStroke: map['actualStroke'] != null
          ? Stroke.values.byName(map['actualStroke'] as String)
          : null,
      actualIntensityZone: map['actualIntensityZone'] != null
          ? IntensityZone.values.byName(map['actualIntensityZone'] as String)
          : null,
      actualEquipmentUsed: safeEquipment,
      swimmerNotesForItem: map['swimmerNotesForItem'] as String?,
      plannedSetItemIdRef: map['plannedSetItemIdRef'] as String?,
    );
  }
}
