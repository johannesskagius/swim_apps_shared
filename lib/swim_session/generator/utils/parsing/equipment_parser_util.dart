import '../../enums/equipment.dart';

class EquipmentExtractionResult {
  final List<EquipmentType> foundEquipment;
  final String remainingLine;

  EquipmentExtractionResult(this.foundEquipment, this.remainingLine);
}

class EquipmentParserUtil {
  // Regex to find the first equipment block like "[fins paddles]"
  // It captures the content *inside* the brackets.
  // - r"\[": Matches the opening square bracket.
  // - r"\s*": Matches any whitespace characters (spaces, tabs, newlines) zero or more times. (allows for spaces like [ fins ] )
  // - r"([^\]]*?)": This is the capturing group (group 1).
  //    - "[^\]]": Matches any character that is NOT a closing square bracket.
  //    - "*?": Matches the previous character zero or more times, but as few times as possible (non-greedy).
  //            This is important if there are multiple sets of brackets on a line or nested (though nested isn't typical for this use case).
  // - r"\s*": Matches any whitespace characters zero or more times before the closing bracket.
  // - r"\]": Matches the closing square bracket.
  static final RegExp _equipmentBlockPattern = RegExp(r"\[\s*([^\]]*?)\s*\]");

  /// Parses the content string from within an equipment block (e.g., "fins paddles").
  /// This method identifies known equipment keywords within the provided string.
  static List<EquipmentType> parseFromContentString(String? contentString) {
    if (contentString == null || contentString.trim().isEmpty) {
      // If the content string itself is empty, this is different from "[]" which is handled
      // in extractAndRemove. Here, an empty string from within brackets, if it's not "[]",
      // might mean no specific equipment. Returning [] is appropriate.
      return [];
    }

    Set<EquipmentType> foundEquipment = {};
    String lowerText = contentString.trim().toLowerCase();
    bool specificEquipmentFound = false;

    // Iterate through all defined equipment types
    for (EquipmentType equipType in EquipmentType.values) {
      // Skip EquipmentType.none in the first pass if it only has "empty" as a keyword trigger.
      // We'll handle it later if no other specific equipment is found.
      // This is to prevent 'none' from being added if 'fins' is also present,
      // just because an "empty" part of the string might technically match an empty keyword for 'none'.
      if (equipType == EquipmentType.none &&
          equipType.parsingKeywords.any((k) => k.trim().isEmpty)) {
        // We will evaluate adding 'none' later if nothing else is found AND
        // if 'none' was explicitly requested by a non-empty keyword like "no equipment".
        // For now, if 'none' is only triggered by an implicit empty match, skip it.
      }

      for (String keyword in equipType.parsingKeywords) {
        if (keyword.trim().isEmpty) {
          // Generally, empty keywords are problematic for specific equipment types.
          // EquipmentType.none might be an exception if it's *meant* to match empty strings
          // (though this is better handled by the "[]" rule in extractAndRemove).
          // If an actual equipment type (not 'none') has an empty keyword, it's likely a config error.
          if (equipType != EquipmentType.none) continue;
          // If it IS EquipmentType.none and the keyword is empty, this specific keyword shouldn't add it
          // if other specific equipment is found. This scenario is tricky.
          // The "[]" rule in extractAndRemove is cleaner for this.
          // For now, let's assume empty keywords in parsingKeywords for *specific* equipment
          // (other than a conceptual 'none' for empty strings) are not intended.
          continue; // Avoid processing empty keywords for named equipment.
        }

        RegExp keywordRegex = RegExp(
          r"\b" + RegExp.escape(keyword.toLowerCase()) + r"\b",
          caseSensitive: false,
        );

        if (keywordRegex.hasMatch(lowerText)) {
          if (equipType != EquipmentType.none) {
            foundEquipment.add(equipType);
            specificEquipmentFound = true;
          } else if (equipType == EquipmentType.none &&
              keyword.trim().isNotEmpty) {
            // Only add EquipmentType.none if it was matched by an *explicit, non-empty* keyword
            // like "no equipment".
            foundEquipment.add(EquipmentType.none);
            specificEquipmentFound =
                true; // 'none' explicitly stated is specific
          }
        }
      }
    }

    // If specific equipment (including 'none' via an explicit keyword) was found, return it.
    if (specificEquipmentFound) {
      // If EquipmentType.none was added via an explicit keyword like "no equipment"
      // AND other equipment was also found (e.g., "[no equipment fins]"),
      // you need to decide the precedence. Usually, explicit equipment overrides "no equipment".
      // So, if 'none' is in foundEquipment AND other items are also there, remove 'none'.
      if (foundEquipment.contains(EquipmentType.none) &&
          foundEquipment.length > 1) {
        foundEquipment.remove(EquipmentType.none);
      }
      return foundEquipment.toList();
    }

    // If the original contentString was not empty, but no *specific* equipment keywords were found,
    // this means the content was unknown (e.g., "[xyz]").
    // In this case, return an empty list. The "[] means none" and "no brackets mean none"
    // are handled in extractAndRemove.
    return [];
  }

  /// Extracts the *first* equipment block (e.g., "[fins]") found in the line.
  /// An equipment block is defined as text enclosed in square brackets.
  ///
  /// Returns an [EquipmentExtractionResult] containing:
  /// - `foundEquipment`: A list of [EquipmentType]s parsed from the content within the first found block.
  ///                     Empty if no block is found or if the block's content doesn't match known equipment.
  /// - `remainingLine`: The original line with the *first* matched equipment block (including brackets) removed.
  ///                    If no block is found, this is the original line.
  static EquipmentExtractionResult extractAndRemove(String line) {
    Match? match = _equipmentBlockPattern.firstMatch(line);

    if (match != null) {
      String contentInsideBrackets = match.group(1)!;
      String fullMatchedBlock = match.group(0)!;
      List<EquipmentType> equipmentList; // Renamed for clarity

      if (contentInsideBrackets.trim().isEmpty) {
        equipmentList = [EquipmentType.none]; // Represents "[]"
      } else {
        equipmentList = parseFromContentString(contentInsideBrackets);
      }
      String remainingLine = line.replaceFirst(fullMatchedBlock, '').trim();
      return EquipmentExtractionResult(equipmentList, remainingLine);
    }
    return EquipmentExtractionResult(
      [],
      line,
    ); // Return empty list, line unchanged
  }
}
