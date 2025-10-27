import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Helper class to return both the extracted note and the modified line
class ItemNoteExtractionResult {
  final String? foundNote;
  final String remainingLine;

  ItemNoteExtractionResult(this.foundNote, this.remainingLine);
}

class ItemNoteParserUtil {
  // Regex to find the first single-quoted note.
  // - "'" : Matches the opening single quote.
  // - "\s*" : Matches any leading whitespace inside the quotes (optional).
  // - "([^']*?)" : Captures the actual note content (group 1).
  //    - "[^']*" : Matches any character that is not a single quote, zero or more times.
  //    - "?" after "*" makes it non-greedy, important if there could be multiple quoted strings on a line,
  //      though for item notes, we typically expect one or the first one.
  // - "\s*" : Matches any trailing whitespace inside the quotes (optional).
  // - "'" : Matches the closing single quote.
  static final RegExp _notePattern = RegExp(r"'\s*([^']*?)\s*'");

  /// Extracts the first single-quoted note from a line and removes it.
  /// Example: "100 fr 'easy pace' @1:30" -> foundNote: "easy pace", remainingLine: "100 fr @1:30"
  ///
  /// This function is designed to be resilient and handles cases where no note is found
  /// or when malformed input is provided.
  ///
  /// [Returns] An [ItemNoteExtractionResult] containing the parsed note (if any)
  /// and the line with the note removed.
  static ItemNoteExtractionResult extractAndRemove(String line) {
    try {
      final Match? match = _notePattern.firstMatch(line);

      // If no regex match is found, it means there's no single-quoted note.
      // Return the original line and a null note.
      if (match == null) {
        return ItemNoteExtractionResult(null, line);
      }

      // Extract the note and clean up the line.
      return _extractNoteFromMatch(line, match);
    } catch (e, s) {
      // --- Error Handling ---
      // This catch block acts as a safeguard against any unforeseen exceptions
      // that might occur during regex matching or string manipulation,
      // preventing a potential crash. For example, a highly complex or malformed
      // input string could theoretically cause issues in the regex engine.
      // By logging the error and returning the original line, we ensure the app
      // remains stable and can gracefully handle the parsing failure.
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'An unexpected error occurred in ItemNoteParserUtil.extractAndRemove',
      );

      // Return the original line as a fallback to prevent data loss or crashes.
      return ItemNoteExtractionResult(null, line);
    }
  }

  /// Refactored private helper to process a successful regex match.
  /// This improves readability and separates the logic of finding a match
  /// from the logic of processing it.
  static ItemNoteExtractionResult _extractNoteFromMatch(String line, Match match) {
    // Group 1 of the regex captures the content inside the single quotes.
    // e.g., for "' easy pace '", group 1 is " easy pace ".
    final String? noteContent = match.group(1);

    // Trim the extracted content to remove leading/trailing whitespace.
    // If the content is null or becomes an empty string after trimming (e.g., "''" or "' '"),
    // we treat it as if no note was provided.
    String? finalNote = noteContent?.trim();
    if (finalNote != null && finalNote.isEmpty) {
      finalNote = null;
    }

    // --- Refactoring for Readability ---
    // The original logic for removing the matched substring was correct but could be
    // error-prone if the indices were miscalculated. Using replaceRange is a more
    // readable and declarative way to achieve the same result, reducing the
    // cognitive load for future maintainers.
    final String remainingLine = line.replaceRange(match.start, match.end, '').trim();

    return ItemNoteExtractionResult(finalNote, remainingLine);
  }
}
