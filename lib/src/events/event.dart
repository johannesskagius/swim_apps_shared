import 'package:swim_apps_shared/src/objects/pool_length.dart';
import 'package:swim_apps_shared/src/objects/stroke.dart';

import 'checkpoint.dart';

abstract class
Event {
  final Stroke stroke;

  const Event({required this.stroke});

  String get name;

  int get distance;

  PoolLength get poolLength;

  List<CheckPoint> get checkPoints;
}
