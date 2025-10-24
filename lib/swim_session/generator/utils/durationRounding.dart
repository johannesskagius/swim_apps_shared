// Place this in a utility file (e.g., lib/swim/utils/duration_extensions.dart)
// or at the top level of a relevant file if it's only used locally.

extension DurationRounding on Duration {
  /// Rounds the total seconds of the Duration to the nearest multiple of [roundingValueInSeconds].
  /// Defaults to rounding to the nearest 5 seconds.
  Duration roundToNearestSeconds(int roundingValueInSeconds) {
    if (roundingValueInSeconds <= 0)
      return this; // Avoid division by zero or invalid input

    int totalSeconds = inSeconds;
    int remainder = totalSeconds % roundingValueInSeconds;

    if (remainder == 0) {
      return this; // Already a multiple
    }

    // If remainder is more than half of roundingValue, round up
    // Otherwise, round down
    if (remainder * 2 >= roundingValueInSeconds) {
      return Duration(
        seconds: totalSeconds - remainder + roundingValueInSeconds,
      );
    } else {
      return Duration(seconds: totalSeconds - remainder);
    }
  }

  /// Convenience method to round to the nearest 5 seconds.
  Duration roundToNearest5Seconds() {
    return roundToNearestSeconds(5);
  }

  /// Convenience method to round to the nearest 10 seconds.
  Duration roundToNearest10Seconds() {
    return roundToNearestSeconds(10);
  }
}

extension DurationHelpers on Duration {
  /// Multiplies the duration by a given factor.
  /// Returns Duration.zero if the factor is not positive.
  Duration multiply(double factor) {
    if (factor <= 0) {
      // Or throw an ArgumentError, depending on how you want to handle invalid factors.
      // For rest ratios, factor should always be positive.
      return Duration.zero;
    }
    return Duration(milliseconds: (inMilliseconds * factor).round());
  }

  /// Example: Returns a duration 5% faster.
  Duration slightlyFaster() => multiply(0.95);

  /// Example: Returns a duration 5% slower.
  Duration slightlySlower() => multiply(1.05);
}

// Example Usage:
// final d1 = Duration(minutes: 1, seconds: 47);
// print(d1.roundToNearest5Seconds()); // Output: 0:01:45.000000

// final d2 = Duration(minutes: 1, seconds: 48);
// print(d2.roundToNearest5Seconds()); // Output: 0:01:50.000000

// final d3 = Duration(seconds: 52);
// print(d3.roundToNearest5Seconds()); // Output: 0:00:50.000000

// final d4 = Duration(seconds: 53);
// print(d4.roundToNearest5Seconds()); // Output: 0:00:55.000000
