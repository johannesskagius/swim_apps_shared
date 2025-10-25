
import '../swim_session/events/checkpoint.dart';

/// Represents a single recorded moment in a race.
class RaceSegment {
  final CheckPoint checkPoint;
  final Duration splitTimeOfTotalRace;

  RaceSegment({required this.checkPoint, required this.splitTimeOfTotalRace});
}