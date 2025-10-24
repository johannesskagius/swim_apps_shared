// lib/swim/generator/focus/im_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class IMFocus extends TrainingFocus {
  @override
  String get name => 'Medley';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i3,
    IntensityZone.sp1,
  ];

  @override
  String generatePrompt() => """
You are designing an **Individual Medley (IM)-focused swim session**.

Key principles:
- Integrate all four strokes (Fly, Back, Breast, Free) in balanced sets.
- Include stroke transitions and stroke-specific drills.
- Emphasize technique and pacing consistency across strokes.
- Use mixed IM order (IM or Reverse IM) for variety.
- Incorporate kick and drill sets targeting stroke balance and rhythm.
- Intensity: moderate to high aerobic (zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}).
- Include short sprint work for transitions and turns.
- Typical total volume: 3000–5000m.
- Warm-up should include all strokes; main set combines IM sequences.

Goal: Develop complete medley performance with balanced endurance and efficiency.
Return only plain-text workout in textToSessionParser format.
""";
}
