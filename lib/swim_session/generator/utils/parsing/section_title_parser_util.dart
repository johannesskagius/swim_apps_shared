import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swim_apps_shared/swim_session/generator/enums/set_types.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/tag_parser_util.dart';

import '../../../../objects/planned/set_item.dart';
import '../../../../objects/planned/swim_set.dart';
import '../../../../objects/planned/swim_set_config.dart';

class SectionTitleParseResult {
  final SetType setType;
  final String? setNotes;

  SectionTitleParseResult(this.setType, this.setNotes);
}

class SectionTitleLineResult {
  final SessionSetConfiguration newConfig;
  final SetType newActiveSetType;

  SectionTitleLineResult(this.newConfig, this.newActiveSetType);
}

class SectionTitleUtil {
  /// Parses the set type and notes from a regex match of a section title.
  ///
  /// This function is now safer, handling cases where regex groups might be null.
  static SectionTitleParseResult parseSectionTitleDetails(
      Match sectionTitleMatch,
      ) {
    // Use null-safe access for the regex group and provide a default empty string.
    // This prevents a crash if group(1) is unexpectedly null.
    String typeName = (sectionTitleMatch.group(1) ?? '').trim().toLowerCase();
    String? notesKeyword = sectionTitleMatch.group(2);

    // Refactored the long if-else chain into a more readable and maintainable switch statement.
    SetType determinedSetType;
    switch (typeName) {
      case "warm up":
      case "warmup":
        determinedSetType = SetType.warmUp;
        break;
      case "cool down":
      case "cooldown":
        determinedSetType = SetType.coolDown;
        break;
      case "main set":
      case "main":
        determinedSetType = SetType.mainSet;
        break;
      case "kick set":
      case "kick":
        determinedSetType = SetType.kickSet;
        break;
      case "pull set":
      case "pull":
        determinedSetType = SetType.pullSet;
        break;
      case "drill set":
      case "drills":
        determinedSetType = SetType.drillSet;
        break;
      case "pre set":
        determinedSetType = SetType.preSet;
        break;
      case "post set":
        determinedSetType = SetType.postSet;
        break;
      default:
      // Default to mainSet for any unrecognized type.
        determinedSetType = SetType.mainSet;
        break;
    }

    String? setNotes;
    // The conditional check for notes remains as it is clear and effective.
    if (notesKeyword != null && notesKeyword.isNotEmpty) {
      setNotes = notesKeyword.trim();
    }

    return SectionTitleParseResult(determinedSetType, setNotes);
  }

  /// Refactored from `handleSectionTitleLine` to specifically handle the finalization
  /// of the previous set configuration. This improves separation of concerns.
  static void _finalizeAndAddPreviousConfig({
    required SessionSetConfiguration? config,
    required List<SetItem> items,
    required List<SessionSetConfiguration> parsedConfigsList,
    required String coachId,
    required SetType activeSetType,
    required String newSetId,
  }) {
    if (config == null) {
      return; // Nothing to do if there's no previous config.
    }

    try {
      if (items.isNotEmpty) {
        config.swimSet = SwimSet(
          setId: config.swimSet?.setId ?? newSetId,
          type: config.swimSet?.type ?? activeSetType,
          items: List.from(items),
          setNotes: config.swimSet?.setNotes,
        );
      }

      // Refactored complex boolean logic into a separate, well-named private method for clarity.
      if (_shouldAddConfig(config)) {
        if (config.coachId.isEmpty) {
          config.coachId = coachId;
        }
        parsedConfigsList.add(config);
      }
    } catch (e, s) {
      // Added a try-catch block to handle any unexpected errors during finalization.
      // This is a critical stability improvement.
      print('Error finalizing previous config: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'An exception occurred in _finalizeAndAddPreviousConfig.',
      );
    }
  }

  /// Determines if a SessionSetConfiguration should be added to the final list.
  /// Logic is extracted from the main function for improved readability and testability.
  static bool _shouldAddConfig(SessionSetConfiguration config) {
    final swimSet = config.swimSet;
    final notes = config.notesForThisInstanceOfSet;

    // Condition 1: The set has actual content (items or repeated notes).
    final bool hasActualContent = (swimSet != null && swimSet.items.isNotEmpty) ||
        (config.repetitions > 1 && notes != null && notes.isNotEmpty);

    // Condition 2: The set is an "empty title card" meant for display.
    // Null-safe operators `?.` are used to prevent crashes on `rawSetTypeHeaderFromText`.
    final bool isEmptyTitleCard = (swimSet == null || swimSet.items.isEmpty) &&
        (notes == null || notes.isEmpty) &&
        config.repetitions == 1 &&
        // Added a null-check on rawSetTypeHeaderFromText before calling toLowerCase().
        // This was a potential crash point.
        (config.rawSetTypeHeaderFromText?.toLowerCase().contains("(default)") == false);

    return hasActualContent || isEmptyTitleCard;
  }

  /// Handles the parsing of a line identified as a section title.
  static SectionTitleLineResult handleSectionTitleLine({
    required String originalLineText,
    required Match sectionTitleMatch,
    required TagExtractionResult tagResult,
    required SessionSetConfiguration? previousCurrentConfig,
    required List<SetItem> previousCurrentItems,
    required List<SessionSetConfiguration> parsedConfigsList,
    required String coachId,
    required SetType activeSetTypeBeforeThisLine,
    required int newConfigOrder,
    required String setId,
    required String swimSetId,
  }) {
    // 1. Finalize the previous section by calling the new, separated function.
    _finalizeAndAddPreviousConfig(
      config: previousCurrentConfig,
      items: previousCurrentItems,
      parsedConfigsList: parsedConfigsList,
      coachId: coachId,
      activeSetType: activeSetTypeBeforeThisLine,
      newSetId: setId,
    );

    // 2. Parse details for the new section title.
    final SectionTitleParseResult sectionDetails =
    SectionTitleUtil.parseSectionTitleDetails(sectionTitleMatch);

    // 3. Create the new SessionSetConfiguration for the current section.
    // This logic remains largely the same as it was already clear.
    final SessionSetConfiguration newConfig = SessionSetConfiguration(
      sessionSetConfigId: setId,
      swimSetId: swimSetId,
      order: newConfigOrder,
      repetitions: 1,
      storedSet: false,
      coachId: coachId,
      specificSwimmerIds: List<String>.from(tagResult.swimmerIds),
      specificGroupIds: List<String>.from(tagResult.groupIds),
      swimSet: SwimSet(
        setId: setId,
        type: sectionDetails.setType,
        items: [],
        setNotes: sectionDetails.setNotes,
      ),
      rawSetTypeHeaderFromText: originalLineText,
      notesForThisInstanceOfSet: sectionDetails.setNotes,
      unparsedTextLines: [],
    );

    return SectionTitleLineResult(newConfig, sectionDetails.setType);
  }
}
