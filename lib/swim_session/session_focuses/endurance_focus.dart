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

  @override
  String generatePrompt() => """
You are designing an **Endurance-focused swim session**.

Key principles:
- Prioritize aerobic capacity and sustainable pace swimming.
- Main sets use moderate-to-long intervals (100–800m repeats).
- Maintain steady technique and rhythm across the entire set.
- Rest intervals are short (10–30 seconds) to keep heart rate elevated.
- Intensity should stay mostly within zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}.
- Include pacing or descending efforts to teach consistency.
- Warm-up prepares for sustained aerobic work with progressive builds.
- Optional pre-main set: short aerobic pull or kick.
- Cool-down is easy, emphasizing relaxed technique.
- Typical total distance: 4000–6000m depending on level.

Goal: Build aerobic endurance and pacing control without excessive fatigue.
Return a plain-text swim workout formatted for textToSessionParser.
""";
}
