import 'package:swim_apps_shared/swim_apps_shared.dart';

class RacePaceSpeedFocus extends TrainingFocus {
  @override
  String get name => 'Race Pace Speed';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.racePace,
    IntensityZone.sp1,
    IntensityZone.sp2,
  ];
}
