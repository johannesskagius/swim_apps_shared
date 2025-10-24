// lib/swim/generator/focus/mixed_focus.dart


import '../../swim_apps_shared.dart';

class MixedFocus extends TrainingFocus {
  @override
  String get name => "Mixed / General Purpose";

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i1,
    IntensityZone.i2,
    IntensityZone.i3,
    IntensityZone.drill,
  ];
}
