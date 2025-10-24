import 'package:swim_apps_shared/src/objects/user/event_specialization.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';

class SwimmerSessionPromptBuilder {
  final SwimmerFocusProfile swimmerFocus;

  SwimmerSessionPromptBuilder(this.swimmerFocus);

  String buildPrompt() {
    final specialization = swimmerFocus.eventSpecialization;
    final swimmerName = swimmerFocus.swimmerName;
    final targetDistance = swimmerFocus.targetDistance;
    final strokes = swimmerFocus.focusStrokes.map((s) => s.name).join(", ");
    final durationText = swimmerFocus.targetDuration != null
        ? "${swimmerFocus.targetDuration!.inMinutes} min"
        : "N/A";

    // --- 🎯 Specialization-specific guidance ---
    final specializationContext = _getSpecializationPrompt(specialization);

    return """
# 🏊‍♂️ Swimmer Session Generator

### Swimmer Context
- Name: $swimmerName
- Focus strokes: $strokes
- Target distance: ${targetDistance}m
- Target duration: $durationText
- Event specialization: ${specialization.label}

### Objective
Generate a swim session for **$swimmerName**, a ${specialization.label} swimmer,
with approximately **$targetDistance meters total** work, tailored for the strokes: **$strokes**.

### Specialization Context
$specializationContext

### Session Requirements
- Keep total distance close to ${targetDistance}m.
- Distribute volume logically across warm-up, main set, and cool-down.
- Include stroke variety based on the focus strokes ($strokes).
- Output must be **plain text** formatted for `textToSessionParser`.
- Maintain physiological relevance to the swimmer’s specialization.
""";
  }

  // --- 🧠 Helper to generate specialization guidance ---
  String _getSpecializationPrompt(EventSpecialization specialization) {
    switch (specialization) {
      case EventSpecialization.sprint:
        return """
**Sprint (50–100m)** swimmers focus on:
- Maximum power and velocity.
- Short-distance, high-intensity repeats (15–50m).
- Full recovery between efforts (1:5–1:8 ratio).
- Neuromuscular activation and explosive starts.
- Technical efficiency at top speed.

Warm-up: progressive speed build with short accelerations.  
Main set: pure speed + race-pace work, total 1000–2000m.  
Cool-down: easy swimming and recovery.
""";

      case EventSpecialization.distance:
        return """
**Distance (800–1500m)** swimmers focus on:
- Aerobic endurance and efficiency.
- Long intervals (200–800m) with short rest.
- Stroke rhythm, pacing, and breathing control.
- Progressive overload and volume tolerance.

Warm-up: aerobic prep and stroke control.  
Main set: high-volume aerobic work, total 4000–6000m.  
Cool-down: long, easy recovery swim.
""";
      case EventSpecialization.middleDistance:
      default:
        return """
**Middle Distance (200–400m)** swimmers focus on:
- Sustained race pace and controlled lactate production.
- Medium-length intervals (100–400m) with moderate rest.
- Combination of aerobic and anaerobic load.
- Pacing consistency and technique under fatigue.

Warm-up: steady aerobic + drills.  
Main set: broken race swims or pace sets, total 2500–4000m.  
Cool-down: relaxed and technique-oriented.
""";
    }
  }
}
