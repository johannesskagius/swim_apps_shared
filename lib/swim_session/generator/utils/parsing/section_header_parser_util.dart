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
  // Class for all space/dash-like separators (ASCII + Unicode)
  static final RegExp _sepClass = RegExp(r'[\s_\u2010-\u2015-]+');
  static const String _sepFlexible = r'[\s_\u2010-\u2015-]*';

  static RegExp _buildSectionTitleRegex() {
    final List<String> keywordPatterns = [];

    for (final type in SetType.values) {
      // Collect all forms: display + parsing keywords (without colons in keywords)
      final Set<String> allForms = {
        type.toDisplayString(),
        ...type.parsingKeywords,
      };

      for (final keyword in allForms) {
        final trimmed = keyword.trim();
        if (trimmed.isEmpty) continue;

        // Split on any dash/space-like char, escape each token,
        // then join with a flexible separator class so we match
        // Warm-up / Warm – up / Warm up / Warm_up, etc.
        final tokens = trimmed.split(_sepClass);
        final joined = tokens.map(RegExp.escape).join(_sepFlexible);

        keywordPatterns.add(joined);
      }
    }

    final String setTypeKeywords = keywordPatterns.join("|");

    // Optional colon after keyword, optional quoted notes after that
    return RegExp(
      '^\\s*($setTypeKeywords)\\s*:?(?:\\s*[\'"“](.*?)["”\']?)?\\s*\$',
      caseSensitive: false,
    );
  }

  static final RegExp _sectionTitleRegex = _buildSectionTitleRegex();

  static SetType _mapKeywordToSetType(String keyword) {
    // Normalize by removing any separator chars (space/dash family + colon)
    final normalizedKeyword =
    keyword.toLowerCase().replaceAll(_sepClass, '').replaceAll(':', '');

    for (final type in SetType.values) {
      final Set<String> allForms = {
        type.toDisplayString(),
        ...type.parsingKeywords,
      };

      for (final form in allForms) {
        final normalizedForm =
        form.toLowerCase().replaceAll(_sepClass, '').replaceAll(':', '');
        if (normalizedForm == normalizedKeyword) {
          return type;
        }
      }
    }

    debugPrint("⚠️ Unrecognized set type keyword after regex match: $keyword");
    return SetType.mainSet; // fallback
  }

  /// Parses a line to see if it's a section header (e.g., "Warm-up: 'easy'").
  static SectionHeaderParseResult? parse(String line) {
    final Match? match = _sectionTitleRegex.firstMatch(line.trim());
    if (match == null) return null;

    final String rawKeyword = match.group(1)!.trim();
    final String? notes = match.group(2)?.trim();

    final SetType setType = _mapKeywordToSetType(rawKeyword);

    return SectionHeaderParseResult(
      setType: setType,
      notes: notes,
      rawKeyword: rawKeyword,
    );
  }
}
