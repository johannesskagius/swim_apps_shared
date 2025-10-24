import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_session/objects/planned/set_item.dart';

import '../../generator/enums/set_types.dart';

class SwimSet {
  String setId; // Firestore document ID or UUID
  SetType? type;
  String? customTypeName;
  List<SetItem> items;
  String? setNotes;
  int? totalSetDistance;
  Duration? totalSetDurationEstimated;
  String? rawTextLine;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? coachId;

  // --------------------------------------------------------------------------
  // ✅ Default constructor
  // --------------------------------------------------------------------------
  SwimSet({
    required this.setId,
    this.type,
    this.customTypeName,
    required this.items,
    this.setNotes,
    this.totalSetDistance,
    this.totalSetDurationEstimated,
    this.rawTextLine,
    this.createdAt,
    this.updatedAt,
    this.coachId,
  });

  // --------------------------------------------------------------------------
  // ✅ Named constructor for quick custom creation
  // --------------------------------------------------------------------------
  SwimSet.custom({
    required this.setId,
    required this.type,
    required this.items,
    this.customTypeName,
    this.setNotes,
    this.totalSetDistance,
    this.totalSetDurationEstimated,
    this.rawTextLine,
    this.createdAt,
    this.updatedAt,
    this.coachId,
  });

  // --------------------------------------------------------------------------
  // ✅ Deep copy (for planned → actual conversion)
  // --------------------------------------------------------------------------
  SwimSet deepCopy() {
    return SwimSet(
      setId: setId,
      type: type,
      customTypeName: customTypeName,
      items: items.map((item) => item.deepCopy()).toList(),
      setNotes: setNotes,
      totalSetDistance: totalSetDistance,
      totalSetDurationEstimated: totalSetDurationEstimated,
      rawTextLine: rawTextLine,
      createdAt: createdAt,
      updatedAt: updatedAt,
      coachId: coachId,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Serialization for Firestore
  // --------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'swimSetId': setId,
      if (type != null) 'type': type!.name,
      if (customTypeName != null) 'customTypeName': customTypeName,
      'items': items.map((i) => i.toJson()).toList(),
      if (setNotes != null) 'setNotes': setNotes,
      if (totalSetDistance != null)
        'totalSetDistanceEstimated': totalSetDistance,
      if (totalSetDurationEstimated != null)
        'totalSetDurationEstimated': totalSetDurationEstimated!.inSeconds,
      if (rawTextLine != null) 'rawTextLine': rawTextLine,
      if (coachId != null) 'coachId': coachId,
    };
  }

  // --------------------------------------------------------------------------
  // ✅ Firestore deserialization (with ID)
  // --------------------------------------------------------------------------
  factory SwimSet.fromJsonWithId(String id, Map<String, dynamic> json) {
    final rawItems = json['items'];
    final safeItems = (rawItems is List)
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SetItem.fromJson)
              .toList()
        : <SetItem>[];

    SetType? safeType;
    if (json['type'] != null) {
      try {
        safeType = SetType.values.byName(json['type']);
      } catch (_) {
        debugPrint('Warning: Unknown SetType "${json['type']}"');
      }
    }

    return SwimSet(
      setId: id,
      type: safeType,
      customTypeName: json['customTypeName'] as String?,
      items: safeItems,
      setNotes: json['setNotes'] as String?,
      totalSetDistance: json['totalSetDistanceEstimated'] as int?,
      totalSetDurationEstimated: Duration(
        seconds: json['totalSetDurationEstimated'] as int? ?? 0,
      ),
      rawTextLine: json['rawTextLine'] as String?,
      coachId: json['coachId'] as String?,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Firestore deserialization (without explicit ID)
  // --------------------------------------------------------------------------
  factory SwimSet.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final safeItems = (rawItems is List)
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SetItem.fromJson)
              .toList()
        : <SetItem>[];

    SetType? safeType;
    if (json['type'] != null) {
      try {
        safeType = SetType.values.byName(json['type']);
      } catch (_) {
        debugPrint('Warning: Unknown SetType "${json['type']}"');
      }
    }

    return SwimSet(
      setId: json['swimSetId'] ?? '',
      type: safeType,
      customTypeName: json['customTypeName'] as String?,
      items: safeItems,
      setNotes: json['setNotes'] as String?,
      totalSetDistance: json['totalSetDistanceEstimated'] as int?,
      totalSetDurationEstimated: Duration(
        seconds: json['totalSetDurationEstimated'] as int? ?? 0,
      ),
      rawTextLine: json['rawTextLine'] as String?,
      coachId: json['coachId'] as String?,
    );
  }
}
