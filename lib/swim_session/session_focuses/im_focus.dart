import '../generator/enums/equipment.dart';
import 'training_focus.dart';

class IMFocus extends TrainingFocus {
  @override
  String get name => 'Medley';

  @override
  int get warmUpRatio => 25;
  @override
  int get preSetRatio => 15;
  @override
  int get mainSetRatio => 50;
  @override
  int get coolDownRatio => 10;

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.paddles,
  ];

  @override
  List<String> get aiPromptTags => ['medley', 'im', 'stroke variety', 'transitions'];

  @override
  String generatePrompt() => """
### Training Focus: Medley
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating an **Individual Medley (IM)-focused swim session**.

Key principles:
- Incorporate all four strokes in balanced sequences.
- Emphasize transitions, rhythm, and stroke control.
- Include drills and kick sets for each stroke.
- Use IM and Reverse IM order for variation.

Session requirements:
- Respect ${aiPromptTags.join(", ")}.
- Keep total distance 3000–5000m.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
