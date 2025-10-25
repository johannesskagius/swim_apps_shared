import '../../objects/pool_length.dart';
import 'checkpoint.dart';
import 'event.dart';

class TwentyFiveMeterRace extends Event {
  final bool fromDive;

  TwentyFiveMeterRace({required super.stroke, this.fromDive = true});

  @override
  String get name => '25m ${stroke.description}';

  @override
  int get distance => 25;

  @override
  PoolLength get poolLength => PoolLength.m25;

  @override
  List<CheckPoint> get checkPoints => fromDive ? [
    CheckPoint.start,
    CheckPoint.offTheBlock,
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.finish,
  ]:[
    CheckPoint.offTheBlock,
    CheckPoint.breakOut,
    CheckPoint.fifteenMeterMark,
    CheckPoint.finish,
  ];
}
