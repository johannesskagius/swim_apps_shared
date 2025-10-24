import 'package:swim_apps_shared/swim_apps_shared.dart';
import 'training_focus.dart';

class MixedFocus extends TrainingFocus {
  @override
  String get name => 'Mixed';

  @override
  int get warmUpRatio => 20;
  @override
  int get preSetRatio => 20;
  @override
  int get mainSetRatio => 50;
  @override
  int get coolDownRatio => 10;

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.pullBuoy,
  ];

  @override
  List<String> get aiPromptTags => ['mixed', 'varied', 'general', 'balance'];

  @override
  String generatePrompt() => """
### Training Focus: Mixed
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **Mixed / General-purpose swim session**.

Key principles:
- Blend aerobic, technique, and controlled speed work.
- Alternate between intensity levels and stroke focuses.
- Include one or more drill components.
- End with relaxed recovery swimming.

Session requirements:
- Focus on variety and balance.
- Keep total distance 3000–5000m.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
