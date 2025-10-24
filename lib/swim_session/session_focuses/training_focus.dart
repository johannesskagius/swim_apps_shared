import 'dart:math';

import 'package:swim_apps_shared/swim_apps_shared.dart';

abstract class TrainingFocus {
  abstract final String name;
  final Random random =
      Random(); // Each focus might need its own random decisions

  double get mainSetFocusPercentageMin =>
      0.6; // Default: at least 60% of main set
  double get mainSetFocusPercentageMax => 0.9;

  double get warmUpPercentageMin => 0.2;

  /// Preferred intensity zones for this focus.
  List<IntensityZone> get preferredIntensityZones;
}
