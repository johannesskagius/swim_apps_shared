import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';
import 'training_focus.dart';

class RacePaceSpeedFocus extends TrainingFocus {
  @override
  String get name => 'Race Pace Speed';

  @override
  int get warmUpRatio => 20;
  @override
  int get preSetRatio => 20;
  @override
  int get mainSetRatio => 50;
  @override
  int get coolDownRatio => 10;

  @override
  String get description =>
      'Train specific race-pace intensity and stroke mechanics under fatigue.';
  @override
  String get aiPurpose =>
      'Refine pace control and technical endurance at competition-level intensity.';
  @override
  String get recommendedSetTypes =>
      'Broken swims, descending 100s, 50s at target race pace, short rest cycles.';
  @override
  List<String> get coachingCues => [
    'hold pace',
    'strong turns',
    'controlled breathing',
    'efficient underwaters',
  ];

  @override
  List<EquipmentType> get recommendedEquipment => [
    EquipmentType.fins,
    EquipmentType.parachute,
    EquipmentType.snorkel,
  ];

  @override
  List<IntensityZone> get preferredIntensityZones => [
    IntensityZone.sp2,
    IntensityZone.sp1,
    IntensityZone.i4,
  ];

  @override
  List<String> get aiPromptTags => ['race pace', 'speed endurance', 'control', 'execution'];

  @override
  String generatePrompt() => """
### Training Focus: $name
**Description:** $description
**AI Purpose:** $aiPurpose
**Recommended Set Types:** $recommendedSetTypes
**Preferred Intensity Zones:** ${preferredIntensityZones.map((z) => z.name).join(", ")} (main set emphasis; warm-up and pre-set prepare pacing control)
**Coaching Cues:** ${coachingCues.join(', ')}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

Guidelines:
- Emphasize ${preferredIntensityZones.map((z) => z.name).join(", ")} zones.
- Recreate racing conditions with short, high-quality intervals.
- Integrate ${recommendedSetTypes.toLowerCase()}.
- Reinforce ${coachingCues.take(3).join(', ')} for performance control.

Session Requirements:
- 2500–4000m total.
- Keep technical precision under race stress.
- Output plain-text workout formatted for textToSessionParser.
""";
}
