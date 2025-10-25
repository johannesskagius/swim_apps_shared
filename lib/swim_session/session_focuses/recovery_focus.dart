import '../generator/enums/equipment.dart';
import 'training_focus.dart';

class RecoveryFocus extends TrainingFocus {
  @override
  String get name => 'Recovery';

  @override
  int get warmUpRatio => 30;
  @override
  int get preSetRatio => 10;
  @override
  int get mainSetRatio => 40;
  @override
  int get coolDownRatio => 20;

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.snorkel,
  ];

  @override
  List<String> get aiPromptTags => ['recovery', 'aerobic', 'easy', 'drills'];

  @override
  String generatePrompt() => """
### Training Focus: Recovery
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **Recovery-focused swim session**.

Key principles:
- Use easy aerobic swimming and gentle drills.
- Emphasize relaxation, technique, and blood flow.
- Avoid fatigue; maintain low heart rate.
- Include mixed strokes or kicking.

Session requirements:
- Match ${aiPromptTags.join(", ")} goals.
- Keep total distance 1500–3000m.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
