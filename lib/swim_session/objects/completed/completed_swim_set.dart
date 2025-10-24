import 'package:flutter/foundation.dart';

import '../planned/swim_set.dart';
import 'completed_set_item.dart';

@immutable
class ActualSwimSet {
  final String? id;
  final String? actualSetTypeName; // e.g., "Main Set"
  final List<CompletedSetItem> items;
  final String? swimmerNotesForSet;
  final String? plannedSwimSetIdRef;

  const ActualSwimSet({
    this.id,
    this.actualSetTypeName,
    required this.items,
    this.swimmerNotesForSet,
    this.plannedSwimSetIdRef,
  });

  // --------------------------------------------------------------------------
  // ✅ Copy constructor
  // --------------------------------------------------------------------------
  ActualSwimSet copyWith({
    String? id,
    String? actualSetTypeName,
    List<CompletedSetItem>? items,
    String? swimmerNotesForSet,
    String? plannedSwimSetIdRef,
  }) {
    return ActualSwimSet(
      id: id ?? this.id,
      actualSetTypeName: actualSetTypeName ?? this.actualSetTypeName,
      items: items ?? this.items,
      swimmerNotesForSet: swimmerNotesForSet ?? this.swimmerNotesForSet,
      plannedSwimSetIdRef: plannedSwimSetIdRef ?? this.plannedSwimSetIdRef,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Create from planned SwimSet (deep copy of SetItems)
  // --------------------------------------------------------------------------
  factory ActualSwimSet.fromSwimSet(SwimSet plannedSet) {
    final copiedItems = plannedSet.items
        .map((plannedItem) => CompletedSetItem.fromSetItem(plannedItem))
        .toList();

    return ActualSwimSet(
      id: plannedSet.setId,
      actualSetTypeName: plannedSet.type!.name,
      items: copiedItems,
      swimmerNotesForSet: null,
      // Swimmer adds notes later
      plannedSwimSetIdRef: plannedSet.setId,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Firestore serialization
  // --------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      if (actualSetTypeName != null) 'actualSetTypeName': actualSetTypeName,
      'items': items.map((item) => item.toMap()).toList(),
      if (swimmerNotesForSet != null) 'swimmerNotesForSet': swimmerNotesForSet,
      if (plannedSwimSetIdRef != null)
        'plannedSwimSetIdRef': plannedSwimSetIdRef,
    };
  }

  // --------------------------------------------------------------------------
  // ✅ Defensive deserialization
  // --------------------------------------------------------------------------
  factory ActualSwimSet.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final safeItems = (rawItems is List)
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(CompletedSetItem.fromMap)
              .toList()
        : <CompletedSetItem>[];

    return ActualSwimSet(
      id: map['id'] as String?,
      actualSetTypeName: map['actualSetTypeName'] as String?,
      items: safeItems,
      swimmerNotesForSet: map['swimmerNotesForSet'] as String?,
      plannedSwimSetIdRef: map['plannedSwimSetIdRef'] as String?,
    );
  }
}
