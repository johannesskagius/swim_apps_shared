import 'dart:core';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
  /// This method is designed to be robust, handling various time formats including
  /// seconds-only, minutes:seconds, and hours:minutes:seconds.
  ///
  /// Returns null and logs a non-fatal error to Firebase Crashlytics if the
  /// string is malformed or cannot be parsed.
  static Duration? parseDuration(String? intervalStr) {
    // 1. Initial Validation: Return early for null or empty strings to prevent
    // further processing on invalid input.
    if (intervalStr == null || intervalStr.trim().isEmpty) {
      return null;
    }

    final parts = intervalStr.trim().split(':');

    try {
      // Refactored logic into separate, testable functions for clarity.
      switch (parts.length) {
        case 1:
          return _parseSeconds(parts[0]);
        case 2:
          return _parseMinutesAndSeconds(parts[0], parts[1]);
        case 3:
          return _parseHoursMinutesAndSeconds(parts[0], parts[1], parts[2]);
        default:
        // 2. Error Handling: If the format is unexpected (e.g., "1:2:3:4"),
        // it's an invalid format. Log it for analytics.
          final error = FormatException("Invalid time format: Too many parts.", intervalStr);
          FirebaseCrashlytics.instance.recordError(
            error,
            StackTrace.current,
            reason: 'Failed to parse swim interval duration due to unexpected format.',
          );
          return null;
      }
    } catch (e, s) {
      // 3. Robust Error Handling: Catch any unexpected parsing errors that might occur,
      // such as a FormatException from int.parse if the input is malformed (e.g., "1:a").
      // Logging this helps identify and fix edge cases from user input.
      print("Error parsing interval duration '$intervalStr': $e");
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'A non-fatal error occurred while parsing a swim interval.',
      );
      return null;
    }
  }

  /// Parses a string representing total seconds (e.g., "90") into a Duration.
  static Duration? _parseSeconds(String secPart) {
    final seconds = double.tryParse(secPart);
    if (seconds != null) {
      // Use Duration(milliseconds: ...) to handle fractional seconds correctly.
      return Duration(milliseconds: (seconds * 1000).round());
    }
    return null;
  }

  /// Parses strings representing minutes and seconds (e.g., "1", "30.5") into a Duration.
  static Duration? _parseMinutesAndSeconds(String minPart, String secPart) {
    final minutes = int.tryParse(minPart);
    final seconds = double.tryParse(secPart);

    if (minutes != null && seconds != null) {
      return Duration(
        minutes: minutes,
        milliseconds: (seconds * 1000).round(),
      );
    }
    return null;
  }

  /// Parses strings for hours, minutes, and seconds into a Duration.
  static Duration? _parseHoursMinutesAndSeconds(String hrPart, String minPart, String secPart) {
    final hours = int.tryParse(hrPart);
    final minutes = int.tryParse(minPart);
    final seconds = double.tryParse(secPart);

    if (hours != null && minutes != null && seconds != null) {
      return Duration(
        hours: hours,
        minutes: minutes,
        milliseconds: (seconds * 1000).round(),
      );
    }
    return null;
  }


  /// Extracts the first interval found in the line (e.g., "@1:30" or "on 90s").
  /// Returns an [IntervalExtractionResult] containing the parsed [Duration]
  /// and the line with the interval string removed.
  static IntervalExtractionResult extractAndRemove(String line) {
    final Match? match = _intervalPattern.firstMatch(line);

    if (match == null) {
      // No interval pattern found, return the original line.
      return IntervalExtractionResult(null, line);
    }

    // The numeric part like "1:30" or "90".
    // Group 2 is guaranteed to be non-null if `match` is not null.
    final String timeString = match.group(2)!;
    final Duration? duration = parseDuration(timeString);

    // If parsing fails, duration will be null, which is the desired outcome.
    // The malformed interval text is still removed from the line.

    // Remove the matched part (e.g., "@1:30") from the line.
    final String remainingLine = line.replaceRange(match.start, match.end, '').trim();

    return IntervalExtractionResult(duration, remainingLine);
  }
}
