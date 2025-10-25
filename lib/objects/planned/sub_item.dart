import 'package:flutter/foundation.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/equipment.dart';
import '../../swim_session/generator/enums/swim_way.dart';
import '../intensity_zones.dart';
import '../stroke.dart';

@immutable
class SubItem {
  final int subItemDistance;
  final DistanceUnit distanceUnit;
  final SwimWay swimWay;
  final Stroke? stroke;
  final IntensityZone? intensityZone;
  final List<EquipmentType> equipment;
  final String? itemNotes;

  const SubItem({
    required this.subItemDistance,
    this.distanceUnit = DistanceUnit.meters,
    this.swimWay = SwimWay.swim,
    this.stroke,
    this.intensityZone,
    this.equipment = const [],
    this.itemNotes,
  });

  // 🔹 Clone or copy methods
  SubItem clone() => SubItem(
    subItemDistance: subItemDistance,
    distanceUnit: distanceUnit,
    swimWay: swimWay,
    stroke: stroke,
    intensityZone: intensityZone,
    equipment: List<EquipmentType>.from(equipment),
    itemNotes: itemNotes,
  );

  SubItem copyWith({
    int? subItemDistance,
    DistanceUnit? distanceUnit,
    SwimWay? swimWay,
    ValueGetter<Stroke?>? stroke,
    ValueGetter<IntensityZone?>? intensityZone,
    List<EquipmentType>? equipment,
    ValueGetter<String?>? itemNotes,
  }) {
    return SubItem(
      subItemDistance: subItemDistance ?? this.subItemDistance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      swimWay: swimWay ?? this.swimWay,
      stroke: stroke != null ? stroke() : this.stroke,
      intensityZone: intensityZone != null
          ? intensityZone()
          : this.intensityZone,
      equipment: equipment ?? List<EquipmentType>.from(this.equipment),
      itemNotes: itemNotes != null ? itemNotes() : this.itemNotes,
    );
  }

  // 🔹 Serialization
  Map<String, dynamic> toJson() {
    return {
      'subItemDistance': subItemDistance,
      'distanceUnit': distanceUnit.name,
      'swimWay': swimWay.name,
      if (stroke != null) 'stroke': stroke!.name,
      if (intensityZone != null) 'intensityZone': intensityZone!.name,
      if (equipment.isNotEmpty)
        'equipment': equipment.map((e) => e.name).toList(),
      if (itemNotes != null) 'itemNotes': itemNotes,
    };
  }

  // 🔹 Safe Firestore deserialization
  factory SubItem.fromJson(Map<String, dynamic> json) {
    // Handle numeric values safely
    final rawDistance = json['subItemDistance'];
    final safeDistance = rawDistance is int
        ? rawDistance
        : (rawDistance is num
              ? rawDistance.toInt()
              : int.tryParse(rawDistance.toString()) ?? 0);

    DistanceUnit safeDistanceUnit = DistanceUnit.meters;
    if (json['distanceUnit'] is String) {
      try {
        safeDistanceUnit = DistanceUnit.values.byName(json['distanceUnit']);
      } catch (_) {
        debugPrint('⚠️ Unknown DistanceUnit: ${json['distanceUnit']}');
      }
    }

    SwimWay safeSwimWay = SwimWay.swim;
    if (json['swimWay'] is String) {
      try {
        safeSwimWay = SwimWay.values.byName(json['swimWay']);
      } catch (_) {
        debugPrint('⚠️ Unknown SwimWay: ${json['swimWay']}');
      }
    }

    Stroke? safeStroke;
    if (json['stroke'] is String) {
      try {
        safeStroke = Stroke.values.byName(json['stroke']);
      } catch (_) {
        debugPrint('⚠️ Unknown Stroke: ${json['stroke']}');
      }
    }

    IntensityZone? safeIntensityZone;
    if (json['intensityZone'] is String) {
      try {
        safeIntensityZone = IntensityZone.values.byName(json['intensityZone']);
      } catch (_) {
        debugPrint('⚠️ Unknown IntensityZone: ${json['intensityZone']}');
      }
    }

    final rawEquipment = json['equipment'];
    final safeEquipment = (rawEquipment is List)
        ? rawEquipment.whereType<String>().map((name) {
            try {
              return EquipmentType.values.byName(name);
            } catch (_) {
              debugPrint('⚠️ Unknown EquipmentType: $name');
              return EquipmentType.none;
            }
          }).toList()
        : <EquipmentType>[];

    return SubItem(
      subItemDistance: safeDistance,
      distanceUnit: safeDistanceUnit,
      swimWay: safeSwimWay,
      stroke: safeStroke,
      intensityZone: safeIntensityZone,
      equipment: safeEquipment,
      itemNotes: json['itemNotes'] as String?,
    );
  }
}
