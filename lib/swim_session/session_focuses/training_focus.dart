// lib/swim/generator/focus/training_focus.dart
import 'dart:math';

import '../../objects/intensity_zones.dart';
import '../generator/enums/equipment.dart';

abstract class TrainingFocus {
  abstract final String name;
  final Random random = Random();

  /// Structure ratios (% of total session)
  abstract final int warmUpRatio;
  abstract final int preSetRatio;
  abstract final int mainSetRatio;
  abstract final int coolDownRatio;

  /// --- 🧩 AI & Coaching Metadata ---
  /// Short, human-readable summary.
  abstract final String description;

  /// What the AI should optimize for (e.g., "endurance and pacing control").
  abstract final String aiPurpose;

  /// Common set patterns that fit this focus (helps AI choose structure).
  abstract final String recommendedSetTypes;

  /// Common coaching cues or words to emphasize in AI output.
  abstract final List<String> coachingCues;

  /// Preferred intensity zones for this focus.
  List<IntensityZone> get preferredIntensityZones;

  /// Equipment often used for this type of training.
  List<EquipmentType> get recommendedEquipment => [];

  /// Semantic tags that help AI anchor the prompt.
  List<String> get aiPromptTags => [name.toLowerCase()];

  String generatePrompt() =>
      """
### Training Focus: $name
**Tags:** ${aiPromptTags.join(", ")}
**Structure Ratios:** Warm-up $warmUpRatio%, Pre-set $preSetRatio%, Main-set $mainSetRatio%, Cool-down $coolDownRatio%
**Recommended Equipment:** ${recommendedEquipment.map((e) => e.name).join(", ")}

You are generating a $name-focused swim session.

Key principles:
- (custom focus logic)

Session requirements:
- Respect the above ratios and focus intent.
- Use ${recommendedEquipment.isEmpty ? "minimal equipment" : "recommended equipment"} where appropriate.
- Maintain training logic matching tags and energy systems.
- Return only the final swim workout, formatted for textToSessionParser.
""";

  /// Derived helpers
  int get totalRatio =>
      warmUpRatio + preSetRatio + mainSetRatio + coolDownRatio;

  Map<String, double> get normalizedRatios => {
    'warmUp': warmUpRatio / totalRatio,
    'preSet': preSetRatio / totalRatio,
    'mainSet': mainSetRatio / totalRatio,
    'coolDown': coolDownRatio / totalRatio,
  };

  /// Serialization
  Map<String, dynamic> toJson() => {
    'name': name,
    'warmUpRatio': warmUpRatio,
    'preSetRatio': preSetRatio,
    'mainSetRatio': mainSetRatio,
    'coolDownRatio': coolDownRatio,
  };

  // fromJson() stays the same as before

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TrainingFocus && name == other.name);

  @override
  int get hashCode => name.hashCode;
}
