import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
  ///
  /// This function is designed to be robust against malformed input. It uses try-catch blocks
  /// to handle potential parsing errors gracefully. Non-fatal errors are logged to
  /// Firebase Crashlytics to help with debugging and monitoring.
  static TagExtractionResult extractTagsFromLine(
    String line,
    List<Swimmer> availableSwimmers,
    List<SwimGroup> availableGroups,
  ) {
    try {
      // Sort entities by name length to prioritize longer, more specific matches first.
      // This prevents "John" from matching before "John Doe".
      final sortedSwimmers = _sortByNameLength(availableSwimmers);
      final sortedGroups = _sortByNameLength(availableGroups);

      final foundTags = _findAllTags(line, sortedSwimmers, sortedGroups);

      // Remove tag text from the original line to get the remaining content.
      String remainingLine = _stripTagsFromLine(line, foundTags);

      // Collect unique IDs from all found tags, preserving the order of appearance.
      final swimmerIds = <String>{};
      final groupIds = <String>{};
      for (final tag in foundTags) {
        if (tag.tagType == 'swimmer') {
          swimmerIds.addAll(tag.resolvedIds);
        } else {
          groupIds.addAll(tag.resolvedIds);
        }
      }

      return TagExtractionResult(
        remainingLine: remainingLine,
        swimmerIds: swimmerIds.toList(),
        groupIds: groupIds.toList(),
      );
    } catch (e, s) {
      // This is a critical error handler. If any unexpected exception occurs during parsing,
      // we log it to Crashlytics for immediate investigation.
      // To prevent a crash, we return the original line with no tags extracted, ensuring the app remains stable.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'A critical error occurred in extractTagsFromLine',
      );
      return TagExtractionResult(
        remainingLine: line,
        swimmerIds: [],
        groupIds: [],
      );
    }
  }

  /// Sorts a list of Swimmers or SwimGroups by name length in descending order.
  static List<T> _sortByNameLength<T>(List<T> entities) {
    final sortedList = List<T>.from(entities);
    sortedList.sort((a, b) {
      final nameA = a is Swimmer ? a.name : (a as SwimGroup).name;
      final nameB = b is Swimmer ? b.name : (b as SwimGroup).name;
      return nameB.length.compareTo(nameA.length);
    });
    return sortedList;
  }

  /// Iterates through the line to find all valid #swimmer and #group tags.
  /// This function was refactored from the main loop in `extractTagsFromLine` to improve clarity.
  static List<_FoundTag> _findAllTags(
    String line,
    List<Swimmer> sortedSwimmers,
    List<SwimGroup> sortedGroups,
  ) {
    final foundTags = <_FoundTag>[];
    int offset = 0;

    while (offset < line.length) {
      final match = _tagPrefixRegex.firstMatch(line.substring(offset));
      if (match == null) break;

      // The use of `group(1)` is safe here because the regex `r"#\s*(swimmer|group)\b"` guarantees
      // that if a match is found, group(1) will contain either "swimmer" or "group".
      // A null-check is added for extra safety.
      final tagType = match.group(1)?.toLowerCase();
      if (tagType == null) {
        offset += match.end; // Skip invalid match
        continue;
      }

      final tagStart = offset + match.start;
      final contentStart = offset + match.end;

      final afterTag = line.substring(contentStart).trimLeft();
      final consumedWhitespace = line.length - afterTag.length - contentStart;

      final segmentEndIndex = _findEndOfTagRegion(afterTag);
      final tagContent = afterTag.substring(0, segmentEndIndex).trim();

      final entities = tagType == 'swimmer' ? sortedSwimmers : sortedGroups;
      final resolvedIds = _resolveCommaSeparatedNames(tagContent, entities);

      if (resolvedIds.isNotEmpty) {
        final tagEnd = contentStart + consumedWhitespace + segmentEndIndex;
        foundTags.add(
          _FoundTag(
            startIndex: tagStart,
            endIndex: tagEnd,
            tagType: tagType,
            resolvedIds: resolvedIds,
          ),
        );
      }
      offset = contentStart + segmentEndIndex;
    }
    return foundTags;
  }

  /// Removes all identified tag sections from the line.
  /// Refactored for better separation of concerns.
  static String _stripTagsFromLine(String line, List<_FoundTag> tags) {
    String remaining = line;
    // Tags are removed in reverse order to ensure start/end indices remain valid.
    for (final tag in tags.reversed) {
      remaining =
          remaining.substring(0, tag.startIndex) +
          remaining.substring(tag.endIndex);
    }
    // Normalize spacing by replacing multiple whitespace characters with a single space.
    return remaining.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Finds the end of a tag's content, which is terminated by another tag, a quote, or the end of the line.
  /// This logic was extracted into its own method for improved testability and clarity.
  static int _findEndOfTagRegion(String text) {
    final nextTagMatch = RegExp(
      r"#\s*(swimmer|group)",
      caseSensitive: false,
    ).firstMatch(text);
    final nextTag = nextTagMatch?.start ?? -1;
    final nextQuote = text.indexOf("'");

    if (nextTag == -1 && nextQuote == -1) return text.length;
    if (nextTag == -1) return nextQuote;
    if (nextQuote == -1) return nextTag;

    return nextTag < nextQuote ? nextTag : nextQuote;
  }

  /// Resolves a comma-separated string of names into a list of unique IDs.
  /// This function was an ideal candidate for refactoring as it performs a distinct, testable task.
  static List<String> _resolveCommaSeparatedNames(
    String content,
    List<dynamic> entities,
  ) {
    final ids = <String>[];
    final parts = content
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final name in parts) {
      final match = entities.cast<dynamic?>().firstWhere(
        (e) =>
            (e is Swimmer ? e.name : (e as SwimGroup).name)
                .toLowerCase()
                .trim() ==
            name.toLowerCase().trim(),
        orElse: () => null,
      );
      if (match is Swimmer)
        ids.add(match.id);
      else if (match is SwimGroup)
        ids.add(match.id!);
    }
    return ids;
  }
}
