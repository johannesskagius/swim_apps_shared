import '../stroke.dart';
import 'event_specialization.dart';

class SwimmerFocusProfile {
  String id; // Unique document ID (Firestore or local)
  String swimmerId;
  String clubId;
  String coachId;
  String swimmerName;
  EventSpecialization eventSpecialization;
  List<Stroke> focusStrokes;
  int targetDistance; // in meters
  Duration? targetDuration; // optional, for timed sessions

  SwimmerFocusProfile({
    required this.id,
    required this.swimmerId,
    required this.swimmerName,
    required this.coachId,
    required this.clubId,
    required this.eventSpecialization,
    required this.focusStrokes,
    required this.targetDistance,
    this.targetDuration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'swimmerId': swimmerId,
    'swimmerName': swimmerName,
    'coachId': coachId,
    'clubId': clubId,
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
      coachId: json['coachId'] ?? '',
      clubId: json['clubId'] ?? '',
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
