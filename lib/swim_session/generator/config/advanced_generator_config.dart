import 'package:swim_apps_shared/swim_apps_shared.dart';

// Enums for Generator Configuration
enum SessionDifficulty { easy, medium, hard }

class AdvancedGeneratorConfig {
  final String mode; // 'distance' or 'time'
  final int? totalDistance; // In meters or yards based on targetDistanceUnit
  final int? timeLimitMinutes;
  final Duration averageIntervalPer100m; // User's base pace
  final SessionSlot sessionSlot;
  final DistanceUnit
  targetDistanceUnit; // meters or yards for generated distances

  final SessionDifficulty difficulty;
  final TrainingFocus? selectedTrainingFocus;
  final List<Stroke>? preferredStrokes; // Strokes user wants to focus on
  final Stroke primaryFocusStroke; // Strokes user wants to focus on
  final List<EquipmentType>? availableEquipment;
  final bool includeWarmup;
  final bool includeCooldown;
  final String? coachId; // To assign to SessionSetConfiguration
  final DateTime sessionDate;

  AdvancedGeneratorConfig({
    required this.mode,
    this.totalDistance,
    this.timeLimitMinutes,
    required this.averageIntervalPer100m,
    this.targetDistanceUnit = DistanceUnit.meters,
    this.difficulty = SessionDifficulty.medium,
    this.primaryFocusStroke = Stroke.freestyle,
    this.preferredStrokes,
    this.availableEquipment,
    this.sessionSlot = SessionSlot.afternoon,
    this.includeWarmup = true,
    this.includeCooldown = true,
    this.coachId,
    this.selectedTrainingFocus,
    DateTime? sessionDate,
  }) : sessionDate = sessionDate ?? DateTime.now();
}
