import 'package:swim_apps_shared/src/events/checkpoint.dart';

/// Represents a single recorded moment in a race.
class RaceSegment {
  final CheckPoint checkPoint;
  final Duration time;

  RaceSegment({required this.checkPoint, required this.time});
}