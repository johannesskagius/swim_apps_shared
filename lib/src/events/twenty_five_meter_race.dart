import 'package:swim_apps_shared/src/objects/pool_length.dart';

import 'checkpoint.dart';
import 'event.dart';

class TwentyFiveMeterRace extends Event {
  const TwentyFiveMeterRace({required super.stroke});

  @override
  String get name => '25m ${stroke.description}';
  @override
  int get distance => 25;
  @override
  PoolLength get poolLength => PoolLength.m25;

  @override
  List<CheckPoint> get checkPoints => [
    CheckPoint.start,
    CheckPoint.offTheBlock,
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.finish,
  ];
}