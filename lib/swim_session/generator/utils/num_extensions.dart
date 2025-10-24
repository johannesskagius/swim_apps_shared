// lib/swim/generator/num_extensions.dart (or your preferred utility path)

extension RoundToNearestInt on int {
  /// Rounds this integer to the nearest multiple of [value].
  ///
  /// For example:
  /// - `7.roundToNearest(5)` would return `5`.
  /// - `8.roundToNearest(5)` would return `10`.
  /// - `10.roundToNearest(5)` would return `10`.
  /// - `12.roundToNearest(50)` would return `0`.
  /// - `25.roundToNearest(50)` would return `0`.
  /// - `30.roundToNearest(50)` would return `50`.
  /// - `75.roundToNearest(50)` would return `50`.
  /// - `80.roundToNearest(50)` would return `100`.
  ///
  /// If [value] is zero or negative, the original number is returned.
  int roundToNearest(int value) {
    if (value <= 0) {
      return this;
    }
    // Perform division as double to get decimal part for rounding
    double division = toDouble() / value;
    return (division.round() * value);
  }
}

extension RoundToNearestDouble on double {
  /// Rounds this double to the nearest multiple of [value] and returns an integer.
  ///
  /// For example:
  /// - `7.0.roundToNearest(5)` would return `5`.
  /// - `8.2.roundToNearest(5)` would return `10`.
  /// - `10.0.roundToNearest(5)` would return `10`.
  /// - `12.5.roundToNearest(50)` would return `0`.
  /// - `25.0.roundToNearest(50)` would return `50`. (standard rounding for .5 goes up)
  /// - `30.1.roundToNearest(50)` would return `50`.
  /// - `75.0.roundToNearest(50)` would return `50`.
  /// - `80.8.roundToNearest(50)` would return `100`.
  ///
  /// If [value] is zero or negative, the original number rounded to the nearest integer is returned.
  int roundToNearest(int value) {
    if (value <= 0) {
      return round(); // Or throw an error, depending on desired behavior
    }
    double division = this / value;
    return (division.round() * value);
  }
}
