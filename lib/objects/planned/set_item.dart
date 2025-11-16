
import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/objects/planned/sub_item.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/equipment.dart';
import '../../swim_session/generator/enums/swim_way.dart';
import '../intensity_zones.dart';
import '../stroke.dart';

@immutable
class SetItem {
  final String id;
  final int order;
  final int? itemRepetition;
  final int? itemDistance;
  final Stroke? stroke;
  final String? drillName;
  final Duration? interval;
  final String? targetPaceOrTime;
  final List<EquipmentType>? equipment;


  final String? itemNotes;
  final String? rawTextLine;
  final IntensityZone? intensityZone;
  final DistanceUnit? distanceUnit;
  final SwimWay swimWay;
  final List<SubItem>? subItems;

  final bool requiresResult;
  final List<String>? resultTags;
  final Map<String, dynamic>? resultSchema;

  const SetItem({
    required this.id,
    required this.order,
    this.swimWay = SwimWay.swim,
    this.itemRepetition,
    this.itemDistance,
    this.stroke,
    this.drillName,
    this.interval,
    this.targetPaceOrTime,
    this.equipment,
    this.itemNotes,
    this.intensityZone,
    this.distanceUnit,
    this.subItems,
    this.rawTextLine,
    this.requiresResult = false,
    this.resultTags,
    this.resultSchema,
  });

  const SetItem.custom({
    required this.id,
    required this.order,
    this.swimWay = SwimWay.swim,
    this.itemRepetition,
    this.itemDistance,
    this.stroke,
    this.drillName,
    this.interval,
    this.targetPaceOrTime,
    this.equipment,
    this.itemNotes,
    this.intensityZone,
    this.distanceUnit,
    this.subItems,
    this.rawTextLine,
    this.requiresResult = false,
    this.resultTags,
    this.resultSchema,
  });

  List<Map<String, dynamic>> _convertSubItemsToJson() =>
      (subItems ?? []).map((s) => s.toJson()).toList();

  SetItem copyWith({
    String? id,
    int? order,
    SwimWay? swimWay,
    int? itemRepetition,
    int? itemDistance,
    Stroke? stroke,
    String? drillName,
    Duration? interval,
    String? targetPaceOrTime,
    List<EquipmentType>? equipment,
    String? itemNotes,
    IntensityZone? intensityZone,
    DistanceUnit? distanceUnit,
    List<SubItem>? subItems,
    String? rawTextLine,
    bool? requiresResult,
    List<String>? resultTags,
    Map<String, dynamic>? resultSchema,
  }) {
    return SetItem(
      id: id ?? this.id,
      order: order ?? this.order,
      swimWay: swimWay ?? this.swimWay,
      itemRepetition: itemRepetition ?? this.itemRepetition,
      itemDistance: itemDistance ?? this.itemDistance,
      stroke: stroke ?? this.stroke,
      drillName: drillName ?? this.drillName,
      interval: interval ?? this.interval,
      targetPaceOrTime: targetPaceOrTime ?? this.targetPaceOrTime,
      equipment: equipment ?? this.equipment,
      itemNotes: itemNotes ?? this.itemNotes,
      intensityZone: intensityZone ?? this.intensityZone,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      subItems: subItems ?? this.subItems,
      rawTextLine: rawTextLine ?? this.rawTextLine,
      requiresResult: requiresResult ?? this.requiresResult,    // NEW
      resultTags: resultTags ?? this.resultTags,                // NEW
      resultSchema: resultSchema ?? this.resultSchema,          // NEW
    );
  }

  SetItem deepCopy() {
    return SetItem(
      id: id,
      order: order,
      swimWay: swimWay,
      itemRepetition: itemRepetition,
      itemDistance: itemDistance,
      stroke: stroke,
      drillName: drillName,
      interval: interval,
      targetPaceOrTime: targetPaceOrTime,
      equipment: equipment != null ? List.from(equipment!) : null,
      itemNotes: itemNotes,
      intensityZone: intensityZone,
      distanceUnit: distanceUnit,
      subItems: subItems?.map((s) => s.copyWith()).toList(),
      rawTextLine: rawTextLine,
      requiresResult: requiresResult,                                  // NEW
      resultTags: resultTags != null ? List.of(resultTags!) : null,    // NEW
      resultSchema: resultSchema != null ? Map.of(resultSchema!) : null, // NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      if (itemRepetition != null) 'repetitions': itemRepetition,
      if (itemDistance != null) 'quantity': itemDistance,
      if (stroke != null) 'stroke': stroke!.name,
      if (drillName != null) 'drillName': drillName,
      if (interval != null) 'interval': interval!.inSeconds,
      if (targetPaceOrTime != null) 'targetPaceOrTime': targetPaceOrTime,
      if (equipment != null && equipment!.isNotEmpty)
        'equipment': equipment!.map((e) => e.name).toList(),
      if (itemNotes != null) 'itemNotes': itemNotes,
      if (intensityZone != null) 'intensityZone': intensityZone!.name,
      if (distanceUnit != null) 'distanceUnit': distanceUnit!.name,
      if (subItems != null && subItems!.isNotEmpty)
        'subItems': _convertSubItemsToJson(),
      if (rawTextLine != null) 'rawTextLine': rawTextLine,
      'swimWay': swimWay.name,
      'requiresResult': requiresResult,
      if (resultTags != null && resultTags!.isNotEmpty) 'resultTags': resultTags,
      if (resultSchema != null && resultSchema!.isNotEmpty) 'resultSchema': resultSchema,
    };
  }

  factory SetItem.fromJson(Map<String, dynamic> json) {
    final rawEquipment = json['equipment'];
    final safeEquipment = (rawEquipment is List)
        ? rawEquipment
              .whereType<String>()
              .map(
                (name) => EquipmentType.values.firstWhere(
                  (e) => e.name == name,
                  orElse: () => EquipmentType.none,
                ),
              )
              .toList()
        : <EquipmentType>[];

    final rawSubItems = json['subItems'];
    final safeSubItems = (rawSubItems is List)
        ? rawSubItems
              .whereType<Map<String, dynamic>>()
              .map(SubItem.fromJson)
              .toList()
        : <SubItem>[];

    final intervalValue = json['interval'];
    final safeIntervalSeconds = intervalValue is int
        ? intervalValue
        : (intervalValue is double
              ? intervalValue.toInt()
              : int.tryParse('$intervalValue') ?? 0);

    Stroke? safeStroke;
    if (json['stroke'] != null) {
      try {
        safeStroke = Stroke.values.byName(json['stroke']);
      } catch (_) {
        debugPrint('Unknown stroke: ${json['stroke']}');
      }
    }

    IntensityZone? safeIntensityZone;
    if (json['intensityZone'] != null) {
      try {
        safeIntensityZone = IntensityZone.values.byName(json['intensityZone']);
      } catch (_) {
        debugPrint('Unknown intensity zone: ${json['intensityZone']}');
      }
    }

    DistanceUnit? safeDistanceUnit;
    if (json['distanceUnit'] != null) {
      try {
        safeDistanceUnit = DistanceUnit.values.byName(json['distanceUnit']);
      } catch (_) {
        debugPrint('Unknown distance unit: ${json['distanceUnit']}');
      }
    }

    SwimWay safeSwimWay = SwimWay.swim;
    if (json['swimWay'] != null) {
      try {
        safeSwimWay = SwimWay.values.byName(json['swimWay']);
      } catch (_) {
        debugPrint('Unknown swim way: ${json['swimWay']}');
      }
    }

    return SetItem(
      id: json['id'] ?? '',
      order: json['order'] ?? 0,
      swimWay: safeSwimWay,
      itemRepetition: json['repetitions'] as int?,
      itemDistance: json['quantity'] as int?,
      stroke: safeStroke,
      drillName: json['drillName'] as String?,
      interval: Duration(seconds: safeIntervalSeconds),
      targetPaceOrTime: json['targetPaceOrTime'] as String?,
      equipment: safeEquipment,
      itemNotes: json['itemNotes'] as String?,
      intensityZone: safeIntensityZone,
      distanceUnit: safeDistanceUnit,
      subItems: safeSubItems,
      rawTextLine: json['rawTextLine'] as String?,
      requiresResult: json['requiresResult'] == true,
      resultTags: (json['resultTags'] as List?)
          ?.whereType<String>()
          .toList(),
      resultSchema: json['resultSchema'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['resultSchema'])
          : null,
    );
  }
}
