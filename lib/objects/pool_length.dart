import '../../swim_session/generator/enums/distance_units.dart';

/// Enum representing standard pool lengths.
enum PoolLength {
  m25(25, DistanceUnit.meters),
  m50(50, DistanceUnit.meters),
  y25(25, DistanceUnit.yards),
  unknown(0, DistanceUnit.meters); // Default/fallback case

  const PoolLength(this.distance, this.distanceUnit);
  final int distance;
  final DistanceUnit distanceUnit;

  /// Returns a user-friendly display string (e.g., "25m", "25y").
  String get toDisplayString {
    switch (this) {
      case PoolLength.m25:
        return '25m';
      case PoolLength.m50:
        return '50m';
      case PoolLength.y25:
        return '25y';
      case PoolLength.unknown:
        return 'N/A';
    }
  }
}