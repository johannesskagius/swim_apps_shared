import '../../../../objects/planned/swim_groups.dart';
import '../../../../objects/user/swimmer.dart';

/// Holds the result of extracting tags from a line of text.
class TagExtractionResult {
  /// The part of the original line that remains after all tags have been removed.
  final String remainingLine;

  /// A list of unique IDs for all swimmers identified by #swimmer tags, in order of appearance.
  final List<String> swimmerIds;

  /// A list of unique IDs for all groups identified by #group tags, in order of appearance.
  final List<String> groupIds;

  TagExtractionResult({
    required this.remainingLine,
    required this.swimmerIds,
    required this.groupIds,
  });
}

/// Internal helper for tracking tag positions and content.
class _FoundTag {
  final int startIndex;
  final int endIndex;
  final String tagType; // 'swimmer' or 'group'
  final List<String> resolvedIds;

  _FoundTag({
    required this.startIndex,
    required this.endIndex,
    required this.tagType,
    required this.resolvedIds,
  });
}

/// Utility for extracting #swimmer and #group tags from a workout text line.
class TagExtractUtil {
  // Detect tag prefix — supports both "#group" and "#swimmer" with flexible spacing.
  static final RegExp _tagPrefixRegex = RegExp(
    r"#\s*(swimmer|group)\b",
    caseSensitive: false,
  );

  /// Extracts #swimmer and #group tags and resolves them to IDs.
  static TagExtractionResult extractTagsFromLine(
      String line,
      List<Swimmer> availableSwimmers,
      List<SwimGroup> availableGroups,
      ) {
    // Sort swimmers and groups by descending name length to prioritize longer matches first.
    final sortedSwimmers = List<Swimmer>.from(availableSwimmers)
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    final sortedGroups = List<SwimGroup>.from(availableGroups)
      ..sort((a, b) => b.name.length.compareTo(a.name.length));

    final foundTags = <_FoundTag>[];
    int offset = 0;

    // Search the line for #swimmer / #group prefixes
    while (offset < line.length) {
      final match = _tagPrefixRegex.firstMatch(line.substring(offset));
      if (match == null) break;

      final tagType = match.group(1)!.toLowerCase();
      final tagStart = offset + match.start;
      int contentStart = offset + match.end;

      // Extract content after the tag prefix
      String afterTag = line.substring(contentStart).trimLeft();
      int consumed = line.length - afterTag.length - contentStart;

      // Extract until a quote, #, or end of line — this is the name list region
      final segmentEndIndex = _findEndOfTagRegion(afterTag);
      final tagContent = afterTag.substring(0, segmentEndIndex).trim();

      final entities = tagType == 'swimmer' ? sortedSwimmers : sortedGroups;
      final resolvedIds = _resolveCommaSeparatedNames(tagContent, entities);

      if (resolvedIds.isNotEmpty) {
        final tagEnd = contentStart + segmentEndIndex + consumed;
        foundTags.add(
          _FoundTag(
            startIndex: tagStart,
            endIndex: tagEnd,
            tagType: tagType,
            resolvedIds: resolvedIds,
          ),
        );
      }

      // Advance parser after this tag content
      offset = contentStart + segmentEndIndex + 1;
    }

    // Remove all found tags from text (reverse order to avoid offset drift)
    String remaining = line;
    for (final tag in foundTags.reversed) {
      remaining =
          remaining.substring(0, tag.startIndex) + remaining.substring(tag.endIndex);
    }

    // Collect IDs without duplicates, preserving order
    final swimmerIds = <String>{};
    final groupIds = <String>{};
    for (final tag in foundTags) {
      if (tag.tagType == 'swimmer') {
        swimmerIds.addAll(tag.resolvedIds);
      } else {
        groupIds.addAll(tag.resolvedIds);
      }
    }

    // Normalize spacing
    final cleaned = remaining.replaceAll(RegExp(r'\s+'), ' ').trim();

    return TagExtractionResult(
      remainingLine: cleaned,
      swimmerIds: swimmerIds.toList(),
      groupIds: groupIds.toList(),
    );
  }

  /// Find where the current tag region likely ends (before next tag, quote, or EOL)
  static int _findEndOfTagRegion(String text) {
    final nextTag = text.indexOf(RegExp(r"(#\s*(swimmer|group))", caseSensitive: false));
    final nextQuote = text.indexOf("'");
    if (nextTag == -1 && nextQuote == -1) return text.length;
    if (nextTag == -1) return nextQuote;
    if (nextQuote == -1) return nextTag;
    return nextTag < nextQuote ? nextTag : nextQuote;
  }

  /// Resolves comma-separated names (case-insensitive, whitespace-tolerant)
  static List<String> _resolveCommaSeparatedNames(
      String content,
      List<dynamic> entities,
      ) {
    final ids = <String>[];
    final parts = content.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final name in parts) {
      final match = entities.firstWhere(
            (e) => (e is Swimmer ? e.name : (e as SwimGroup).name)
            .toLowerCase()
            .trim() ==
            name.toLowerCase().trim(),
        orElse: () => null,
      );
      if (match != null) {
        ids.add(match! is Swimmer ? match.id : (match as SwimGroup).id);
      }
    }
    return ids;
  }
}
