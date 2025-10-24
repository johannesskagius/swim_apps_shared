import 'package:swim_apps_shared/swim_apps_shared.dart';
import 'training_focus.dart';

class MaxVelocitySprintFocus extends TrainingFocus {
  @override
  String get name => 'Max Velocity Sprint';

  @override
  int get warmUpRatio => 30;
  @override
  int get preSetRatio => 10;
  @override
  int get mainSetRatio => 50;
  @override
  int get coolDownRatio => 10;

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.resistanceBand,
    EquipmentType.parachute,
  ];

  @override
  List<String> get aiPromptTags => ['max velocity', 'sprint', 'power', 'explosive'];

  @override
  String generatePrompt() => """
### Training Focus: Max Velocity Sprint
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **Max Velocity Sprint-focused swim session**.

Key principles:
- Prioritize short (10–25m) all-out efforts.
- Use full recovery (1:5–1:10 work:rest).
- Combine resisted and assisted sprints.
- Stop before fatigue reduces quality.

Session requirements:
- Match ${aiPromptTags.join(", ")} intent.
- Keep total sprint volume ≤400m.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
