// lib/swim/ai/swimmer_session_prompt_builder.dart
import 'package:swim_apps_shared/src/objects/user/swimmer_focus_profile.dart';

class SwimmerSessionPromptBuilder {
  final SwimmerFocusProfile swimmerFocus;

  SwimmerSessionPromptBuilder(this.swimmerFocus);

  String buildPrompt() {
    final focus = swimmerFocus.trainingFocus;
    final swimmerName = swimmerFocus.swimmerName;
    final targetDistance = swimmerFocus.targetDistance;
    final strokes = swimmerFocus.focusStrokes.map((s) => s.name).join(", ");
    final durationText = swimmerFocus.targetDuration != null
        ? "${swimmerFocus.targetDuration!.inMinutes} min"
        : "N/A";

    final ratios = focus.normalizedRatios.entries
        .map((e) => "${e.key}: ${(e.value * 100).round()}%")
        .join(", ");

    final equipment = focus.recommendedEquipment.isEmpty
        ? "no specific equipment"
        : focus.recommendedEquipment.map((e) => e.name).join(", ");

    final tags = focus.aiPromptTags.join(", ");

    return """
### Swimmer Context
Name: $swimmerName
Focus strokes: $strokes
Target distance: ${targetDistance}m
Target duration: $durationText

### Training Focus Context
Type: ${focus.name}
Ratios: $ratios
Equipment: $equipment
Tags: $tags

### Objective
Generate a ${focus.name}-oriented swim session for $swimmerName
with approximately $targetDistance meters total work,
tailored for the listed strokes: $strokes.

### Session Requirements
- Respect the provided structure ratios and total distance.
- Include work balanced across selected strokes.
- Integrate equipment suggestions when natural.
- Maintain the intent of this training focus (${focus.name}).
- Keep output plain-text formatted for textToSessionParser.

---

${focus.generatePrompt()}
""";
  }
}
