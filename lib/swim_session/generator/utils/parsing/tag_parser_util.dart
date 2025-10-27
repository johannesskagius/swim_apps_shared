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

  /// 🆕 A list of human-readable group names from #group tags (including AI-generated ones).
  final List<String> groupNames;

  TagExtractionResult({
    required this.remainingLine,
    required this.swimmerIds,
    required this.groupIds,
    required this.groupNames,
  });
}

/// Internal helper for tracking tag positions and content.
class _FoundTag {
  final int startIndex;
  final int endIndex;
  final String tagType; // 'swimmer' or 'group'
  final List<String> resolvedIds;
  final List<String> resolvedNames;

  _FoundTag({
    required this.startIndex,
    required this.endIndex,
    required this.tagType,
    required this.resolvedIds,
    required this.resolvedNames,
  });
}

/// Utility for extracting #swimmer and #group tags from a workout text line.
class TagExtractUtil {
  // Detect tag prefix — supports both "#group" and "#swimmer" with flexible spacing.
  static final RegExp _tagPrefixRegex = RegExp(
    r"#\s*(swimmer|group)\b",
    caseSensitive: false,
  );

  /// Extracts #swimmer and #group tags and resolves them to IDs and names.
  ///
  /// This version handles both known and unknown (AI-generated) groups gracefully.
  static TagExtractionResult extractTagsFromLine(
      String line,
      List<Swimmer> availableSwimmers,
      List<SwimGroup> availableGroups,
      ) {
    try {
      final sortedSwimmers = _sortByNameLength(availableSwimmers);
      final sortedGroups = _sortByNameLength(availableGroups);

      final foundTags = _findAllTags(line, sortedSwimmers, sortedGroups);

      String remainingLine = _stripTagsFromLine(line, foundTags);

      final swimmerIds = <String>{};
      final groupIds = <String>{};
      final groupNames = <String>{};

      for (final tag in foundTags) {
        if (tag.tagType == 'swimmer') {
          swimmerIds.addAll(tag.resolvedIds);
        } else {
          groupIds.addAll(tag.resolvedIds);
          groupNames.addAll(tag.resolvedNames);
        }
      }

      return TagExtractionResult(
        remainingLine: remainingLine,
        swimmerIds: swimmerIds.toList(),
        groupIds: groupIds.toList(),
        groupNames: groupNames.toList(),
      );
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'A critical error occurred in extractTagsFromLine',
      );
      return TagExtractionResult(
        remainingLine: line,
        swimmerIds: [],
        groupIds: [],
        groupNames: [],
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

      final tagType = match.group(1)?.toLowerCase();
      if (tagType == null) {
        offset += match.end;
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
      final resolvedNames = _resolveCommaSeparatedNamesOrFallback(
        tagContent,
        entities,
        tagType,
      );

      if (resolvedIds.isNotEmpty || resolvedNames.isNotEmpty) {
        final tagEnd = contentStart + consumedWhitespace + segmentEndIndex;
        foundTags.add(
          _FoundTag(
            startIndex: tagStart,
            endIndex: tagEnd,
            tagType: tagType,
            resolvedIds: resolvedIds,
            resolvedNames: resolvedNames,
          ),
        );
      }
      offset = contentStart + segmentEndIndex;
    }
    return foundTags;
  }

  /// Removes all identified tag sections from the line.
  static String _stripTagsFromLine(String line, List<_FoundTag> tags) {
    String remaining = line;
    for (final tag in tags.reversed) {
      remaining =
          remaining.substring(0, tag.startIndex) +
              remaining.substring(tag.endIndex);
    }
    return remaining.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Finds the end of a tag's content.
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

  /// Resolves known entity names (Swimmer/Group) to IDs only.
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

  /// 🆕 Resolves group/swimmer names but keeps unknown names as plain text.
  static List<String> _resolveCommaSeparatedNamesOrFallback(
      String content,
      List<dynamic> entities,
      String tagType,
      ) {
    final names = <String>[];
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

      if (match != null) {
        names.add(name); // known entity name
      } else if (tagType == 'group') {
        // Keep AI-generated or unknown group names (e.g., #group Middle)
        names.add(name);
      }
    }
    return names;
  }
}