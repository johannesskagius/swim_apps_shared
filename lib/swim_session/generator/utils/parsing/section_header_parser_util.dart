import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../enums/set_types.dart';

class SectionHeaderParseResult {
  final SetType setType;
  final String? notes;       // e.g., 'for sprinters'
  final String rawKeyword;   // e.g., "Warm Up"

  SectionHeaderParseResult({
    required this.setType,
    this.notes,
    required this.rawKeyword,
  });
}

class SectionHeaderParserUtil {
  // Class for all space/dash-like separators (ASCII + Unicode).
  static final RegExp _sepClass = RegExp(r'[\s_\u2010-\u2015-]+');
  static const String _sepFlexible = r'[\s_\u2010-\u2015-]*';

  // --- Refactoring Start: Pre-computation and Caching ---

  // A cached, lazily-initialized map for efficient keyword to SetType lookups.
  // This avoids re-computing the mapping on every parse call, improving performance.
  static final Map<String, SetType> _keywordToSetTypeMap = _buildKeywordMap();

  // A lazily-initialized regex pattern. The logic is now encapsulated in helper methods.
  static final RegExp _sectionTitleRegex = _buildSectionTitleRegex();

  /// Builds a map from a normalized keyword string to its corresponding SetType.
  /// Normalization involves converting to lowercase and removing all separators.
  static Map<String, SetType> _buildKeywordMap() {
    final Map<String, SetType> map = {};
    for (final type in SetType.values) {
      final Set<String> allForms = {
        type.toDisplayString(),
        ...type.parsingKeywords,
      };

      for (final form in allForms) {
        // The key is the normalized form, ensuring consistent lookups.
        final normalizedForm = _normalizeKeyword(form);
        if (normalizedForm.isNotEmpty) {
          map[normalizedForm] = type;
        }
      }
    }
    return map;
  }

  /// Helper to generate a regex pattern for a single keyword.
  /// It splits the keyword by separators and rejoins them with a flexible separator regex.
  /// This allows matching variants like "Warm-up", "Warm up", and "Warm_up".
  static String _createKeywordPattern(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return "";

    final tokens = trimmed.split(_sepClass);
    return tokens.map(RegExp.escape).join(_sepFlexible);
  }

  /// Constructs the main regex for parsing section headers.
  /// This regex is built once and cached for efficiency.
  static RegExp _buildSectionTitleRegex() {
    // Generate regex patterns for all unique keywords from the map.
    final keywordPatterns = _keywordToSetTypeMap.keys
        .map(_createKeywordPattern)
        .where((p) => p.isNotEmpty)
        .toSet() // Use a Set to handle keywords that normalize to the same string.
        .toList();

    final String setTypeKeywords = keywordPatterns.join("|");

    // The regex captures the keyword (group 1) and optional notes (group 2).
    // It's case-insensitive and handles optional colons and surrounding whitespace.
    return RegExp(
      '^\\s*($setTypeKeywords)\\s*:?(?:\\s*[\'"“](.*?)["”\']?)?\\s*\$',
      caseSensitive: false,
    );
  }

  /// Normalizes a keyword by converting it to lowercase and removing separators.
  static String _normalizeKeyword(String keyword) {
    return keyword.toLowerCase().replaceAll(_sepClass, '').replaceAll(':', '');
  }

  // --- Refactoring End ---

  /// Maps a matched keyword from the regex to its corresponding [SetType].
  /// This now uses the pre-computed map for an efficient O(1) lookup.
  static SetType _mapKeywordToSetType(String keyword) {
    final normalizedKeyword = _normalizeKeyword(keyword);

    // Perform the lookup in the cached map.
    final setType = _keywordToSetTypeMap[normalizedKeyword];

    if (setType != null) {
      return setType;
    }

    // --- Error Handling Improvement ---
    // If a keyword was matched by the regex but is not in our map, it indicates a
    // logic error (e.g., regex and map are out of sync). This is a non-fatal
    // error that should be logged for analysis.
    final error = ArgumentError("Unrecognized set type keyword after regex match: $keyword");
    debugPrint("⚠️ ${error.message}");
    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: 'A keyword was matched by the regex but could not be mapped to a SetType.',
    );

    // Fallback to a sensible default to prevent crashes.
    return SetType.mainSet;
  }

  /// Parses a line to determine if it's a section header (e.g., "Warm-up: 'for sprinters'").
  /// Returns a [SectionHeaderParseResult] on success, or null if the line is not a header.
  static SectionHeaderParseResult? parse(String line) {
    try {
      final Match? match = _sectionTitleRegex.firstMatch(line.trim());
      if (match == null) return null;

      // --- Stability Improvement: Null-Safe Group Access ---
      // Use a null-safe access (`?`) instead of a force-unwrap (`!`) on the capture group.
      // This prevents a crash if the regex were to change and group 1 became optional.
      final String? rawKeyword = match.group(1)?.trim();
      if (rawKeyword == null || rawKeyword.isEmpty) {
        // This case should not be reachable with the current regex, but as a safeguard,
        // we log it as a non-fatal error if it ever occurs.
        FirebaseCrashlytics.instance.recordError(
          'Section header regex matched, but capture group 1 was null or empty.',
          StackTrace.current,
          reason: 'Regex integrity issue in SectionHeaderParserUtil.',
        );
        return null;
      }

      final String? notes = match.group(2)?.trim();
      final SetType setType = _mapKeywordToSetType(rawKeyword);

      return SectionHeaderParseResult(
        setType: setType,
        notes: notes,
        rawKeyword: rawKeyword,
      );
    } catch (e, s) {
      // --- Error Handling Improvement: Catching Unexpected Errors ---
      // This try-catch block provides a safety net against any unexpected exceptions
      // during the parsing process, such as a malformed regex or other runtime issues.
      // Logging this to Crashlytics helps identify and fix bugs.
      debugPrint("🚨 An unexpected error occurred in SectionHeaderParserUtil.parse: $e");
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Failed during section header parsing');
      return null; // Return null to indicate parsing failure.
    }
  }
}
