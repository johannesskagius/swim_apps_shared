import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/equipment_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/interval_parser_util.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/item_note_parser_util.dart';
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
    _idCounter++;
    return "${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_idCounter";
  }

  /// ✅ Final version — compatible with SectionTitleUtil and supports tags/comments
  static RegExp _buildSectionTitleRegex() {
    final keywords = [
      "warm up", "warmup",
      "main set", "main",
      "cool down", "cooldown",
      "pre set", "post set",
      "kick set", "kick",
      "pull set", "pull",
      "drill set", "drills",
      "sprint set", "sprint",
      "recovery", "technique set"
    ];
    final patternPart = keywords.map(RegExp.escape).join("|");

    // ✅ Capture group (1) = section title
    // ✅ Capture group (2) = optional quoted note (e.g., 'activation focus')
    // ✅ Works even if line contains tags (#group, #swimmer)
    return RegExp(
      r"^\s*(" + patternPart + r")\b(?:[^']*'([^']*)')?.*$",
      caseSensitive: false,
    );
  }

  DistanceUnit? _tryParseDistanceUnitFromString(String? unitStr) {
    if (unitStr == null) return null;
    final lowerUnit = unitStr.trim().toLowerCase();
    if (['m', 'meter', 'meters'].contains(lowerUnit)) return DistanceUnit.meters;
    if (['y', 'yd', 'yds', 'yard', 'yards'].contains(lowerUnit)) return DistanceUnit.yards;
    if (['k', 'km', 'kilometer', 'kilometers'].contains(lowerUnit)) return DistanceUnit.kilometers;
    return null;
  }

  (int, String) _parseRepetitions(String line) {
    final repsMatch = RegExp(r"^(\d+)x\s*").firstMatch(line);
    if (repsMatch != null) {
      final repCount = int.tryParse(repsMatch.group(1) ?? '1') ?? 1;
      final remainingLine = line.substring(repsMatch.end).trimLeft();
      return (repCount, remainingLine);
    }
    return (1, line);
  }

  (int?, DistanceUnit?, String) _parseDistanceAndUnit(String line, DistanceUnit defaultUnit) {
    final distMatch = RegExp(r"^(\d+)").firstMatch(line);
    if (distMatch == null) return (null, null, line);

    try {
      final distance = int.parse(distMatch.group(1)!);
      if (distance == 0) return (null, null, line);

      String lineAfterDistance = line.substring(distMatch.end).trimLeft();
      final unitMatch = RegExp(r"^([a-zA-Z]{1,10})(?=\s|$)").firstMatch(lineAfterDistance);

      if (unitMatch != null) {
        final parsedUnit = _tryParseDistanceUnitFromString(unitMatch.group(1));
        if (parsedUnit != null) {
          final remainder = lineAfterDistance.substring(unitMatch.end).trimLeft();
          return (distance, parsedUnit, remainder);
        }
      }
      return (distance, defaultUnit, lineAfterDistance);
    } catch (e, s) {
      _safeRecordCrashlytics(e, s, 'Failed to parse distance from line: "$line"');
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

      final noteResult = ItemNoteParserUtil.extractAndRemove(currentLine);
      currentLine = noteResult.remainingLine.trim();

      final equipmentResult = EquipmentParserUtil.extractAndRemove(currentLine);
      currentLine = equipmentResult.remainingLine.trim();

      final intervalResult = IntervalParserUtil.extractAndRemove(currentLine);
      currentLine = intervalResult.remainingLine.trim();

      final intensityResult = _extractIntensity(currentLine);
      currentLine = intensityResult.line.trim();

      final (repetitions, lineAfterReps) = _parseRepetitions(currentLine);
      currentLine = lineAfterReps;

      final (distance, distanceUnit, lineAfterDistance) =
      _parseDistanceAndUnit(currentLine, sessionDefaultUnit);
      currentLine = lineAfterDistance;

      if (distance == null) {
        _safeRecordCrashlytics(
          Exception('SetItem parsing failed: No distance found.'),
          StackTrace.current,
          'Could not parse a valid distance from line: "$rawLine"',
        );
        return null;
      }

      final components = SwimWayStrokeParserUtil.parse(currentLine.trim());

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
      _safeRecordCrashlytics(e, s, 'Fatal error parsing SetItem from line: "$rawLine"');
      return null;
    }
  }

  ({IntensityZone? zone, String line}) _extractIntensity(String line) {
    String currentLine = line;
    for (final zone in IntensityZone.values) {
      final sorted = [...zone.parsingKeywords]..sort((a, b) => b.length - a.length);
      for (final keyword in sorted) {
        final regex = RegExp(r"\b" + RegExp.escape(keyword) + r"\b", caseSensitive: false);
        if (regex.hasMatch(currentLine)) {
          currentLine = currentLine
              .replaceFirst(regex, '')
              .replaceAll(RegExp(r"\s\s+"), " ")
              .trim();
          return (zone: zone, line: currentLine);
        }
      }
    }
    return (zone: null, line: line);
  }

  // 🔹 NEW — extracts #group names even if not existing in Firestore
  List<String> _extractGroupNames(String text) {
    final matches = RegExp(r'#group\s+([\w\s\-]+)', caseSensitive: false)
        .allMatches(text);
    return matches.map((m) => m.group(1)!.trim()).toList();
  }

  List<SessionSetConfiguration> parseTextToSetConfigurations({
    required String? unParsedText,
    required String coachId,
    DistanceUnit defaultSessionUnit = DistanceUnit.meters,
    List<Swimmer> availableSwimmers = const [],
    List<SwimGroup> availableGroups = const [],
  }) {
    if (unParsedText == null || unParsedText.trim().isEmpty) return [];

    try {
      final parsedConfigs = <SessionSetConfiguration>[];
      final allLines = unParsedText
          .split(lineBreakRegex)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      SessionSetConfiguration? currentConfig;
      final currentItems = <SetItem>[];
      int itemOrder = 0;
      var activeSetType = SetType.mainSet;

      for (final line in allLines) {
        final tagResult =
        TagExtractUtil.extractTagsFromLine(line, availableSwimmers, availableGroups);
        final lineAfterTagRemoval = tagResult.remainingLine;

        final sectionTitleMatch = sectionTitleRegex.firstMatch(lineAfterTagRemoval);
        final internalRepMatch = internalRepetitionLineRegex.firstMatch(lineAfterTagRemoval);

        if (sectionTitleMatch != null) {
          final result = SectionTitleUtil.handleSectionTitleLine(
            originalLineText: line,
            sectionTitleMatch: sectionTitleMatch,
            tagResult: tagResult,
            previousCurrentConfig: currentConfig,
            previousCurrentItems: currentItems,
            parsedConfigsList: parsedConfigs,
            coachId: coachId,
            activeSetTypeBeforeThisLine: activeSetType,
            newConfigOrder: parsedConfigs.length,
            setId: _generateUniqueId("set_"),
            swimSetId: _generateUniqueId("swimSet_"),
          );

          currentConfig = result.newConfig;
          activeSetType = result.newActiveSetType;
          currentItems.clear();
          continue;
        } else if (internalRepMatch != null) {
          continue;
        }

        final item = parseLineToSetItem(lineAfterTagRemoval, itemOrder++, defaultSessionUnit);
        if (item != null) {
          currentConfig ??= _createDefaultConfig(
            order: parsedConfigs.length,
            coachId: coachId,
            tagResult: tagResult,
            activeSetType: activeSetType,
          );
          currentItems.add(item);
        }
      }

      _finalizeCurrentConfig(currentConfig, currentItems, parsedConfigs, coachId, activeSetType);
      return parsedConfigs;
    } catch (e, s) {
      _safeRecordCrashlytics(e, s, 'Failed to parse entire text to session configurations.', fatal: true);
      return [];
    }
  }

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
        assignedGroupNames: tagResult.groupNames, // 🆕 link group names early if found
      ),
      rawSetTypeHeaderFromText: "(Default Set) ${activeSetType.toDisplayString()}",
      unparsedTextLines: [],
    );
  }

  void _finalizeCurrentConfig(
      SessionSetConfiguration? config,
      List<SetItem> items,
      List<SessionSetConfiguration> parsedConfigs,
      String coachId,
      SetType activeSetType,
      ) {
    if (config == null) return;

    if (items.isNotEmpty) {
      // 🔹 Detect any #group mentions within this set's text
      final rawText = config.unparsedTextLines?.join(" ") ?? "";
      final extractedGroupNames = _extractGroupNames(rawText);

      config.swimSet = SwimSet(
        setId: config.swimSet?.setId ?? _generateUniqueId("set_last_"),
        type: config.swimSet?.type ?? activeSetType,
        items: List.from(items),
        setNotes: config.swimSet?.setNotes,
        assignedGroupNames: (config.swimSet?.assignedGroupNames ?? []) +
            extractedGroupNames, // merge both parsed and text-found names
      );
    }

    final hasContent = (config.swimSet?.items.isNotEmpty ?? false) ||
        (config.repetitions > 1 && (config.notesForThisInstanceOfSet?.isNotEmpty ?? false));

    final isTitleCard = !hasContent &&
        config.repetitions == 1 &&
        (config.notesForThisInstanceOfSet == null ||
            config.notesForThisInstanceOfSet!.isEmpty) &&
        (config.rawSetTypeHeaderFromText?.toLowerCase().contains("(default)") == false);

    if (hasContent || isTitleCard) {
      if (config.coachId.isEmpty) config.coachId = coachId;
      parsedConfigs.add(config);
    }
  }

  /// Safe wrapper for Crashlytics (avoids web assertion failures)
  void _safeRecordCrashlytics(Object e, StackTrace s, String reason, {bool fatal = false}) {
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, s, reason: reason, fatal: fatal);
      } else {
        debugPrint("⚠️ Crashlytics disabled on web — $reason ($e)");
      }
    } catch (_) {
      debugPrint("⚠️ Crashlytics unavailable — skipping error report ($reason)");
    }
  }
}
