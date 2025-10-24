
import 'package:swim_apps_shared/swim_session/generator/enums/set_types.dart';
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/tag_parser_util.dart';

import '../../../objects/planned/set_item.dart';
import '../../../objects/planned/swim_set.dart';
import '../../../objects/planned/swim_set_config.dart';

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
  static SectionTitleParseResult parseSectionTitleDetails(
    Match sectionTitleMatch,
  ) {
    String typeName = sectionTitleMatch.group(1)!.trim().toLowerCase();
    String? notesKeyword = sectionTitleMatch.group(2);

    SetType determinedSetType;
    if (typeName == "warm up" || typeName == "warmup") {
      determinedSetType = SetType.warmUp;
    } else if (typeName == "cool down" || typeName == "cooldown") {
      determinedSetType = SetType.coolDown;
    } else if (typeName == "main set" || typeName == "main") {
      determinedSetType = SetType.mainSet;
    } else if (typeName == "kick set" || typeName == "kick") {
      determinedSetType = SetType.kickSet;
    } else if (typeName == "pull set" || typeName == "pull") {
      determinedSetType = SetType.pullSet;
    } else if (typeName == "drill set" || typeName == "drills") {
      determinedSetType = SetType.drillSet;
    } else if (typeName == "pre set") {
      determinedSetType = SetType.preSet;
    } else if (typeName == "post set") {
      determinedSetType = SetType.postSet;
    } else {
      determinedSetType = SetType.mainSet;
    }

    String? setNotes;
    if (notesKeyword != null && notesKeyword.isNotEmpty) {
      setNotes = notesKeyword.trim();
    }

    return SectionTitleParseResult(determinedSetType, setNotes);
  }

  static SectionTitleLineResult handleSectionTitleLine({
    required String originalLineText,
    required Match sectionTitleMatch,
    required TagExtractionResult tagResult,
    required SessionSetConfiguration? previousCurrentConfig,
    required List<SetItem> previousCurrentItems,
    required List<SessionSetConfiguration>
    parsedConfigsList, // Changed name for clarity
    required String coachId,
    required SetType activeSetTypeBeforeThisLine,
    required int newConfigOrder,
    required String setId,
    required String swimSetId,
  }) {
    // 1. Finalize and add the previous configuration
    if (previousCurrentConfig != null) {
      if (previousCurrentItems.isNotEmpty) {
        previousCurrentConfig.swimSet = SwimSet(
          setId: previousCurrentConfig.swimSet?.setId ?? setId,
          type:
              previousCurrentConfig.swimSet?.type ??
              activeSetTypeBeforeThisLine,
          items: List.from(previousCurrentItems),
          setNotes: previousCurrentConfig.swimSet?.setNotes,
        );
      }
      bool hasActualContent =
          (previousCurrentConfig.swimSet != null &&
              previousCurrentConfig.swimSet!.items.isNotEmpty) ||
          (previousCurrentConfig.repetitions > 1 &&
              previousCurrentConfig.notesForThisInstanceOfSet != null &&
              previousCurrentConfig.notesForThisInstanceOfSet!.isNotEmpty);
      bool isEmptyTitleCard =
          (previousCurrentConfig.swimSet == null ||
              previousCurrentConfig.swimSet!.items.isEmpty) &&
          (previousCurrentConfig.notesForThisInstanceOfSet == null ||
              previousCurrentConfig.notesForThisInstanceOfSet!.isEmpty) &&
          previousCurrentConfig.repetitions == 1 &&
          previousCurrentConfig.rawSetTypeHeaderFromText != null &&
          !previousCurrentConfig.rawSetTypeHeaderFromText!
              .toLowerCase()
              .contains("(default)");

      if (hasActualContent || isEmptyTitleCard) {
        if (previousCurrentConfig.coachId.isEmpty) {
          previousCurrentConfig.coachId = coachId;
        }
        parsedConfigsList.add(previousCurrentConfig); // Add to the passed list
      }
    }

    // 2. Parse details for the new section title
    final SectionTitleParseResult sectionDetails =
        SectionTitleUtil.parseSectionTitleDetails(sectionTitleMatch);

    // 3. Create the new SessionSetConfiguration
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
