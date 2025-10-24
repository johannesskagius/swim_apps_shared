// lib/swim/generator/focus/speed_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class SpeedFocus extends TrainingFocus {
  static const int maxPureSpeedVolumeSP1 = 400;
  static const int maxPureSpeedVolumeSP2 = 600;
  static const int maxPureSpeedVolumeSP3 = 800;

  @override
  String get name => 'Speed Focus';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.sp1,
    IntensityZone.sp2,
    IntensityZone.sp3,
    IntensityZone.max,
    IntensityZone.racePace,
  ];
}
