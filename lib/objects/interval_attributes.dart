/// A class to hold the attributes for a single interval between checkpoints.
class IntervalAttributes {
  int dolphinKickCount = 0;
  int strokeCount = 0;
  int breathCount = 0;
  List<Duration> strokeTimestamps;
  double? averageStrokeFrequency;

  IntervalAttributes({
    this.strokeCount = 0,
    this.breathCount = 0,
    this.dolphinKickCount = 0,
    List<Duration>? strokeTimestamps,
    this.averageStrokeFrequency,
  }) : strokeTimestamps = strokeTimestamps ?? [];
}
