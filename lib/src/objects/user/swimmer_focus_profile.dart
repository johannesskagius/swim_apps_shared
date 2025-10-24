// lib/swim/ai/swimmer_focus_profile.dart
import 'package:swim_apps_shared/src/objects/user/event_specialization.dart';
import 'package:swim_apps_shared/swim_apps_shared.dart';

class SwimmerFocusProfile {
  String id; // Unique document ID (Firestore or local)
  String swimmerId;
  String swimmerName;
  EventSpecialization eventSpecialization;
  List<Stroke> focusStrokes;
  int targetDistance; // in meters
  Duration? targetDuration; // optional, for timed sessions

  SwimmerFocusProfile({
    required this.id,
    required this.swimmerId,
    required this.swimmerName,
    required this.eventSpecialization,
    required this.focusStrokes,
    required this.targetDistance,
    this.targetDuration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'swimmerId': swimmerId,
    'swimmerName': swimmerName,
    'eventSpecializationName': eventSpecialization.name,
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
      eventSpecialization: EventSpecialization.fromString(json['eventSpecializationName']),
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
