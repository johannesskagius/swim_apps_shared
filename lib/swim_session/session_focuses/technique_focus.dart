// lib/swim/generator/focus/technique_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';


class TechniqueFocus extends TrainingFocus {
  // TechniqueFocus() : super(); // Keep if base class has parameterless constructor

  @override
  String get name => 'Technique Focus';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.drill, // Primary for technique
    IntensityZone.i1, // Low aerobic for focus
  ];
}
