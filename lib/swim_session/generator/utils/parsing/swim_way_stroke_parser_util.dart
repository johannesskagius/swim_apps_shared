import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/parsed_component.dart';

import '../../../../objects/stroke.dart';
import '../../enums/swim_way.dart';

class SwimWayStrokeParserUtil {
  /// Parses the main component text to identify the SwimWay and Stroke.
  /// This method is designed to be robust, handling potential parsing errors gracefully.
  ///
  /// It extracts the most specific SwimWay and Stroke from the text, prioritizing
  /// longer keywords to ensure accuracy (e.g., "fly kick" is correctly parsed).
  ///
  /// [mainText]: The input string to parse (e.g., "fly kick with fins").
  /// Returns a [ParsedItemComponents] object with the detected SwimWay and Stroke.
  static ParsedItemComponents parse(String mainText) {
    // The main parsing logic is wrapped in a try-catch block to handle any unexpected
    // exceptions during the process, preventing crashes.
    try {
      // Return default values immediately if the input text is null or empty to prevent
      // unnecessary processing and potential errors.
      if (mainText.trim().isEmpty) {
        return ParsedItemComponents(SwimWay.swim, Stroke.freestyle);
      }

      String remainingText = mainText.trim().toLowerCase();
      var detectedSwimWay = SwimWay.swim; // Default value

      // Refactored the SwimWay parsing into its own function for better separation of concerns and testability.
      final swimWayResult = _parseSwimEntity(
        text: remainingText,
        values: SwimWay.values,
        getKeywords: (way) => (way).parsingKeywords,
      );

      if (swimWayResult != null) {
        detectedSwimWay = swimWayResult.entity as SwimWay;
        remainingText = swimWayResult.remainingText;
      }

      var detectedStroke = Stroke.freestyle; // Default value

      // Refactored the Stroke parsing into the same helper function for consistency.
      final strokeResult = _parseSwimEntity(
        text: remainingText,
        values: Stroke.values,
        getKeywords: (stroke) => (stroke).parsingKeywords,
      );

      if (strokeResult != null) {
        detectedStroke = strokeResult.entity as Stroke;
        remainingText = strokeResult.remainingText;
      }

      return ParsedItemComponents(detectedSwimWay, detectedStroke);
    } catch (e, s) {
      // Non-fatal errors during parsing are logged to Firebase Crashlytics.
      // This allows developers to monitor parsing issues without crashing the app for the user.
      // The function then returns default values, ensuring the app remains stable.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'An error occurred in SwimWayStrokeParserUtil.parse',
      );
      return ParsedItemComponents(SwimWay.swim, Stroke.freestyle);
    }
  }

  /// A generic helper function to parse a swim entity (like SwimWay or Stroke) from text.
  /// It improves readability by abstracting the repetitive parsing logic.
  ///
  /// This function sorts entities and their keywords by length to find the most specific match first.
  ///
  /// [text]: The text to parse.
  /// [values]: A list of all possible entity values (e.g., SwimWay.values).
  /// [getKeywords]: A function to retrieve the parsing keywords for a given entity.
  /// Returns a [_ParseResult] containing the detected entity and remaining text, or null if no match is found.
  static _ParseResult? _parseSwimEntity<T>({
    required String text,
    required List<T> values,
    required List<String> Function(T) getKeywords,
  }) {
    // The list of entities is copied and sorted to prioritize longer, more specific keywords.
    // This prevents "pull" from matching before "scull", for example.
    final sortedEntities = List<T>.from(values)
      ..sort(
        (a, b) =>
            getKeywords(b).join("").length - getKeywords(a).join("").length,
      );

    for (final entity in sortedEntities) {
      // Keywords for each entity are also sorted by length to ensure the most specific match is found first.
      final sortedKeywords = List<String>.from(getKeywords(entity))
        ..sort((a, b) => b.length - a.length);

      for (final keyword in sortedKeywords.map((k) => k.toLowerCase())) {
        if (keyword.isEmpty)
          continue; // Skip empty keywords to prevent regex errors.

        // A regular expression with word boundaries ensures that we match whole words only.
        final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
        if (regex.hasMatch(text)) {
          // If a match is found, update the text by removing the keyword and compacting spaces.
          final newRemainingText = text
              .replaceFirst(regex, "")
              .replaceAll(RegExp(r"\s\s+"), " ")
              .trim();
          return _ParseResult(entity, newRemainingText);
        }
      }
    }
    // Return null if no entity keyword was found in the text.
    return null;
  }
}

/// A private helper class to hold the result of a parsing operation.
/// This improves code clarity by allowing the parsing function to return a structured object
/// instead of relying on mutable variables or complex data structures like maps.
class _ParseResult {
  final dynamic entity;
  final String remainingText;

  _ParseResult(this.entity, this.remainingText);
}
