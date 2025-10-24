
import 'package:flutter/foundation.dart';

import '../../enums/set_types.dart';

class SectionHeaderParseResult {
  final SetType setType;
  final String?
  notes; // Note extracted from the header line, e.g., 'for sprinters'
  final String rawKeyword; // e.g., "Warm Up"

  SectionHeaderParseResult({
    required this.setType,
    this.notes,
    required this.rawKeyword,
  });
}

class SectionHeaderParserUtil {
  // --- FIX APPLIED HERE ---
  // The logic is now broken into explicit, typed steps to resolve type errors.
  static RegExp _buildSectionTitleRegex() {
    // 1. Create a list to hold the individual regex patterns for each keyword.
    final List<String> keywordPatterns = [];

    // 2. Loop through each enum value.
    for (final type in SetType.values) {
      // 3. Explicitly get the display string and ensure it's a String.
      final String displayString = type.toDisplayString();

      // 4. Escape the string to handle any special regex characters safely.
      final String escapedString = RegExp.escape(displayString);

      // 5. Replace spaces with a flexible pattern to allow for "Main Set" or "Main-Set".
      final String pattern = escapedString.replaceAll(" ", r"[\s-]*");

      keywordPatterns.add(pattern);
    }

    // 6. Join all individual patterns with the OR operator `|`.
    final String setTypeKeywords = keywordPatterns.join("|");

    // 7. Construct the final, correct RegExp.
    return RegExp(
      '^\\s*($setTypeKeywords)\\s*(?:[\'"“](.*?)["”\']?)?\\s*\$',
      // Correct the quotes
      caseSensitive: false,
    );
  }

  // The regex is now created correctly and stored as a static final variable
  // for performance, so it's compiled only once.
  static final RegExp _sectionTitleRegex = _buildSectionTitleRegex();

  // The same explicit typing fix is applied here for safety and consistency.
  static SetType _mapKeywordToSetType(String keyword) {
    // Normalize the keyword from the parsed text line.
    final String normalizedKeyword = keyword.toLowerCase().replaceAll(
      RegExp(r"[\s-]+"),
      "",
    );

    // Loop through all possible SetType enum values.
    for (final type in SetType.values) {
      // Normalize the display string from the enum in the same way.
      final String displayString = type.toDisplayString();
      final String normalizedDisplayString = displayString
          .toLowerCase()
          .replaceAll(RegExp(r"[\s-]+"), "");

      // The comparison is now clearly between two String variables.
      if (normalizedDisplayString == normalizedKeyword) {
        return type;
      }
    }

    debugPrint("Warning: Unrecognized set type keyword after regex match: $keyword");
    return SetType.mainSet; // Default or throw error
  }

  /// Parses a line to see if it's a section header (e.g., "Warm Up 'easy'").
  /// Returns a [SectionHeaderParseResult] if a valid section header is found,
  /// otherwise returns `null`.
  static SectionHeaderParseResult? parse(String line) {
    final Match? match = _sectionTitleRegex.firstMatch(line.trim());

    if (match != null) {
      final String rawKeyword = match.group(1)!.trim();
      final String? notes = match.group(2)?.trim();

      final SetType setType = _mapKeywordToSetType(rawKeyword);

      return SectionHeaderParseResult(
        setType: setType,
        notes: notes,
        rawKeyword: rawKeyword,
      );
    }
    return null;
  }
}
