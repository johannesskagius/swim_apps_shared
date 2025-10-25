import '../../objects/pool_length.dart';
import '../../swim_apps_shared.dart';
import 'checkpoint.dart';
import 'event.dart';

class HundredMetersRace extends Event {
  const HundredMetersRace({required super.stroke});

  @override
  String get name => '100m $stroke';
  @override
  int get distance => 100;
  @override
  PoolLength get poolLength => PoolLength.m25;

  @override
  List<CheckPoint> get checkPoints => [
    CheckPoint.start,
    CheckPoint.offTheBlock,
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.turn, // 25m
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.turn, // 50m
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.turn, // 75m
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.finish, // 100m
  ];
}