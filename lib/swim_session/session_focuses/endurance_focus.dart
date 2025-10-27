import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';
import 'training_focus.dart';

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
  String get description =>
      'Build aerobic capacity and pacing consistency through longer repeats and sustained effort.';
  @override
  String get aiPurpose =>
      'Enhance aerobic efficiency and steady-state control while maintaining good stroke technique.';
  @override
  String get recommendedSetTypes =>
      'Long repeats (200–800m), negative splits, broken swims, and steady aerobic intervals.';
  @override
  List<String> get coachingCues => [
    'even pacing',
    'controlled breathing',
    'consistent rhythm',
    'focus on efficiency',
  ];

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.pullBuoy,
    EquipmentType.paddles,
    EquipmentType.snorkel,
  ];

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.i1,
    IntensityZone.i2,
    IntensityZone.i3,
  ];

  @override
  List<String> get aiPromptTags => ['endurance', 'aerobic', 'pacing', 'stamina'];

  @override
  String generatePrompt() => """
### Training Focus: $name
**Description:** $description
**AI Purpose:** $aiPurpose
**Recommended Set Types:** $recommendedSetTypes
**Preferred Intensity Zones:** ${preferredIntensityZones.map((z) => z.name).join(", ")} (main set target; mirrored with lighter load in warm-up and pre-set)
**Coaching Cues:** ${coachingCues.join(', ')}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

Guidelines:
- Use ${preferredIntensityZones.map((z) => z.name).join(", ")} intensity to build endurance and pacing.
- Warm-up and pre-set should gradually approach main-set intensity.
- Include ${recommendedSetTypes.toLowerCase()}.
- Maintain ${coachingCues.take(3).join(', ')} throughout.

Session Requirements:
- Total distance 4000–6000m.
- Avoid sprint-type sets.
- Return plain-text workout formatted for textToSessionParser.
""";
}
