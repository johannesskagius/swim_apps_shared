// lib/swim/ai/swimmer_focus_profile.dart
import 'package:swim_apps_shared/swim_apps_shared.dart';

class SwimmerFocusProfile {
  String id; // Unique document ID (Firestore or local)
  String swimmerId;
  String swimmerName;
  TrainingFocus trainingFocus;
  List<Stroke> focusStrokes;
  int targetDistance; // in meters
  Duration? targetDuration; // optional, for timed sessions

  SwimmerFocusProfile({
    required this.id,
    required this.swimmerId,
    required this.swimmerName,
    required this.trainingFocus,
    required this.focusStrokes,
    required this.targetDistance,
    this.targetDuration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'swimmerId': swimmerId,
    'swimmerName': swimmerName,
    'trainingFocusName': trainingFocus.name,
    'focusStrokes': focusStrokes.map((s) => s.name).toList(),
    'targetDistance': targetDistance,
    if (targetDuration != null)
      'targetDuration': targetDuration!.inSeconds,
  };

  factory SwimmerFocusProfile.fromJson(Map<String, dynamic> json) {
    return SwimmerFocusProfile(
      id: json['id'] ?? '',
      swimmerId: json['swimmerId'] ?? '',
      swimmerName: json['swimmerName'] ?? '',
      trainingFocus: TrainingFocusFactory.fromName(json['trainingFocusName']),
      focusStrokes: (json['focusStrokes'] as List<dynamic>? ?? [])
          .map((name) => Stroke.fromString(name))
          .whereType<Stroke>() // filters out nulls automatically
          .toList(),
      targetDistance: json['targetDistance'] ?? 0,
      targetDuration: json['targetDuration'] != null
          ? Duration(seconds: json['targetDuration'])
          : null,
    );
  }
}
