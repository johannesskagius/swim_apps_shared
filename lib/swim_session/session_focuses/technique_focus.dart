import '../generator/enums/equipment.dart';
import 'training_focus.dart';

class TechniqueFocus extends TrainingFocus {
  @override
  String get name => 'Technique';

  @override
  int get warmUpRatio => 25;
  @override
  int get preSetRatio => 20;
  @override
  int get mainSetRatio => 40;
  @override
  int get coolDownRatio => 15;

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.snorkel,
    EquipmentType.paddles,
  ];

  @override
  List<String> get aiPromptTags => ['technique', 'drills', 'efficiency', 'form'];

  @override
  String generatePrompt() => """
### Training Focus: Technique
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **Technique-focused swim session**.

Key principles:
- Emphasize efficiency, balance, and body position.
- Include controlled drills, skill progressions, and sculling.
- Maintain low intensity for precision and form.
- Use equipment like fins and snorkel for control.

Session requirements:
- Ensure sets support ${aiPromptTags.join(", ")}.
- Keep total distance 2000–4000m.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
