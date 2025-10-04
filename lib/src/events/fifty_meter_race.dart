import 'checkpoint.dart';
import 'event.dart';

class FiftyMeterRace extends Event {
  const FiftyMeterRace({required super.stroke});

  @override
  String get name => '50m $stroke';
  @override
  int get distance => 50;
  @override
  int get poolLength => 25;

  @override
  List<CheckPoint> get checkPoints => [
    CheckPoint.start,
    CheckPoint.offTheBlock,
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.turn,
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.finish,
  ];
}