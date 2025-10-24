// lib/swim/generator/focus/race_pace_speed_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class RacePaceSpeedFocus extends TrainingFocus {
  @override
  String get name => 'Race Pace';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.racePace,
    IntensityZone.sp1,
    IntensityZone.sp2,
  ];

  @override
  String generatePrompt() => """
You are designing a **Race-Pace swim session**.

Key principles:
- Focus on replicating competition speed and efficiency.
- Use short-to-medium intervals (25–100m) at race pace with structured rest.
- Maintain form and precision at speed (zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}).
- Include broken swims, descending efforts, or negative splits.
- Emphasize pacing consistency and stroke rhythm under fatigue.
- Warm-up should include build and pace-target sets.
- Total session range: 2500–4000m.

Goal: Develop the ability to sustain target race speed efficiently.
""";
}
