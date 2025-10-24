import 'package:swim_apps_shared/swim_apps_shared.dart';
import 'training_focus.dart';

class RacePaceSpeedFocus extends TrainingFocus {
  @override
  String get name => 'Race Pace';

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
    EquipmentType.paddles,
    EquipmentType.pullBuoy,
  ];

  @override
  List<String> get aiPromptTags => ['race pace', 'speed endurance', 'competition'];

  @override
  String generatePrompt() => """
### Training Focus: Race Pace
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **Race-Pace swim session**.

Key principles:
- Train precise pacing and efficiency at race speed.
- Use structured intervals (25–100m) with consistent effort.
- Include broken swims and negative splits.
- Focus on form under fatigue.

Session requirements:
- Match effort to ${aiPromptTags.join(", ")}.
- Keep total distance 2500–4000m.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
