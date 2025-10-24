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

  @override
  String generatePrompt() => """
You are designing a **Max Velocity Sprint-focused swim session**.

Key principles:
- Focus on maximum power and pure speed over very short distances (10–25m).
- Total high-quality sprint volume should not exceed $maxSprintSessionVolume meters.
- Work-to-rest ratio: 1:5 to 1:10 — full recovery between efforts.
- Include resisted (tubing, parachute) and assisted (fins, cords) sprint variations.
- Keep technique pristine; stop the set if speed drops.
- Avoid aerobic fatigue; this is neural, not endurance work.
- Include long warm-up with speed-activation drills.
- Use cooldown to reset the nervous system and stretch out.

Preferred intensity zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}.
Goal: Achieve maximum velocity, not conditioning.
Return a plain-text swim session matching these rules.
""";
}
