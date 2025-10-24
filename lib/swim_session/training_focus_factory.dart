import 'package:swim_apps_shared/swim_apps_shared.dart';

/// Enum representing all known training focus types.
enum TrainingFocusType {
  endurance,
  technique,
  speed,
  racePace,
  mixed,
  recovery,
  medley,
  sprint,
}

/// Helper to map enum <-> display name (used in UI or JSON)
extension TrainingFocusTypeX on TrainingFocusType {
  String get displayName {
    switch (this) {
      case TrainingFocusType.endurance:
        return 'Endurance';
      case TrainingFocusType.technique:
        return 'Technique';
      case TrainingFocusType.speed:
        return 'Speed';
      case TrainingFocusType.racePace:
        return 'Race Pace';
      case TrainingFocusType.mixed:
        return 'Mixed';
      case TrainingFocusType.recovery:
        return 'Recovery';
      case TrainingFocusType.medley:
        return 'Medley';
      case TrainingFocusType.sprint:
        return 'Max Velocity Sprint';
    }
  }

  /// Short lowercase name for Firebase keys, analytics, etc.
  String get id => displayName.toLowerCase().replaceAll(' ', '_');
}

/// Factory & registry for all focus types.
class TrainingFocusFactory {
  /// Create a TrainingFocus instance by enum.
  static TrainingFocus fromType(TrainingFocusType type) {
    switch (type) {
      case TrainingFocusType.endurance:
        return EnduranceFocus();
      case TrainingFocusType.technique:
        return TechniqueFocus();
      case TrainingFocusType.speed:
        return SpeedFocus();
      case TrainingFocusType.racePace:
        return RacePaceSpeedFocus();
      case TrainingFocusType.mixed:
        return MixedFocus();
      case TrainingFocusType.recovery:
        return RecoveryFocus();
      case TrainingFocusType.medley:
        return IMFocus();
      case TrainingFocusType.sprint:
        return MaxVelocitySprintFocus();
    }
  }

  /// Create a TrainingFocus instance by name (case-insensitive).
  static TrainingFocus fromName(String name) {
    final normalized = name.trim().toLowerCase();
    switch (normalized) {
      case 'endurance':
        return EnduranceFocus();
      case 'technique':
      case 'technique focus':
        return TechniqueFocus();
      case 'speed':
      case 'speed focus':
        return SpeedFocus();
      case 'race pace':
      case 'race pace speed':
        return RacePaceSpeedFocus();
      case 'mixed':
      case 'mixed / general purpose':
        return MixedFocus();
      case 'recovery':
      case 'recovery focus':
        return RecoveryFocus();
      case 'medley':
      case 'im':
      case 'individual medley':
        return IMFocus();
      case 'sprint':
      case 'max sprint':
      case 'max velocity sprint':
        return MaxVelocitySprintFocus();
      default:
        return MixedFocus();
    }
  }

  /// List all available TrainingFocus types (for dropdowns, menus, etc.)
  static List<TrainingFocusType> get allTypes => TrainingFocusType.values;

  /// List all instantiated focuses (ready for iteration / preview cards).
  static List<TrainingFocus> get allFocuses => [
    EnduranceFocus(),
    TechniqueFocus(),
    SpeedFocus(),
    RacePaceSpeedFocus(),
    MixedFocus(),
    RecoveryFocus(),
    IMFocus(),
    MaxVelocitySprintFocus(),
  ];

  /// Try to guess focus type from name safely (returns `mixed` as fallback).
  static TrainingFocusType typeFromName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final type in TrainingFocusType.values) {
      if (type.displayName.toLowerCase() == normalized) return type;
    }
    return TrainingFocusType.mixed;
  }
}
