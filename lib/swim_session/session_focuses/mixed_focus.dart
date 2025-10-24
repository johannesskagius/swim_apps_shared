// lib/swim/generator/focus/mixed_focus.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class MixedFocus extends TrainingFocus {
  @override
  String get name => "Mixed";

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i1,
    IntensityZone.i2,
    IntensityZone.i3,
    IntensityZone.drill,
  ];

  @override
  String generatePrompt() => """
You are designing a **Mixed / General-purpose swim session**.

Key principles:
- Blend aerobic endurance, technique, and controlled speed work.
- Alternate between different intensities (zones: ${preferredIntensityZones.map((z) => z.name).join(", ")}).
- Include at least one skill-oriented part (e.g. drills or stroke variations).
- Structure: moderate warm-up → balanced main set → relaxed cool-down.
- Ideal for maintenance or transition days.
- Keep total distance between 3000–5000m depending on athlete level.

Goal: Provide a complete, balanced workout stimulating multiple systems.
""";
}
