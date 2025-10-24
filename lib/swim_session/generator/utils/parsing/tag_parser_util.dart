// lib/swim/text_parser/tag_parser_util.dart

import 'package:swim_apps_shared/swim_apps_shared.dart';

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

/// A private helper class to store information about a found tag's position and content.
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

/// A utility class for parsing #swimmer and #group tags from a string.
class TagExtractUtil {
  // A simple, non-greedy regex to find only the START of a potential tag.
  static final RegExp _tagPrefixRegex = RegExp(
    r"#\s*(swimmer|group)\s*",
    caseSensitive: false,
  );

  /// Extracts #swimmer and #group tags from a line of text.
  ///
  /// This function uses an imperative parsing strategy that ONLY removes
  /// tags that can be resolved to a known swimmer or group.
  static TagExtractionResult extractTagsFromLine(
    String line,
    List<Swimmer> availableSwimmers,
    List<SwimGroup> availableGroups,
  ) {
    // --- Step 1: Pre-process and sort the available names ---
    final sortedSwimmers = List<Swimmer>.from(availableSwimmers)
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    final sortedGroups = List<SwimGroup>.from(availableGroups)
      ..sort((a, b) => b.name.length.compareTo(a.name.length));

    final foundTags = <_FoundTag>[];
    int searchOffset = 0;

    // --- Step 2: Iteratively find and process all potential tags ---
    while (searchOffset < line.length) {
      final Match? prefixMatch = _tagPrefixRegex.firstMatch(
        line.substring(searchOffset),
      );

      if (prefixMatch == null) break;

      final tagType = prefixMatch.group(1)!.toLowerCase();
      final tagStartIndex = searchOffset + prefixMatch.start;
      int currentContentOffset = searchOffset + prefixMatch.end;
      int endOfLastSuccessfulParse = currentContentOffset;

      final entitiesToSearch = tagType == 'swimmer'
          ? sortedSwimmers
          : sortedGroups;
      final currentTagResolvedIds = <String>[];
      bool moreNamesInList = true;
      bool aNameWasFound = false;

      // --- Step 3: Process comma-separated lists of KNOWN names ---
      while (moreNamesInList) {
        final contentToSearchFrom = line
            .substring(currentContentOffset)
            .trimLeft();
        final trimLength =
            line.substring(currentContentOffset).length -
            contentToSearchFrom.length;
        currentContentOffset += trimLength;

        if (contentToSearchFrom.isEmpty) break;

        // Handle empty name segments (e.g., ,,) by consuming the comma and continuing.
        if (contentToSearchFrom.startsWith(',')) {
          currentContentOffset += 1;
          endOfLastSuccessfulParse = currentContentOffset;
          aNameWasFound =
              true; // Mark that we've processed a valid part of the tag.
          continue;
        }

        String? bestMatchId;
        int consumedNameLength = 0;

        // Find the longest matching KNOWN name at the current position.
        for (final entity in entitiesToSearch) {
          final String name = (entity is Swimmer)
              ? entity.name
              : (entity as SwimGroup).name;

          if (contentToSearchFrom.toLowerCase().startsWith(
            name.toLowerCase(),
          )) {
            bestMatchId = (entity is Swimmer)
                ? entity.id
                : (entity as SwimGroup).id;
            consumedNameLength = name.length;
            break; // First match is longest, thanks to sorting.
          }
        }

        if (bestMatchId != null) {
          aNameWasFound = true;

          currentTagResolvedIds.add(bestMatchId);
          currentContentOffset += consumedNameLength;
          endOfLastSuccessfulParse = currentContentOffset;

          final remainingAfterName = line
              .substring(currentContentOffset)
              .trimLeft();
          if (remainingAfterName.startsWith(',')) {
            final commaTrimLength =
                line.substring(currentContentOffset).length -
                remainingAfterName.length;
            currentContentOffset +=
                commaTrimLength + 1; // Consume whitespace and comma
            endOfLastSuccessfulParse = currentContentOffset;
          } else {
            moreNamesInList = false;
          }
        } else {
          // If no known name is found, the tag block ends here.
          moreNamesInList = false;
        }
      }

      if (aNameWasFound) {
        foundTags.add(
          _FoundTag(
            startIndex: tagStartIndex,
            endIndex: endOfLastSuccessfulParse,
            tagType: tagType,
            resolvedIds: currentTagResolvedIds,
          ),
        );
        searchOffset = endOfLastSuccessfulParse;
      } else {
        // A prefix was found but no known name followed.
        // Advance the parser past the prefix to continue searching.
        searchOffset = tagStartIndex + prefixMatch.group(0)!.length;
      }
    }

    // --- Step 4: Reconstruct the remaining line and collect all IDs ---
    String remainingLine = line;
    final finalSwimmerIds = <String>[];
    final finalGroupIds = <String>[];

    for (final tag in foundTags.reversed) {
      remainingLine =
          remainingLine.substring(0, tag.startIndex) +
          remainingLine.substring(tag.endIndex);
    }

    for (final tag in foundTags) {
      if (tag.tagType == 'swimmer') {
        finalSwimmerIds.addAll(tag.resolvedIds);
      } else {
        finalGroupIds.addAll(tag.resolvedIds);
      }
    }

    // --- THIS IS THE FIX ---
    // The regex is now correctly `r'\s+'` to match one or more whitespace characters.
    // The previous version `r'\\s+'` was incorrect and did not collapse spaces.
    final finalLine = remainingLine.replaceAll(RegExp(r'\s+'), ' ').trim();

    return TagExtractionResult(
      remainingLine: finalLine,
      swimmerIds: finalSwimmerIds,
      groupIds: finalGroupIds,
    );
  }
}
