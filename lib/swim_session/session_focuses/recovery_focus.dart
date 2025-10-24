// /Users/johannesskagius/Company/projects/swimify/lib/swim/generator/focus/recovery_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';


class RecoveryFocus extends TrainingFocus {
  // RecoveryFocus() : super(); // Keep if base has parameterless constructor

  @override
  String get name => 'Recovery Focus';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i1,
    IntensityZone.drill,
  ];
}
