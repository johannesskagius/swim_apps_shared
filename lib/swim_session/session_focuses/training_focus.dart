import 'dart:math';
import 'package:swim_apps_shared/swim_apps_shared.dart';

abstract class TrainingFocus {
  abstract final String name;
  final Random random = Random();

  double get mainSetFocusPercentageMin => 0.6;
  double get mainSetFocusPercentageMax => 0.9;
  double get warmUpPercentageMin => 0.2;

  /// Preferred intensity zones for this focus.
  List<IntensityZone> get preferredIntensityZones;

  /// ✅ Generates the AI prompt segment for this focus
  String generatePrompt();

  // Equality and hashing
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TrainingFocus &&
              runtimeType == other.runtimeType &&
              name == other.name;

  @override
  int get hashCode => name.hashCode;
}
