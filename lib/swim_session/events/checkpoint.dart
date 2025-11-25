enum CheckPoint {
  start,
  offTheBlock,
  breakOut,
  fifteenMeterMark,
  turn,
  finish,
}

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
