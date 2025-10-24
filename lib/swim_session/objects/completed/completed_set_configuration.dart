import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_session/objects/planned/swim_set_config.dart';

import 'completed_swim_set.dart';

@immutable
class CompletedSetConfiguration {
  final String? id; // Optional
  final int actualRepetitions; // Actual performed repetitions
  final ActualSwimSet actualSwimSet; // The actual performed set
  final String? swimmerNotesForConfiguration;
  final String? plannedSetConfigurationIdRef; // Link to planned config
  final int? setConfigOrder; // To keep the correct order in the swim_session

  const CompletedSetConfiguration({
    this.id,
    required this.actualRepetitions,
    required this.actualSwimSet,
    this.swimmerNotesForConfiguration,
    this.plannedSetConfigurationIdRef,
    this.setConfigOrder,
  });

  // --------------------------------------------------------------------------
  // ✅ Factory: build from planned configuration
  // --------------------------------------------------------------------------
  factory CompletedSetConfiguration.fromSessionSetConfiguration(
    SessionSetConfiguration plannedConfig, {
    int? order,
  }) {
    final swimSet = plannedConfig.swimSet;

    final actualSwimSet = (swimSet != null)
        ? ActualSwimSet.fromSwimSet(swimSet)
        : ActualSwimSet(items: []); // fallback to empty if null

    return CompletedSetConfiguration(
      id: null,
      // Firestore can assign its own ID
      plannedSetConfigurationIdRef: plannedConfig.sessionSetConfigId,
      actualRepetitions: plannedConfig.repetitions,
      actualSwimSet: actualSwimSet,
      swimmerNotesForConfiguration: null,
      setConfigOrder: order ?? plannedConfig.order,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Copy method
  // --------------------------------------------------------------------------
  CompletedSetConfiguration copyWith({
    String? id,
    int? actualRepetitions,
    ActualSwimSet? actualSwimSet,
    String? swimmerNotesForConfiguration,
    String? plannedSetConfigurationIdRef,
    int? setConfigOrder,
  }) {
    return CompletedSetConfiguration(
      id: id ?? this.id,
      actualRepetitions: actualRepetitions ?? this.actualRepetitions,
      actualSwimSet: actualSwimSet ?? this.actualSwimSet,
      swimmerNotesForConfiguration:
          swimmerNotesForConfiguration ?? this.swimmerNotesForConfiguration,
      plannedSetConfigurationIdRef:
          plannedSetConfigurationIdRef ?? this.plannedSetConfigurationIdRef,
      setConfigOrder: setConfigOrder ?? this.setConfigOrder,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Serialization
  // --------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'actualRepetitions': actualRepetitions,
      'actualSwimSet': actualSwimSet.toMap(),
      if (swimmerNotesForConfiguration != null)
        'swimmerNotesForConfiguration': swimmerNotesForConfiguration,
      if (plannedSetConfigurationIdRef != null)
        'plannedSetConfigurationIdRef': plannedSetConfigurationIdRef,
      if (setConfigOrder != null) 'setConfigOrder': setConfigOrder,
    };
  }

  factory CompletedSetConfiguration.fromMap(Map<String, dynamic> map) {
    final actualSetData = map['actualSwimSet'];
    final safeActualSwimSet = (actualSetData is Map<String, dynamic>)
        ? ActualSwimSet.fromMap(actualSetData)
        : ActualSwimSet(items: []);

    return CompletedSetConfiguration(
      id: map['id'] as String?,
      actualRepetitions: map['actualRepetitions'] as int? ?? 1,
      actualSwimSet: safeActualSwimSet,
      swimmerNotesForConfiguration:
          map['swimmerNotesForConfiguration'] as String?,
      plannedSetConfigurationIdRef:
          map['plannedSetConfigurationIdRef'] as String?,
      setConfigOrder: map['setConfigOrder'] as int?,
    );
  }
}
