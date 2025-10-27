import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';
import 'training_focus.dart';

class MixedFocus extends TrainingFocus {
  @override
  String get name => 'Mixed / General Purpose';

  @override
  int get warmUpRatio => 20;
  @override
  int get preSetRatio => 10;
  @override
  int get mainSetRatio => 55;
  @override
  int get coolDownRatio => 15;

  @override
  String get description =>
      'Maintain overall swim fitness through a balanced mix of aerobic, technique, and short speed elements.';
  @override
  String get aiPurpose =>
      'Blend endurance, technique, and moderate intensity work to develop all-round performance.';
  @override
  String get recommendedSetTypes =>
      'Combination sets (aerobic + speed), drill transitions, variable distance series.';
  @override
  List<String> get coachingCues => [
    'rhythm control',
    'stroke balance',
    'pace awareness',
    'smooth transitions',
  ];

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.paddles,
    EquipmentType.snorkel,
  ];

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i2,
    IntensityZone.i3,
    IntensityZone.sp1,
  ];

  @override
  List<String> get aiPromptTags => ['mixed', 'balanced', 'aerobic', 'speed blend'];

  @override
  String generatePrompt() => """
### Training Focus: $name
**Description:** $description
**AI Purpose:** $aiPurpose
**Recommended Set Types:** $recommendedSetTypes
**Preferred Intensity Zones:** ${preferredIntensityZones.map((z) => z.name).join(", ")} (main set emphasis; include lighter touch in warm-up and pre-set)
**Coaching Cues:** ${coachingCues.join(', ')}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

Guidelines:
- Mix ${preferredIntensityZones.map((z) => z.name).join(", ")} across segments.
- Use ${recommendedSetTypes.toLowerCase()}.
- Include both aerobic control and short bursts of speed.
- Reinforce ${coachingCues.take(2).join(' and ')}.

Session Requirements:
- 3000–5000m total.
- Provide variety but maintain logical flow.
- Output plain-text workout formatted for textToSessionParser.
""";
}
