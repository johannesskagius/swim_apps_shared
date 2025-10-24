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

  /// Extracts the first single-quoted note found in the line.
  /// Example: "100 fr 'easy pace' @1:30" -> foundNote: "easy pace"
  ///
  /// Returns an [ItemNoteExtractionResult] containing the parsed note (if any)
  /// and the line with the note string (including quotes) removed.
  static ItemNoteExtractionResult extractAndRemove(String line) {
    Match? match = _notePattern.firstMatch(line);

    if (match != null) {
      // Group 1 contains the content inside the quotes
      String? noteContent = match.group(1);

      // Trim the extracted note content itself, then check if empty
      String? finalNote = noteContent?.trim();
      if (finalNote != null && finalNote.isEmpty) {
        finalNote =
            null; // Treat an empty quoted string (e.g., "''" or "' '") as no note
      }

      // Remove the matched part (e.g., "'easy pace'") from the line
      String remainingLine =
          line.substring(0, match.start) + line.substring(match.end);

      return ItemNoteExtractionResult(finalNote, remainingLine.trim());
    }

    // No note pattern found
    return ItemNoteExtractionResult(null, line);
  }
}
