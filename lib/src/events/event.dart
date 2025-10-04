import 'package:swim_apps_shared/src/objects/stroke.dart';

import 'checkpoint.dart';

abstract class Event {
  final Stroke stroke;

  const Event({required this.stroke});

  String get name;
  int get distance;
  int get poolLength;
  List<CheckPoint> get checkPoints;
}