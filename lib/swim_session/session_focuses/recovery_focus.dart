// lib/swim/generator/focus/recovery_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class RecoveryFocus extends TrainingFocus {
  @override
  String get name => 'Recovery';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i1,
    IntensityZone.drill,
  ];

  @override
  String generatePrompt() => """
You are designing a **Recovery-focused swim session**.

Key principles:
- Emphasize relaxation, mobility, and active regeneration.
- Use easy aerobic swimming with drills and long rest intervals.
- Maintain very low intensity (zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}).
- Include mixed strokes and kicking to enhance blood flow.
- Avoid fatigue; keep heart rate low and focus on technique.
- Warm-up and cool-down blend together into continuous easy movement.
- Total distance should stay between 1500–3000m.

The workout should leave swimmers feeling refreshed, not tired.
""";
}
