
import 'package:swim_apps_shared/swim_session/generator/utils/parsing/parsed_component.dart';

import '../../../../objects/stroke.dart';
import '../../enums/swim_way.dart';

class SwimWayStrokeParserUtil {
  /// Parses the main component text to identify the SwimWay and Stroke.
  ///
  /// The method prioritizes longer, more specific keywords.
  /// For example, "fly kick" would correctly identify kick as the SwimWay
  /// if "kick" is processed after "fly" for Stroke determination.
  static ParsedItemComponents parse(String mainText) {
    String remainingText = mainText.trim().toLowerCase();
    SwimWay detectedSwimWay = SwimWay.swim; // Default
    Stroke? detectedStroke = Stroke.freestyle; // Default

    // Prioritize longer keywords for SwimWay to match specific ones first
    // (e.g., "scull" before "pull" if "scull" is a type of pull)
    List<SwimWay> sortedSwimWays = List.from(SwimWay.values)
      ..sort(
        (a, b) =>
            b.parsingKeywords.join("").length -
            a.parsingKeywords.join("").length,
      );

    SwimWayLoop:
    for (SwimWay way in sortedSwimWays) {
      // Also sort individual keywords of a SwimWay by length, descending
      List<String> sortedWayKeywords = List.from(way.parsingKeywords)
        ..sort((a, b) => b.length - a.length);

      for (String keyword in sortedWayKeywords.map((k) => k.toLowerCase())) {
        // Use word boundaries to ensure whole word matching
        final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
        if (regex.hasMatch(remainingText)) {
          detectedSwimWay = way;
          remainingText = remainingText.replaceFirst(regex, "").trim();
          remainingText = remainingText.replaceAll(
            RegExp(r"\s\s+"),
            " ",
          ); // Compact multiple spaces
          break SwimWayLoop; // Found the most specific SwimWay
        }
      }
    }

    // Prioritize longer keywords for Stroke
    List<Stroke> sortedStrokes = List.from(Stroke.values)
      ..sort(
        (a, b) =>
            b.parsingKeywords.join("").length -
            a.parsingKeywords.join("").length,
      );

    StrokeLoop:
    for (Stroke stroke in sortedStrokes) {
      // Also sort individual keywords of a Stroke by length, descending
      List<String> sortedStrokeKeywords = List.from(stroke.parsingKeywords)
        ..sort((a, b) => b.length - a.length);

      for (String keyword in sortedStrokeKeywords.map((k) => k.toLowerCase())) {
        // Use word boundaries
        final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
        if (regex.hasMatch(remainingText)) {
          detectedStroke = stroke;
          remainingText = remainingText.replaceFirst(regex, "").trim();
          remainingText = remainingText.replaceAll(
            RegExp(r"\s\s+"),
            " ",
          ); // Compact multiple spaces
          break StrokeLoop; // Found the most specific Stroke
        }
      }
    }

    // The 'remainingText' could be passed as 'unparsedDetails' if ParsedItemComponents supports it
    // For now, adhering to the existing structure of ParsedItemComponents.
    // If ParsedItemComponents had: ParsedItemComponents(this.swimWay, this.stroke, {this.unparsedDetails})
    // you could do:
    // return ParsedItemComponents(detectedSwimWay, detectedStroke, unparsedDetails: remainingText.isNotEmpty ? remainingText : null);
    return ParsedItemComponents(detectedSwimWay, detectedStroke);
  }
}
