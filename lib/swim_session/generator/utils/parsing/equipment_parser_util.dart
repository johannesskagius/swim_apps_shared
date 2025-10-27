import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../enums/equipment.dart';

class EquipmentExtractionResult {
  final List<EquipmentType> foundEquipment;
  final String remainingLine;

  EquipmentExtractionResult(this.foundEquipment, this.remainingLine);
}

class EquipmentParserUtil {
  // Regex to find the first equipment block like "[fins paddles]".
  // This pattern is designed to be robust against extra spacing.
  static final RegExp _equipmentBlockPattern = RegExp(r"\[\s*([^\]]*?)\s*\]");

  /// Extracts the first equipment block (e.g., "[fins]") from a line of text.
  ///
  /// This function is the main entry point for parsing equipment from a string. It robustly
  /// handles cases where no equipment block is found, the block is empty `[]`, or the
  /// block contains equipment keywords.
  ///
  /// Returns an [EquipmentExtractionResult] containing:
  /// - `foundEquipment`: A list of [EquipmentType]s parsed from the block.
  /// - `remainingLine`: The original line with the equipment block removed.
  static EquipmentExtractionResult extractAndRemove(String line) {
    try {
      final Match? match = _equipmentBlockPattern.firstMatch(line);

      // If no equipment block (e.g., "[...]") is found, return the original line.
      if (match == null) {
        return EquipmentExtractionResult([], line);
      }

      // Refactoring: Safely access match groups. The previous use of `!` could
      // cause a crash if the regex pattern were ever changed in a way that
      // removed a capture group. This approach is safer.
      final String contentInsideBrackets = match.group(1) ?? '';
      final String fullMatchedBlock = match.group(0) ?? '';

      // If the matched block is empty, we cannot proceed. This is an
      // unexpected state that should be logged for investigation.
      if (fullMatchedBlock.isEmpty) {
        // Logging a non-fatal error to monitor if this edge case ever occurs.
        FirebaseCrashlytics.instance.recordError(
          Exception('Empty equipment block matched, which is unexpected.'),
          StackTrace.current,
          reason: 'A regex match for an equipment block was empty.',
        );
        return EquipmentExtractionResult([], line);
      }

      final List<EquipmentType> equipmentList;

      // According to the logic, an empty block "[]" signifies "no equipment".
      if (contentInsideBrackets.trim().isEmpty) {
        equipmentList = [EquipmentType.none];
      } else {
        // If the block has content, parse it to identify specific equipment.
        equipmentList = _parseContent(contentInsideBrackets);
      }

      // Cleanly remove the parsed block from the line.
      final String remainingLine = line.replaceFirst(fullMatchedBlock, '').trim();
      return EquipmentExtractionResult(equipmentList, remainingLine);
    } catch (e, s) {
      // Error Handling: A try-catch block is added as a safety net to prevent
      // any unexpected errors during regex matching or string manipulation from
      // crashing the application.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to extract or remove equipment block from line.',
      );
      // Failsafe: If an error occurs, return the original line without modification
      // to ensure the rest of the parsing process can continue.
      return EquipmentExtractionResult([], line);
    }
  }

  /// Refactored Function: Parses a non-empty string from within an equipment block.
  ///
  /// This private helper focuses solely on identifying equipment from a given string.
  /// It improves readability by isolating this complex logic from the `extractAndRemove` method.
  static List<EquipmentType> _parseContent(String contentString) {
    final Set<EquipmentType> foundEquipment = {};
    final String lowerText = contentString.trim().toLowerCase();

    // Iterate through all defined equipment types to find matches.
    for (final equipType in EquipmentType.values) {
      for (final keyword in equipType.parsingKeywords) {
        // Skip empty keywords to prevent incorrect matches. An empty keyword
        // is often a configuration error and should not match any equipment.
        if (keyword.trim().isEmpty) {
          continue;
        }

        // Use a word boundary regex to ensure "fin" doesn't match "fins".
        final keywordRegex = RegExp(
          r'\b' + RegExp.escape(keyword.toLowerCase()) + r'\b',
          caseSensitive: false,
        );

        if (keywordRegex.hasMatch(lowerText)) {
          foundEquipment.add(equipType);
        }
      }
    }

    // After finding all matches, apply precedence rules.
    return _applyEquipmentPrecedence(foundEquipment);
  }

  /// Refactored Function: Applies precedence rules to a set of found equipment.
  ///
  /// For example, if both "no equipment" (`EquipmentType.none`) and "fins" are
  /// found, the specific equipment ("fins") should take precedence. This function
  /// isolates that rule for clarity and easier testing.
  static List<EquipmentType> _applyEquipmentPrecedence(
      Set<EquipmentType> equipment) {
    // If EquipmentType.none was explicitly matched (e.g., by "no equipment")
    // but other specific equipment was also found, the specific equipment wins.
    // For example, in "[no equipment, fins]", we should only return [fins].
    if (equipment.contains(EquipmentType.none) && equipment.length > 1) {
      equipment.remove(EquipmentType.none);
    }

    // If after applying precedence, the set is empty (e.g., content was "[xyz]"),
    // return an empty list as no known equipment was found.
    return equipment.toList();
  }
}
