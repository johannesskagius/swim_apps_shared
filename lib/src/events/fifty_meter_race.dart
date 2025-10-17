import 'package:swim_apps_shared/src/objects/pool_length.dart';

import 'checkpoint.dart';
import 'event.dart';

class FiftyMeterRace extends Event {
  final bool fromDive;

  const FiftyMeterRace({required super.stroke, this.fromDive = true});

  @override
  String get name => '50m ${stroke.description}';

  @override
  int get distance => 50;

  @override
  PoolLength get poolLength => PoolLength.m25;

  @override
  List<CheckPoint> get checkPoints => fromDive
      ? [
          CheckPoint.start,
          CheckPoint.offTheBlock,
          CheckPoint.breakOut,
          CheckPoint.fifteenMeterMark,
          CheckPoint.turn,
          CheckPoint.breakOut,
          CheckPoint.fifteenMeterMark,
          CheckPoint.finish,
        ]
      : [
          CheckPoint.offTheBlock,
          CheckPoint.breakOut,
          CheckPoint.fifteenMeterMark,
          CheckPoint.turn,
          CheckPoint.breakOut,
          CheckPoint.fifteenMeterMark,
          CheckPoint.finish
        ];
}
