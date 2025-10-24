import 'package:swim_apps_shared/swim_apps_shared.dart';

class EnduranceFocus extends TrainingFocus {
  @override
  String get name => 'Endurance';

  @override
  int get warmUpRatio => 20;

  @override
  int get preSetRatio => 10;

  @override
  int get mainSetRatio => 60;

  @override
  int get coolDownRatio => 10;

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.pullBuoy,
    EquipmentType.paddles,
    EquipmentType.snorkel,
  ];

  @override
  List<String> get aiPromptTags => [
    'endurance',
    'aerobic',
    'capacity',
    'steady',
  ];

  @override
  String generatePrompt() =>
      """
### Training Focus: Endurance
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating an **Endurance-focused swim session**.

Key principles:
- Prioritize aerobic capacity and sustainable pace.
- Use long intervals (100–800m) with short rest (10–30s).
- Maintain consistent pace and technique across sets.
- Integrate optional equipment for variety and control.

Session requirements:
- Focus on ${aiPromptTags.join(", ")}.
- Use aerobic zones with progressive builds.
- Return only plain-text workout formatted for textToSessionParser.
""";
}
