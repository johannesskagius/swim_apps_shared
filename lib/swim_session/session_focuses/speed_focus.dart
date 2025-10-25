
import 'package:swim_apps_shared/swim_session/session_focuses/training_focus.dart';

import '../generator/enums/equipment.dart';

class SpeedFocus extends TrainingFocus {
  @override
  String get name => 'Speed';

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
    EquipmentType.parachute,
    EquipmentType.resistanceBand,
  ];

  @override
  List<String> get aiPromptTags => ['speed', 'explosive', 'sprint', 'power'];

  @override
  String generatePrompt() => """
### Training Focus: Speed
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **Speed-focused swim session**.

Key principles:
- Focus on short, explosive efforts (15–50m) at near-max intensity.
- Allow full recovery between efforts (1:3–1:6).
- Maintain excellent technique at high velocity.
- Optionally integrate resisted or assisted sprinting.

Session requirements:
- Respect energy system and recovery balance.
- Use up to ~800m total sprinting.
- Return only plain-text workout formatted for textToSessionParser.
""";

}
