import 'package:swim_apps_shared/src/objects/pool_length.dart';

import 'checkpoint.dart';
import 'event.dart';

class FiftyMeterRace extends Event {
  const FiftyMeterRace({required super.stroke});

  @override
  String get name => '50m $stroke';
  @override
  int get distance => 50;
  @override
  PoolLength get poolLength => PoolLength.m25;

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