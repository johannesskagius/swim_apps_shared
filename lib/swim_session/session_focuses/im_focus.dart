// lib/swim/generator/focus/im_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class IMFocus extends TrainingFocus {
  // IMFocus() : super(); // Base constructor is parameterless

  @override
  String get name => 'Medley focus';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i3,
    IntensityZone.sp1,
  ];
}
