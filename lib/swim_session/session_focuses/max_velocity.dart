import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';
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
  String get description =>
      'Train maximal swimming speed through ultra-short, high-intensity efforts with full recovery.';
  @override
  String get aiPurpose =>
      'Maximize neuromuscular output and stroke velocity without inducing fatigue or technical breakdown.';
  @override
  String get recommendedSetTypes =>
      '10–25m maximal efforts, assisted and resisted sprints, breakout training, reaction starts.';
  @override
  List<String> get coachingCues => [
    'maximum speed from first stroke',
    'explosive breakout',
    'streamlined body position',
    'full recovery before next effort',
    'no loss of quality',
  ];

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.resistanceBand,
    EquipmentType.parachute,
  ];

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.sp3,
    IntensityZone.max,
  ];

  @override
  List<String> get aiPromptTags =>
      ['max velocity', 'sprint', 'power', 'explosive', 'neural activation'];

  @override
  String generatePrompt() => """
### Training Focus: $name
**Description:** $description
**AI Purpose:** $aiPurpose
**Recommended Set Types:** $recommendedSetTypes
**Preferred Intensity Zones:** ${preferredIntensityZones.map((z) => z.name).join(", ")} (main set focus; mirrored at lower intensity during warm-up and pre-set)
**Coaching Cues:** ${coachingCues.join(', ')}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **$name-focused swim session** designed to push top-end speed safely and effectively.

Guidelines:
- Use ${preferredIntensityZones.map((z) => z.name).join(", ")} intensity in short, isolated efforts.
- Keep each repetition 10–25m max, full rest (1:5–1:10 work:rest ratio).
- Incorporate ${recommendedSetTypes.toLowerCase()}.
- Maintain ${coachingCues.take(3).join(', ')} throughout.
- Stop sets before fatigue reduces speed or quality.

Session Requirements:
- Total sprint volume ≤ 400m.
- Focus on neural activation and pure velocity.
- Output plain-text workout formatted for textToSessionParser.
""";
}
