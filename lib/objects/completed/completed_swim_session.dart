import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../swim_session/generator/enums/distance_units.dart';
import '../../swim_session/generator/enums/session_slot.dart';
import '../perceived_exertion_level.dart';
import '../result.dart';
import 'completed_set_configuration.dart';

@immutable
class CompletedSwimSession {
  final String? id;
  final String swimmerId;
  final String? plannedSessionId;
  final String? title;

  /// 🧠 Each completed set can include adjustments (distance, stroke, etc.)
  final List<CompletedSetConfiguration> completedSetConfigurations;

  final DateTime dateCompleted;
  final int actualTotalDistance;
  final Duration actualTotalDuration;
  final String swimSessionId;

  final String? overallSessionGoalAchieved;
  final String? swimmerSessionNotes;
  final PerceivedExertionLevel? perceivedExertion;

  final DistanceUnit distanceUnitUsed;
  final SessionSlot sessionSlotCompleted;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CompletedSwimSession({
    this.id,
    required this.swimmerId,
    this.plannedSessionId,
    this.title,
    required this.completedSetConfigurations,
    required this.swimSessionId,
    required this.dateCompleted,
    required this.actualTotalDistance,
    required this.actualTotalDuration,
    this.overallSessionGoalAchieved,
    this.swimmerSessionNotes,
    this.perceivedExertion,
    required this.distanceUnitUsed,
    required this.sessionSlotCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompletedSwimSession.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Missing data for CompletedSwimSession ${doc.id}");
    }

    final rawConfigs = data['completedSetConfigurations'];
    final safeConfigs = (rawConfigs is List)
        ? rawConfigs
        .whereType<Map<String, dynamic>>()
        .map(CompletedSetConfiguration.fromMap)
        .toList()
        : <CompletedSetConfiguration>[];

    return CompletedSwimSession(
      id: doc.id,
      swimmerId: data['swimmerId'] as String? ?? '',
      plannedSessionId: data['plannedSessionId'] as String?,
      title: data['title'] as String?,
      completedSetConfigurations: safeConfigs,
      dateCompleted: parseDateTimeFromJson(
        data['dateCompleted'],
        'dateCompleted',
        'CompletedSwimSession',
      ),
      actualTotalDistance: (data['actualTotalDistance'] as num?)?.toInt() ?? 0,
      actualTotalDuration:
      Duration(seconds: (data['actualTotalDurationSeconds'] as int?) ?? 0),
      overallSessionGoalAchieved: data['overallSessionGoalAchieved'] as String?,
      swimmerSessionNotes: data['swimmerSessionNotes'] as String?,
      perceivedExertion: (data['perceivedExertion'] is String)
          ? PerceivedExertionLevel.values.firstWhereOrNull(
            (e) => e.name == data['perceivedExertion'],
      )
          : null,
      distanceUnitUsed: (data['distanceUnitUsed'] is String)
          ? DistanceUnit.values.firstWhere(
            (e) => e.name == data['distanceUnitUsed'],
        orElse: () => DistanceUnit.meters,
      )
          : DistanceUnit.meters,
      sessionSlotCompleted: (data['sessionSlotCompleted'] is String)
          ? SessionSlot.values.firstWhere(
            (e) => e.name == data['sessionSlotCompleted'],
        orElse: () => SessionSlot.undefined,
      )
          : SessionSlot.undefined,
      createdAt: parseDateTimeFromJson(
        data['createdAt'],
        'createdAt',
        'CompletedSwimSession',
      ),
      updatedAt: parseDateTimeFromJson(
        data['updatedAt'],
        'updatedAt',
        'CompletedSwimSession',
      ),
      swimSessionId: data['swimSessionId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'swimmerId': swimmerId,
      'plannedSessionId': plannedSessionId,
      'title': title,
      'completedSetConfigurations':
      completedSetConfigurations.map((asc) => asc.toMap()).toList(),
      'dateCompleted': Timestamp.fromDate(dateCompleted),
      'actualTotalDistance': actualTotalDistance,
      'actualTotalDurationSeconds': actualTotalDuration.inSeconds,
      'overallSessionGoalAchieved': overallSessionGoalAchieved,
      'swimmerSessionNotes': swimmerSessionNotes,
      'perceivedExertion': perceivedExertion?.name,
      'distanceUnitUsed': distanceUnitUsed.name,
      'sessionSlotCompleted': sessionSlotCompleted.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'swimSessionId': swimSessionId,
    };
  }

  CompletedSwimSession copyWith({
    String? id,
    String? swimmerId,
    ValueGetter<String?>? plannedSessionId,
    ValueGetter<String?>? title,
    List<CompletedSetConfiguration>? completedSetConfigurations,
    DateTime? dateCompleted,
    int? actualTotalDistance,
    Duration? actualTotalDuration,
    ValueGetter<String?>? overallSessionGoalAchieved,
    ValueGetter<String?>? swimmerSessionNotes,
    ValueGetter<PerceivedExertionLevel>? perceivedExertion,
    DistanceUnit? distanceUnitUsed,
    SessionSlot? sessionSlotCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompletedSwimSession(
      id: id ?? this.id,
      swimmerId: swimmerId ?? this.swimmerId,
      swimSessionId: swimSessionId,
      plannedSessionId:
      plannedSessionId != null ? plannedSessionId() : this.plannedSessionId,
      title: title != null ? title() : this.title,
      completedSetConfigurations:
      completedSetConfigurations ?? this.completedSetConfigurations,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      actualTotalDistance: actualTotalDistance ?? this.actualTotalDistance,
      actualTotalDuration: actualTotalDuration ?? this.actualTotalDuration,
      overallSessionGoalAchieved: overallSessionGoalAchieved != null
          ? overallSessionGoalAchieved()
          : this.overallSessionGoalAchieved,
      swimmerSessionNotes: swimmerSessionNotes != null
          ? swimmerSessionNotes()
          : this.swimmerSessionNotes,
      perceivedExertion: perceivedExertion != null
          ? perceivedExertion()
          : this.perceivedExertion,
      distanceUnitUsed: distanceUnitUsed ?? this.distanceUnitUsed,
      sessionSlotCompleted: sessionSlotCompleted ?? this.sessionSlotCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 🧠 Helper for UI: quickly check if swimmer made any modifications
  bool get hasModifications =>
      completedSetConfigurations.any((c) => c.wasModified == true);
}
