import 'dart:core';

// Helper class to return both the extracted interval and the modified line
class IntervalExtractionResult {
  final Duration? foundInterval;
  final String remainingLine;

  IntervalExtractionResult(this.foundInterval, this.remainingLine);
}

class IntervalParserUtil {
  // Regex to find common interval patterns like "@1:30" or "on 1:30"
  // It captures the keyword (@ or on) and the time string.
  // Added word boundary \b for "on" to make it more precise.
  static final RegExp _intervalPattern = RegExp(
    r"(@|\bon\b)\s*([\d:.]+)",
    caseSensitive: false,
  );

  /// Parses a string representation of an interval (e.g., "1:30", "90") into a Duration.
  ///
  /// Returns null if the string is null, empty, or cannot be parsed.
  static Duration? parseDuration(String? intervalStr) {
    if (intervalStr == null || intervalStr.trim().isEmpty) {
      return null;
    }

    final parts = intervalStr.split(':');
    try {
      if (parts.length == 1) {
        // Assume seconds if only one part (e.g., "90")
        final seconds = double.tryParse(parts[0]);
        if (seconds != null) {
          return Duration(milliseconds: (seconds * 1000).round());
        }
      } else if (parts.length == 2) {
        // Assume minutes and seconds (e.g., "1:30")
        final minutes = int.tryParse(parts[0]);
        final seconds = double.tryParse(parts[1]);
        if (minutes != null && seconds != null) {
          return Duration(
            minutes: minutes,
            milliseconds: (seconds * 1000).round(),
          );
        }
      } else if (parts.length == 3) {
        // Assume hours, minutes, and seconds (e.g., "1:05:10")
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        final seconds = double.tryParse(parts[2]);
        if (hours != null && minutes != null && seconds != null) {
          return Duration(
            hours: hours,
            minutes: minutes,
            milliseconds: (seconds * 1000).round(),
          );
        }
      }
    } catch (e) {
      // Catch any parsing errors (e.g., FormatException)
      print("Error parsing interval duration '$intervalStr': $e");
      return null; // Or return Duration.zero based on desired behavior for invalid
    }
    // If format is unrecognized or parsing failed
    return null; // Or Duration.zero
  }

  /// Extracts the first interval found in the line (e.g., "@1:30" or "on 90s").
  /// Returns an [IntervalExtractionResult] containing the parsed [Duration]
  /// and the line with the interval string removed.
  static IntervalExtractionResult extractAndRemove(String line) {
    Match? match = _intervalPattern.firstMatch(line);

    if (match != null) {
      String timeString = match.group(2)!; // The numeric part like "1:30"
      Duration? duration = parseDuration(timeString);

      // Remove the matched part from the line
      String remainingLine =
          line.substring(0, match.start) + line.substring(match.end);

      return IntervalExtractionResult(duration, remainingLine.trim());
    }

    // No interval pattern found
    return IntervalExtractionResult(null, line);
  }
}
