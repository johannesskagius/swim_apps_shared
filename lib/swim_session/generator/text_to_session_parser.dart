import 'package:swim_apps_shared/swim_apps_shared.dart';

// Removed ItemNoteParserUtil import from here as it's already specific above

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
    //Todo to proper Id
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
      // Add any other set/section titles you expect users to write.
    ];

    String patternPart = keywords
        .map((k) => RegExp.escape(k.toLowerCase()))
        .join("|");

    // Group 1: The set title keyword (e.g., "warmup")
    String part1Title = r"^\s*(" + patternPart + r")"; // Group 1 is the keyword

    //Option 2
    String part2OptionalNotes = r'''(?:\s*'([^']*)')?''';

    //option 3
    String part3End = r"$";

    return RegExp(
      part1Title + part2OptionalNotes + part3End,
      caseSensitive: false,
    );
  }

  DistanceUnit? _tryParseDistanceUnitFromString(String? unitStr) {
    if (unitStr == null) return null;
    String lowerUnit = unitStr.trim().toLowerCase();
    if (lowerUnit == 'm' || lowerUnit == 'meter' || lowerUnit == 'meters') {
      return DistanceUnit.meters;
    }
    if (lowerUnit == 'y' ||
        lowerUnit == 'yd' ||
        lowerUnit == 'yds' ||
        lowerUnit == 'yard' ||
        lowerUnit == 'yards') {
      return DistanceUnit.yards;
    }
    if (lowerUnit == 'k' ||
        lowerUnit == 'km' ||
        lowerUnit == 'kilometer' ||
        lowerUnit == 'kilometers') {
      return DistanceUnit.kilometers;
    }
    return null; // Not a recognized unit string
  }

  SetItem? parseLineToSetItem(
    String rawLine,
    int itemOrder,
    DistanceUnit sessionDefaultUnit,
  ) {
    String currentLine = rawLine.trim();
    if (currentLine.isEmpty) return null;

    int repetitions = 1;
    int? distance;
    DistanceUnit? distanceUnit;
    String? notes;
    List<EquipmentType> equipment = [];
    Duration? interval;
    IntensityZone? intensity;

    // Notes Extraction - now uses the utility
    final noteExtractionResult = ItemNoteParserUtil.extractAndRemove(
      currentLine,
    );
    notes = noteExtractionResult.foundNote; // This can be null
    currentLine = noteExtractionResult.remainingLine;
    currentLine = currentLine.trim(); // Ensure trimmed after note extraction

    // EquipmentParser - now uses the utility
    while (true) {
      final EquipmentExtractionResult extractionResult =
          EquipmentParserUtil.extractAndRemove(currentLine);
      if (extractionResult.foundEquipment.isNotEmpty) {
        equipment.addAll(extractionResult.foundEquipment);
        currentLine = extractionResult.remainingLine;
      } else {
        break;
      }
    }
    currentLine = currentLine.trim(); // Trim after all equipment processing

    // Interval Parser - now uses the utility
    final intervalExtractionResult = IntervalParserUtil.extractAndRemove(
      currentLine,
    );
    if (intervalExtractionResult.foundInterval != null) {
      interval = intervalExtractionResult.foundInterval;
      currentLine = intervalExtractionResult.remainingLine;
    }
    currentLine = currentLine.replaceAll(RegExp(r"\s\s+"), " ").trim();

    //Intensity Parser
    bool intensityFound = false;
    for (IntensityZone zone in IntensityZone.values) {
      if (intensityFound) break;
      List<String> sortedKeywords = List.from(zone.parsingKeywords)
        ..sort((a, b) => b.length - a.length);

      for (String keyword in sortedKeywords) {
        final intensityRegex = RegExp(
          r"\b" + RegExp.escape(keyword.toLowerCase()) + r"\b",
          caseSensitive: false,
        );
        Match? intensityMatch = intensityRegex.firstMatch(currentLine);

        if (intensityMatch != null) {
          intensity = zone;
          currentLine = currentLine
              .replaceFirst(intensityMatch.group(0)!, "")
              .trim();
          intensityFound = true;
          break;
        }
      }
    }
    currentLine = currentLine.replaceAll(RegExp(r"\s\s+"), " ").trim();

    final repsMatch = RegExp(r"^(\d+)x\s*").firstMatch(currentLine);
    if (repsMatch != null) {
      repetitions = int.tryParse(repsMatch.group(1)!) ?? 1;
      currentLine = currentLine.substring(repsMatch.end).trimLeft();
    }

    String remainderAfterDistanceAndUnit = currentLine;
    final distOnlyMatch = RegExp(r"^(\d+)").firstMatch(currentLine);

    if (distOnlyMatch != null) {
      distance = int.tryParse(distOnlyMatch.group(1)!);
      if (distance == null || distance == 0) return null;

      String lineAfterDistance = currentLine
          .substring(distOnlyMatch.end)
          .trimLeft();
      final unitMatch = RegExp(
        r"^([a-zA-Z]{1,10})(?=\s|$)",
      ).firstMatch(lineAfterDistance);

      if (unitMatch != null) {
        final potentialUnitStr = unitMatch.group(1);
        DistanceUnit? parsedUnit = _tryParseDistanceUnitFromString(
          potentialUnitStr,
        );

        if (parsedUnit != null) {
          distanceUnit = parsedUnit;
          remainderAfterDistanceAndUnit = lineAfterDistance
              .substring(unitMatch.end)
              .trimLeft();
        } else {
          distanceUnit = sessionDefaultUnit;
          remainderAfterDistanceAndUnit = lineAfterDistance;
        }
      } else {
        distanceUnit = sessionDefaultUnit;
        remainderAfterDistanceAndUnit = lineAfterDistance;
      }
      currentLine = remainderAfterDistanceAndUnit;
    } else {
      if (repetitions > 1) return null;
      return null;
    }

    String mainComponentText = currentLine.trim();

    // Use the new SwimWayStrokeParserUtil
    ParsedItemComponents components = SwimWayStrokeParserUtil.parse(
      mainComponentText,
    );

    return SetItem(
      id: _generateUniqueId("itemV2_"),
      order: itemOrder,
      itemRepetition: repetitions,
      itemDistance: distance,
      distanceUnit: distanceUnit,
      swimWay: components.swimWay,
      stroke: components.stroke,
      interval: interval,
      intensityZone: intensity,
      equipment: equipment,
      itemNotes: notes,
      rawTextLine: rawLine,
      subItems: [],
    );
  }

  List<SessionSetConfiguration> parseTextToSetConfigurations({
    required String? unParsedText,
    required String coachId,
    DistanceUnit defaultSessionUnit = DistanceUnit.meters,
    List<Swimmer> availableSwimmers = const [],
    List<SwimGroup> availableGroups = const [],
  }) {
    if (unParsedText == null || unParsedText.trim().isEmpty) return [];

    List<SessionSetConfiguration> parsedConfigs = [];
    List<String> allLines = unParsedText
        .split(lineBreakRegex)
        .map((line) => line.trim())
        .toList();

    SessionSetConfiguration? currentConfig;
    List<SetItem> currentItems = [];
    int itemOrder = 0;
    SetType activeSetType = SetType.mainSet;

    for (String line in allLines) {
      if (line.isEmpty) continue;

      final TagExtractionResult tagResult = TagExtractUtil.extractTagsFromLine(
        line,
        availableSwimmers,
        availableGroups,
      );
      String lineAfterTagRemoval = tagResult.remainingLine;

      Match? sectionTitleMatch = sectionTitleRegex.firstMatch(
        lineAfterTagRemoval,
      );
      Match? internalRepMatch = internalRepetitionLineRegex.firstMatch(
        lineAfterTagRemoval,
      );

      if (sectionTitleMatch != null) {
        final SectionTitleLineResult titleLineResult =
            SectionTitleUtil.handleSectionTitleLine(
              originalLineText: line,
              // The raw line for 'rawSetTypeHeaderFromText'
              sectionTitleMatch: sectionTitleMatch,
              tagResult: tagResult,
              // The result from TagExtractUtil
              previousCurrentConfig: currentConfig,
              // Pass the existing currentConfig
              previousCurrentItems: currentItems,
              // Pass the existing currentItems
              parsedConfigsList: parsedConfigs,
              // Pass the main list to be added to
              coachId: coachId,
              activeSetTypeBeforeThisLine: activeSetType,
              // The activeSetType before this line
              newConfigOrder: parsedConfigs.length,
              // Order for the new config
              setId: _generateUniqueId(),
              swimSetId: _generateUniqueId(),
            );

        currentConfig = titleLineResult.newConfig;
        activeSetType = titleLineResult.newActiveSetType;
        currentConfig.specificSwimmerIds =
            titleLineResult.newConfig.specificSwimmerIds;
        currentConfig.specificGroupIds =
            titleLineResult.newConfig.specificGroupIds;
        itemOrder = 0; // Reset itemOrder for the new set
        currentItems.clear(); // Clear items for the new set
      } else if (internalRepMatch != null) {
        if (currentConfig != null && currentItems.isEmpty) {
          int repetitions =
              int.tryParse(
                internalRepMatch.group(1) ?? internalRepMatch.group(2) ?? "1",
              ) ??
              1;
          currentConfig.repetitions = repetitions;
        } else if (currentConfig != null && currentItems.isNotEmpty) {
          // This is an internal repetition for a sub-set or a more complex structure not yet fully supported by this logic.
          // For now, we might treat it as a note or a new type of item if it makes sense.
          // Or, if it's meant to apply to the *next* set, the logic needs adjustment.
          // Current interpretation: applies to current config if items are empty.
          // Could also be the start of a "loop" SetItem feature if we enhance SetItem.
          print(
            "Note: Internal repetition line '${lineAfterTagRemoval}' found after items already added to current set. Repetition ignored for current items.",
          );
          // Potentially, this could be a SetItem by itself if designed:
          // SetItem loopItem = SetItem(id: _generateUniqueId(), order: itemOrder++, itemRepetition: repetitions, rawTextLine: lineAfterTagRemoval ...);
          // currentItems.add(loopItem);
          // For now, let's parse it as a simple SetItem if it can be, or log it.
          SetItem? item = parseLineToSetItem(
            lineAfterTagRemoval,
            itemOrder++,
            defaultSessionUnit,
          );
          if (item != null) {
            currentItems.add(item);
          } else {
            print(
              "Warning: Could not parse internal repetition line as a SetItem: $lineAfterTagRemoval",
            );
          }
        } else {
          // No currentConfig to apply repetitions to. This might be an orphaned line.
          // Or, parse it as a SetItem itself if it's like "2x" as its own instruction.
          SetItem? item = parseLineToSetItem(
            lineAfterTagRemoval,
            itemOrder++,
            defaultSessionUnit,
          );
          if (item != null) {
            // This case implies it might be a new implicit set
            if (currentConfig != null) {
              // Add to previous config if one exists
              currentItems.add(item);
            } else {
              // Create a new default main set for this item
              currentConfig = SessionSetConfiguration(
                sessionSetConfigId: _generateUniqueId("ssc_orph_"),
                swimSetId: _generateUniqueId("sconf_orph_"),
                order: parsedConfigs.length,
                repetitions: 1,
                storedSet: false,
                coachId: coachId,
                specificSwimmerIds: List<String>.from(tagResult.swimmerIds),
                // Use from tagResult
                specificGroupIds: List<String>.from(tagResult.groupIds),
                // Use from tagResult
                swimSet: SwimSet(
                  setId: _generateUniqueId("set_orph_"),
                  type: SetType.mainSet, // Default type
                  items: [item],
                ),
                rawSetTypeHeaderFromText: "(Default Set)",
                unparsedTextLines: [],
              );
              // Since this item started a new config, we'll add the config at the end of the loop iteration.
            }
          } else {
            print(
              "Warning: Orphaned internal repetition line ignored: $lineAfterTagRemoval",
            );
          }
        }
      } else {
        SetItem? item = parseLineToSetItem(
          lineAfterTagRemoval,
          itemOrder++,
          defaultSessionUnit,
        );
        if (item != null) {
          currentConfig ??= SessionSetConfiguration(
            sessionSetConfigId: _generateUniqueId("ssc_def_"),
            swimSetId: _generateUniqueId("sconf_def_"),
            order: parsedConfigs.length,
            repetitions: 1,
            storedSet: false,
            coachId: coachId,
            specificSwimmerIds: List<String>.from(tagResult.swimmerIds),
            // Use from tagResult
            specificGroupIds: List<String>.from(tagResult.groupIds),
            // Use from tagResult
            swimSet: SwimSet(
              setId: _generateUniqueId("set_def_"),
              type: activeSetType,
              items: [],
            ),
            rawSetTypeHeaderFromText:
                "(Default Set) ${activeSetType.toDisplayString()}",
            unparsedTextLines: [],
          );
          currentItems.add(item);
        }
      }
    }

    if (currentConfig != null) {
      if (currentItems.isNotEmpty) {
        currentConfig.swimSet = SwimSet(
          setId: currentConfig.swimSet?.setId ?? _generateUniqueId("set_last_"),
          type: currentConfig.swimSet?.type ?? activeSetType,
          items: List.from(currentItems),
          setNotes:
              currentConfig.swimSet?.setNotes, // Preserve notes from header
        );
      }
      bool hasActualContent =
          (currentConfig.swimSet != null &&
              currentConfig.swimSet!.items.isNotEmpty) ||
          (currentConfig.repetitions > 1 &&
              currentConfig.notesForThisInstanceOfSet != null &&
              currentConfig.notesForThisInstanceOfSet!.isNotEmpty);
      bool isEmptyTitleCard =
          (currentConfig.swimSet == null ||
              currentConfig.swimSet!.items.isEmpty) &&
          (currentConfig.notesForThisInstanceOfSet == null ||
              currentConfig.notesForThisInstanceOfSet!.isEmpty) &&
          currentConfig.repetitions == 1 &&
          currentConfig.rawSetTypeHeaderFromText != null &&
          !currentConfig.rawSetTypeHeaderFromText!.toLowerCase().contains(
            "(default)",
          );

      if (hasActualContent || isEmptyTitleCard) {
        if (currentConfig.coachId.isEmpty) {
          currentConfig.coachId = coachId;
        }
        parsedConfigs.add(currentConfig);
      }
    }
    return parsedConfigs;
  }
}
