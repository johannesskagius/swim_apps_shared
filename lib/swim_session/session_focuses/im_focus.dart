import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';
import 'training_focus.dart';

class IMFocus extends TrainingFocus {
  @override
  String get name => 'IM / Medley';

  @override
  int get warmUpRatio => 20;
  @override
  int get preSetRatio => 15;
  @override
  int get mainSetRatio => 50;
  @override
  int get coolDownRatio => 15;

  @override
  String get description =>
      'Enhance versatility and stroke transitions through medley-based training.';
  @override
  String get aiPurpose =>
      'Improve stroke balance and transition efficiency between all four strokes.';
  @override
  String get recommendedSetTypes =>
      'IM order sets, stroke-specific drills, variable distance transitions.';
  @override
  List<String> get coachingCues => [
    'controlled transitions',
    'stroke differentiation',
    'efficient turns',
    'tempo awareness',
  ];

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.snorkel,
  ];

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i3,
    IntensityZone.i4,
  ];

  @override
  List<String> get aiPromptTags => ['IM', 'medley', 'strokes', 'transitions'];

  @override
  String generatePrompt() => """
### Training Focus: $name
**Description:** $description
**AI Purpose:** $aiPurpose
**Recommended Set Types:** $recommendedSetTypes
**Preferred Intensity Zones:** ${preferredIntensityZones.map((z) => z.name).join(", ")} (main set; also represented lightly in warm-up and pre-set)
**Coaching Cues:** ${coachingCues.join(', ')}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

Guidelines:
- Cover all four strokes regularly (Fly, Back, Breast, Free).
- Alternate IM and stroke-specific focus sets.
- Apply ${preferredIntensityZones.map((z) => z.name).join(", ")} intensity scaling.
- Emphasize ${coachingCues.take(2).join(' and ')}.

Session Requirements:
- 3500–5500m total.
- Logical progression of strokes and intensity.
- Output plain-text workout formatted for textToSessionParser.
""";
}
