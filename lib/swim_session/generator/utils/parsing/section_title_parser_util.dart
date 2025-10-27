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
  // --- Added: repetition tracking state shared between parsing steps ---
  static int? _pendingRepetitions;

  /// Applies a repetition (Nx) to the active configuration if pending.
  static void applyPendingRepetitions(SessionSetConfiguration config) {
    if (_pendingRepetitions != null) {
      config.repetitions = _pendingRepetitions!;
      _pendingRepetitions = null;
    }
  }

  /// Detects if a line is a set-laps (e.g. "2x", "3x") instruction and stores it temporarily.
  static bool detectAndStoreRepetitionMarker(String line) {
    final trimmed = line.trim();
    if (RegExp(r'^\d+\s*x\s*$').hasMatch(trimmed)) {
      try {
        _pendingRepetitions = int.parse(trimmed.replaceAll('x', '').trim());
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Parses the set type and notes from a regex match of a section title.
  static SectionTitleParseResult parseSectionTitleDetails(Match sectionTitleMatch) {
    String typeName = (sectionTitleMatch.group(1) ?? '').trim().toLowerCase();
    String? notesKeyword = sectionTitleMatch.group(2);

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
        determinedSetType = SetType.mainSet;
        break;
    }

    String? setNotes;
    if (notesKeyword != null && notesKeyword.isNotEmpty) {
      setNotes = notesKeyword.trim();
    }

    return SectionTitleParseResult(determinedSetType, setNotes);
  }

  /// Finalizes and adds the previous configuration to the parsed list.
  static void _finalizeAndAddPreviousConfig({
    required SessionSetConfiguration? config,
    required List<SetItem> items,
    required List<SessionSetConfiguration> parsedConfigsList,
    required String coachId,
    required SetType activeSetType,
    required String newSetId,
  }) {
    if (config == null) return;

    try {
      if (items.isNotEmpty) {
        config.swimSet = SwimSet(
          setId: config.swimSet?.setId ?? newSetId,
          type: config.swimSet?.type ?? activeSetType,
          items: List.from(items),
          setNotes: config.swimSet?.setNotes,
        );
      }

      // ✅ Apply any pending repetitions here as well before finalizing
      applyPendingRepetitions(config);

      if (_shouldAddConfig(config)) {
        if (config.coachId.isEmpty) {
          config.coachId = coachId;
        }
        parsedConfigsList.add(config);
      }
    } catch (e, s) {
      print('Error finalizing previous config: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'An exception occurred in _finalizeAndAddPreviousConfig.',
      );
    }
  }

  /// Determines if a SessionSetConfiguration should be added to the final list.
  static bool _shouldAddConfig(SessionSetConfiguration config) {
    final swimSet = config.swimSet;
    final notes = config.notesForThisInstanceOfSet;

    final bool hasActualContent = (swimSet != null && swimSet.items.isNotEmpty) ||
        (config.repetitions > 1 && notes != null && notes.isNotEmpty);

    final bool isEmptyTitleCard = (swimSet == null || swimSet.items.isEmpty) &&
        (notes == null || notes.isEmpty) &&
        config.repetitions == 1 &&
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
    _finalizeAndAddPreviousConfig(
      config: previousCurrentConfig,
      items: previousCurrentItems,
      parsedConfigsList: parsedConfigsList,
      coachId: coachId,
      activeSetType: activeSetTypeBeforeThisLine,
      newSetId: setId,
    );

    final SectionTitleParseResult sectionDetails =
    SectionTitleUtil.parseSectionTitleDetails(sectionTitleMatch);

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

    // ✅ Apply any pending Nx marker directly after creating this section
    applyPendingRepetitions(newConfig);

    return SectionTitleLineResult(newConfig, sectionDetails.setType);
  }
}
