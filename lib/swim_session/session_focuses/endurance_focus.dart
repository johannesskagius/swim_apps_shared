// lib/swim/generator/focus/endurance_focus.dart

import 'package:swim_apps_shared/swim_apps_shared.dart';

class EnduranceFocus extends TrainingFocus {
  @override
  String get name => 'Endurance';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i3,
  ];
}
