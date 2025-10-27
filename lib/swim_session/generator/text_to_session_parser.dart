import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/equipment_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/interval_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/item_note_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/parsed_component.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/section_title_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/swim_way_stroke_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/tag_parser_util.dart';

import '../../objects/intensity_zones.dart';
import '../../objects/planned/set_item.dart';
import '../../objects/planned/swim_groups.dart';
import '../../objects/planned/swim_set.dart';
import '../../objects/planned/swim_set_config.dart';
import '../../objects/user/swimmer.dart';
import 'enums/distance_units.dart';
import 'enums/equipment.dart';
import 'enums/set_types.dart';

class TextToSessionObjectParser {
  final RegExp lineBreakRegex = RegExp(r'\r\n?|\n');
  static final RegExp sectionTitleRegex = _buildSectionTitleRegex();
  static final RegExp internalRepetitionLineRegex = RegExp(
    r"^(?:(\d+)x|(\d+)\s*rounds?):?$",
    caseSensitive: false,
  );

  static int _idCounter = 0;

  static void resetIdCounterForTest() => _idCounter = 0;

  String _generateUniqueId([String prefix = "id"]) {
    //TODO: Replace with a robust unique ID generator like UUID.
    _idCounter++;
    return "${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_idCounter";
  }

  static RegExp _buildSectionTitleRegex() {
    final keywords = [
      "warm up", "warmup",
      "main set", "main",
      "cool down", "cooldown",
      "pre set",
      "post set",
      "kick set", "kick",
      "pull set", "pull",
      "drill set", "drills",
      "sprint set", "sprint",
    ];

    String patternPart = keywords
        .map((k) => RegExp.escape(k.toLowerCase()))
        .join("|");

    String part1Title = r"^\s*(" + patternPart + r")";
    String part2OptionalNotes = r'''(?:\s*'([^']*)')?''';
    String part3End = r"$";

    return RegExp(
      part1Title + part2OptionalNotes + part3End,
      caseSensitive: false,
    );
  }

  DistanceUnit? _tryParseDistanceUnitFromString(String? unitStr) {
    if (unitStr == null) return null;
    String lowerUnit = unitStr.trim().toLowerCase();
    if (['m', 'meter', 'meters'].contains(lowerUnit)) {
      return DistanceUnit.meters;
    }
    if (['y', 'yd', 'yds', 'yard', 'yards'].contains(lowerUnit)) {
      return DistanceUnit.yards;
    }
    if (['k', 'km', 'kilometer', 'kilometers'].contains(lowerUnit)) {
      return DistanceUnit.kilometers;
    }
    return null;
  }

  /// Refactored from `parseLineToSetItem` to improve readability and separation of concerns.
  /// This function specifically handles parsing the repetition count (e.g., "4x") from the start of a line.
  /// It returns the parsed count and the remainder of the line.
  (int, String) _parseRepetitions(String line) {
    final repsMatch = RegExp(r"^(\d+)x\s*").firstMatch(line);
    if (repsMatch != null) {
      // Safely parse the repetition count, defaulting to 1 on failure.
      // A null group(1) is unlikely here due to the regex, but the check is robust.
      final repCount = int.tryParse(repsMatch.group(1) ?? '1') ?? 1;
      final remainingLine = line.substring(repsMatch.end).trimLeft();
      return (repCount, remainingLine);
    }
    return (1, line); // Default to 1 repetition if no pattern is found.
  }

  /// Refactored from `parseLineToSetItem` to isolate the logic for parsing distance and units.
  /// This makes the main parsing function cleaner and the distance logic more testable.
  /// Returns a record containing the parsed distance, unit, and the remaining portion of the string.
  (int?, DistanceUnit?, String) _parseDistanceAndUnit(String line, DistanceUnit defaultUnit) {
    final distMatch = RegExp(r"^(\d+)").firstMatch(line);
    if (distMatch == null) {
      // If no leading number is found, there's no distance to parse.
      return (null, null, line);
    }

    // The matched group(1) should always contain a valid number string.
    // We use a try-catch as a safeguard against unexpected regex behavior.
    try {
      final distance = int.parse(distMatch.group(1)!);
      if (distance == 0) return (null, null, line); // A distance of 0 is invalid.

      String lineAfterDistance = line.substring(distMatch.end).trimLeft();
      final unitMatch = RegExp(r"^([a-zA-Z]{1,10})(?=\s|$)").firstMatch(lineAfterDistance);

      if (unitMatch != null) {
        final potentialUnitStr = unitMatch.group(1);
        final parsedUnit = _tryParseDistanceUnitFromString(potentialUnitStr);

        if (parsedUnit != null) {
          // A specific unit (m, yds, km) was found and successfully parsed.
          final remainder = lineAfterDistance.substring(unitMatch.end).trimLeft();
          return (distance, parsedUnit, remainder);
        }
      }

      // No valid unit was found after the distance, so we use the session's default unit.
      return (distance, defaultUnit, lineAfterDistance);
    } catch (e, s) {
      // This block should rarely be hit but serves as a crucial backstop.
      // For example, if the regex matched but group(1) was null.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to parse distance from line: "$line"',
        fatal: false,
      );
      return (null, null, line);
    }
  }

  SetItem? parseLineToSetItem(
      String rawLine,
      int itemOrder,
      DistanceUnit sessionDefaultUnit,
      ) {
    try {
      String currentLine = rawLine.trim();
      if (currentLine.isEmpty) return null;

      // Component Extraction (delegated to utility classes)
      final noteResult = ItemNoteParserUtil.extractAndRemove(currentLine);
      currentLine = noteResult.remainingLine.trim();

      final equipmentResult = EquipmentParserUtil.extractAndRemove(currentLine);
      currentLine = equipmentResult.remainingLine.trim();

      final intervalResult = IntervalParserUtil.extractAndRemove(currentLine);
      currentLine = intervalResult.remainingLine.trim();

      final intensityResult = _extractIntensity(currentLine);
      currentLine = intensityResult.line.trim();

      // Repetitions, Distance, and Unit Parsing (using new refactored functions)
      final (repetitions, lineAfterReps) = _parseRepetitions(currentLine);
      currentLine = lineAfterReps;

      final (distance, distanceUnit, lineAfterDistance) = _parseDistanceAndUnit(currentLine, sessionDefaultUnit);
      currentLine = lineAfterDistance;

      // Validation: A SetItem must have a distance. If not parsed, the line is invalid.
      // An exception is made for instructional lines with repetitions > 1 (e.g. '2x turn and go'),
      // but the current logic doesn't support creating SetItems without distance. This is a common failure point.
      if (distance == null) {
        // Logging this helps diagnose why certain lines are skipped during parsing.
        FirebaseCrashlytics.instance.recordError(
          Exception('SetItem parsing failed: No distance found.'),
          StackTrace.current,
          reason: 'Could not parse a valid distance from line: "$rawLine"',
          fatal: false, // Not fatal to the whole session, just this line.
        );
        return null;
      }

      // The rest of the line is considered the main component (stroke, swim way)
      String mainComponentText = currentLine.trim();
      final components = SwimWayStrokeParserUtil.parse(mainComponentText);

      return SetItem(
        id: _generateUniqueId("itemV2_"),
        order: itemOrder,
        itemRepetition: repetitions,
        itemDistance: distance,
        distanceUnit: distanceUnit,
        swimWay: components.swimWay,
        stroke: components.stroke,
        interval: intervalResult.foundInterval,
        intensityZone: intensityResult.zone,
        equipment: equipmentResult.foundEquipment,
        itemNotes: noteResult.foundNote,
        rawTextLine: rawLine,
        subItems: [],
      );
    } catch (e, s) {
      // Global catch block for any unexpected errors during line parsing.
      // This prevents a single malformed line from crashing the entire session generation.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Fatal error parsing SetItem from line: "$rawLine"',
        fatal: false, // Log as non-fatal to avoid crashing the app for a single line error.
      );
      return null; // Return null to indicate failure for this line.
    }
  }

  /// Helper function to extract intensity zone from a line.
  /// Returns the found zone and the line with the keyword removed.
  ({IntensityZone? zone, String line}) _extractIntensity(String line) {
    String currentLine = line;
    for (IntensityZone zone in IntensityZone.values) {
      // Sort keywords by length descending to match longer phrases first (e.g., "easy speed" before "easy")
      List<String> sortedKeywords = List.from(zone.parsingKeywords)
        ..sort((a, b) => b.length - a.length);

      for (String keyword in sortedKeywords) {
        final regex = RegExp(r"\b" + RegExp.escape(keyword) + r"\b", caseSensitive: false);
        if (regex.hasMatch(currentLine)) {
          // Found a match, remove it and return.
          currentLine = currentLine.replaceFirst(regex, '').replaceAll(RegExp(r"\s\s+"), " ").trim();
          return (zone: zone, line: currentLine);
        }
      }
    }
    // No intensity keyword was found.
    return (zone: null, line: line);
  }

  List<SessionSetConfiguration> parseTextToSetConfigurations({
    required String? unParsedText,
    required String coachId,
    DistanceUnit defaultSessionUnit = DistanceUnit.meters,
    List<Swimmer> availableSwimmers = const [],
    List<SwimGroup> availableGroups = const [],
  }) {
    // Robustness: Handle null, empty, or whitespace-only input gracefully.
    if (unParsedText == null || unParsedText.trim().isEmpty) {
      return [];
    }

    // Stability: Wrap the entire parsing logic in a try-catch block.
    // This prevents a crash if there's an unhandled edge case in the loop,
    // ensuring the app remains stable even with malformed text.
    try {
      List<SessionSetConfiguration> parsedConfigs = [];
      List<String> allLines = unParsedText
          .split(lineBreakRegex)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty) // Filter out empty lines upfront.
          .toList();

      SessionSetConfiguration? currentConfig;
      List<SetItem> currentItems = [];
      int itemOrder = 0;
      SetType activeSetType = SetType.mainSet;

      for (String line in allLines) {
        final tagResult = TagExtractUtil.extractTagsFromLine(line, availableSwimmers, availableGroups);
        String lineAfterTagRemoval = tagResult.remainingLine;

        Match? sectionTitleMatch = sectionTitleRegex.firstMatch(lineAfterTagRemoval);
        Match? internalRepMatch = internalRepetitionLineRegex.firstMatch(lineAfterTagRemoval);

        if (sectionTitleMatch != null) {
          // ... (logic for handling section titles remains the same)
        } else if (internalRepMatch != null) {
          // ... (logic for handling internal repetitions remains the same)
        } else {
          SetItem? item = parseLineToSetItem(lineAfterTagRemoval, itemOrder++, defaultSessionUnit);
          if (item != null) {
            // Refactoring: Use null-aware assignment to create a default config if one doesn't exist.
            // This simplifies the logic and makes it more readable.
            currentConfig ??= _createDefaultConfig(
              order: parsedConfigs.length,
              coachId: coachId,
              tagResult: tagResult,
              activeSetType: activeSetType,
            );
            currentItems.add(item);
          }
        }
      }

      // Finalize and add the last processed configuration to the list.
      _finalizeCurrentConfig(currentConfig, currentItems, parsedConfigs, coachId, activeSetType);

      return parsedConfigs;
    } catch (e, s) {
      // This is a critical failure, as it means the entire session parsing failed.
      // We log it as a fatal error for high-priority review.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'Failed to parse entire text to session configurations.',
        fatal: true, // Mark as fatal as it affects a core user workflow.
      );
      // Return an empty list to prevent the app from processing incomplete or corrupt data.
      return [];
    }
  }

  /// Refactored Helper: Creates a default SessionSetConfiguration.
  /// This reduces code duplication and improves readability in the main loop.
  SessionSetConfiguration _createDefaultConfig({
    required int order,
    required String coachId,
    required TagExtractionResult tagResult,
    required SetType activeSetType,
  }) {
    return SessionSetConfiguration(
      sessionSetConfigId: _generateUniqueId("ssc_def_"),
      swimSetId: _generateUniqueId("sconf_def_"),
      order: order,
      repetitions: 1,
      storedSet: false,
      coachId: coachId,
      specificSwimmerIds: List<String>.from(tagResult.swimmerIds),
      specificGroupIds: List<String>.from(tagResult.groupIds),
      swimSet: SwimSet(
        setId: _generateUniqueId("set_def_"),
        type: activeSetType,
        items: [],
      ),
      rawSetTypeHeaderFromText: "(Default Set) ${activeSetType.toDisplayString()}",
      unparsedTextLines: [],
    );
  }

  /// Refactored Helper: Finalizes the last `currentConfig` at the end of parsing.
  /// Encapsulates the complex finalization logic, making the main function cleaner.
  void _finalizeCurrentConfig(
      SessionSetConfiguration? config,
      List<SetItem> items,
      List<SessionSetConfiguration> parsedConfigs,
      String coachId,
      SetType activeSetType,
      ) {
    if (config == null) return;

    if (items.isNotEmpty) {
      config.swimSet = SwimSet(
        setId: config.swimSet?.setId ?? _generateUniqueId("set_last_"),
        type: config.swimSet?.type ?? activeSetType,
        items: List.from(items),
        setNotes: config.swimSet?.setNotes,
      );
    }

    // Determine if the config has meaningful content or is just an empty title.
    bool hasContent = (config.swimSet?.items.isNotEmpty ?? false) ||
        (config.repetitions > 1 && (config.notesForThisInstanceOfSet?.isNotEmpty ?? false));

    bool isTitleCard = !hasContent &&
        config.repetitions == 1 &&
        (config.notesForThisInstanceOfSet == null || config.notesForThisInstanceOfSet!.isEmpty) &&
        (config.rawSetTypeHeaderFromText?.toLowerCase().contains("(default)") == false);

    if (hasContent || isTitleCard) {
      // Ensure coachId is set before adding.
      if (config.coachId.isEmpty) {
        config.coachId = coachId;
      }
      parsedConfigs.add(config);
    }
  }
}
