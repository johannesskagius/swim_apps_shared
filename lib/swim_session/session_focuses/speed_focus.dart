import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';
import 'training_focus.dart';

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
  String get description =>
      'Develop explosive power, neuromuscular activation, and top-end swimming velocity.';
  @override
  String get aiPurpose =>
      'Maximize acceleration and speed endurance through controlled, short-distance efforts with full recovery.';
  @override
  String get recommendedSetTypes =>
      'Short sprints (15–50m), resisted or assisted sprint work, overspeed efforts, and broken swims.';
  @override
  List<String> get coachingCues => [
    'explosive starts',
    'fast turnover',
    'maximum effort',
    'full recovery',
    'maintain technique under fatigue',
  ];

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.parachute,
    EquipmentType.resistanceBand,
  ];

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.sp3,
    IntensityZone.sp2,
    IntensityZone.sp1,
    IntensityZone.max,
  ];

  @override
  List<String> get aiPromptTags => ['speed', 'sprint', 'power', 'explosive'];

  @override
  String generatePrompt() => """
### Training Focus: $name
**Description:** $description
**AI Purpose:** $aiPurpose
**Recommended Set Types:** $recommendedSetTypes
**Preferred Intensity Zones:** ${preferredIntensityZones.map((z) => z.name).join(", ")} (used in main set; light activation in warm-up & pre-set)
**Coaching Cues:** ${coachingCues.join(', ')}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a **$name-focused swim session** emphasizing power and velocity.

Guidelines:
- Use ${preferredIntensityZones.map((z) => z.name).join(", ")} zones primarily in the main set.
- Warm-up should activate neuromuscular readiness.
- Pre-set may include fast 25s or power build efforts.
- Maintain ${coachingCues.take(3).join(', ')}.
- Allow full recovery between high-intensity efforts.

Session Requirements:
- Keep total sprint distance under 800m.
- Include clear rest intervals (1:3–1:6 work:rest ratio).
- Output plain-text formatted for textToSessionParser.
""";
}
