
import '../../objects/pool_length.dart';
import '../../objects/stroke.dart';
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
