enum CheckPoint { start, offTheBlock, breakOut, fifteenMeterMark, turn, finish }

extension CheckPointDisplay on CheckPoint {
  String toDisplayString() {
    switch (this) {
      case CheckPoint.start:
        return "Start";
      case CheckPoint.offTheBlock:
        return "Left the block";
      case CheckPoint.breakOut:
        return "Breakout";
      case CheckPoint.fifteenMeterMark:
        return "15m Mark";
      case CheckPoint.turn:
        return "Turn";
      case CheckPoint.finish:
        return "Finish";
    }
  }
}

extension CheckPointDistance on CheckPoint {
  /// Returns the OFFICIAL race distance associated with this checkpoint.
  /// Used ONLY for generating summary tables.
  double expectedDistance({
    required int poolLengthMeters, // 25 or 50
    required int raceDistanceMeters, // 25, 50, 100, 200
  }) {
    switch (this) {
      case CheckPoint.start:
        return 0;

      case CheckPoint.offTheBlock:
      case CheckPoint.breakOut:
        return 5; // breakout ~5m for summary purposes

      case CheckPoint.fifteenMeterMark:
        return 15;

      case CheckPoint.turn:
        // 25m: only 1 turn (if >25)
        // 50m: turn at 25
        // 100m: turns at 25 + 75
        // 200m: turns at 25 + 75 + 125 + 175
        return poolLengthMeters.toDouble();

      case CheckPoint.finish:
        return raceDistanceMeters.toDouble();
    }
  }
}
