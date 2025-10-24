// lib/swim/generator/focus/technique_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class TechniqueFocus extends TrainingFocus {
  @override
  String get name => 'Technique';

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.drill, // Primary for skill work
    IntensityZone.i1, // Low aerobic for control
  ];

  @override
  String generatePrompt() => """
You are designing a **Technique-focused swim session**.

Key principles:
- Emphasize skill development, efficiency, and body position.
- Use drills, slow controlled swimming, and equipment like fins, snorkels, and paddles.
- Keep intensity low (zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}).
- Main set may include progression drills or technique combinations.
- Include frequent rest or easy swimming to maintain precision.
- Warm-up prepares body control and feel for the water.
- Cool-down focuses on relaxed form and stretching strokes.

Target total distance: 2000–4000m.
Focus on movement quality over pace.
""";
}
