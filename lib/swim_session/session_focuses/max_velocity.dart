// lib/swim/generator/focus/max_velocity_sprint_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';


class MaxVelocitySprintFocus extends TrainingFocus {
  static const int maxSprintSessionVolume = 400;

  @override
  String get name => 'Max Velocity Sprint';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.max,
    IntensityZone.sp3,
  ];
}
