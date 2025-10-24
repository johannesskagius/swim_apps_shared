
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
    final List<String> keywordPatterns = [];

    for (final type in SetType.values) {
      // Collect all possible forms: display name + parsing keywords
      final Set<String> allPatterns = {
        type.toDisplayString(),
        ...type.parsingKeywords,
      };

      for (final keyword in allPatterns) {
        final escaped = RegExp.escape(keyword.trim());
        final pattern = escaped.replaceAll(" ", r"[\s-]*");
        keywordPatterns.add(pattern);
      }
    }

    final String setTypeKeywords = keywordPatterns.join("|");

    return RegExp(
      '^\\s*($setTypeKeywords)\\s*:?(?:\\s*[\'"“](.*?)["”\']?)?\\s*\$',
      caseSensitive: false,
    );
  }


  // The regex is now created correctly and stored as a static final variable
  // for performance, so it's compiled only once.
  static final RegExp _sectionTitleRegex = _buildSectionTitleRegex();

  // The same explicit typing fix is applied here for safety and consistency.
  static SetType _mapKeywordToSetType(String keyword) {
    final normalized = keyword.toLowerCase().replaceAll(RegExp(r"[\s:-]+"), "");

    for (final type in SetType.values) {
      final allForms = {
        type.toDisplayString(),
        ...type.parsingKeywords,
      };

      for (final form in allForms) {
        final normalizedForm = form.toLowerCase().replaceAll(RegExp(r"[\s:-]+"), "");
        if (normalizedForm == normalized) return type;
      }
    }

    debugPrint("Warning: Unrecognized set type keyword: $keyword");
    return SetType.mainSet;
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
