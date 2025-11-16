// swim_session/parser/session_syntax_patterns.dart
//
// Shared syntax patterns for both:
//   ✔ TextToSessionObjectParser
//   ✔ Flutter UI syntax highlighting
//
// Keeping all regexps in one place ensures the parser and UI always stay in sync.

import 'package:flutter/material.dart';

class SessionSyntaxPatterns {
  // ---------------------------------------------------------------------------
  // 🎨 Map for CodeController (String keys, SAFE for CodeField)
  // ---------------------------------------------------------------------------
  ///
  /// IMPORTANT:
  /// These are *simplified* patterns for UI highlighting only.
  /// The parser still uses the richer RegExp objects below.
  ///
  /// We avoid:
  ///   - ^ / $ anchors
  ///   - greedy `.*?`
  ///   - capturing groups (only non-capturing `(?:...)`)
  ///   - complex lookaheads
  ///
  /// to prevent CodeTextField from throwing RangeError on partial edits.
  static final Map<String, TextStyle> codeFieldPatternMap = {
    // SECTION HEADERS
    r'\b(?:warm ?up|main ?set|pre ?set|post ?set|cool ?down|'
    r'kick ?set|pull ?set|drill ?set|sprint ?set|recovery|'
    r'technique ?set|main|warmup|cooldown)\b':
    const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF2F6EAA), // Blue
    ),

    // DISTANCES (50m fr)
    r'\b\d+\s*(?:m|fr|bk|br|fly|im)\b':
    const TextStyle(
      fontWeight: FontWeight.w700,
      color: Color(0xFFC44536), // Red orange
    ),

    // INTERVALS (@1:20)
    r'@?\d{1,2}:\d{2}':
    const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF5E8C31), // Green
    ),

    // INTENSITY INDEX (i1..i5)
    r'\bi\s*[1-5]\b':
    const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFFD97706), // Amber
    ),

    // INTENSITY WORDS (easy, moderate...)
    r'\b(?:max|easy|moderate|hard|threshold|sp1|sp2|sp3|drill|race|racepace|rp)\b':
    const TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFFD97706), // Amber
    ),

    // TECHNIQUE WORDS
    r'\bkick(?:ing)?\b':
    const TextStyle(
      color: Color(0xFF6B46C1), // Purple
      fontStyle: FontStyle.italic,
    ),

    r'\bpull(?:ing)?\b':
    const TextStyle(
      color: Color(0xFF6B46C1),
      fontStyle: FontStyle.italic,
    ),

    r'\bdrill(?:s)?\b':
    const TextStyle(
      color: Color(0xFF6B46C1),
      fontStyle: FontStyle.italic,
    ),

    // EQUIPMENT ([paddles], [fins])
    r'\[[^\]]*\]':
    const TextStyle(
      color: Color(0xFF008B8B), // Dark Cyan
      fontWeight: FontWeight.w500,
    ),

    // GROUP TAGS (#group, #swimmers)
    r'#(?:group|swimmers?)\b.*':
    const TextStyle(
      color: Color(0xFF3182CE), // Light blue
    ),
  };


  // ---------------------------------------------------------------------------
  // 🔹 Section Headers (warm up, main set, cooldown, etc.)
  // ---------------------------------------------------------------------------
  static final RegExp sectionHeader = RegExp(
    r'^\s*(warm\s*up|main\s*set|pre\s*set|post\s*set|cool\s*down|'
    r'kick\s*set|pull\s*set|drill\s*set|sprint\s*set|recovery|'
    r'technique\s*set|main|warmup|cooldown)\b',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🔹 Group + Swimmer tags (#group A, #swimmers Emma,John)
  // ---------------------------------------------------------------------------
  static final RegExp groupTag = RegExp(
    r"#group[:\-\s]*([A-Za-z0-9_ ]+?)(?=\s*[\d\'#]|$)",
    caseSensitive: false,
  );

  static final RegExp swimmerTag = RegExp(
    r"#swimmers?\s+([^#\n\r]+)",
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🔹 Repetitions
  // ---------------------------------------------------------------------------
  static final RegExp standaloneReps = RegExp(
    r'^\s*(\d+)\s*(?:x|rounds?)\s*$',
    caseSensitive: false,
  );

  static final RegExp inlineReps = RegExp(
    r'^\s*(\d+)\s*x\s*',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🔹 Distance (50 fr, 100m, 25 bk) & Interval (@1:30)
  // ---------------------------------------------------------------------------
  static final RegExp distance = RegExp(r'^\s*(\d+)\s*([A-Za-z]{0,10})');

  static final RegExp interval = RegExp(r'@?\s*(\d{1,2}):(\d{2})');

  // ---------------------------------------------------------------------------
  // 🔹 Intensity (i1–i5, easy, moderate, threshold, sp1–3, etc.)
  // ---------------------------------------------------------------------------
  static final RegExp intensityIndex = RegExp(
    r'\bi\s*([1-5])\b',
    caseSensitive: false,
  );

  static final RegExp intensityWord = RegExp(
    r'\b(max|easy|moderate|hard|threshold|sp1|sp2|sp3|drill|race|racepace|rp)\b',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🔹 Equipment tags ([paddles], [fins], etc.)
  // ---------------------------------------------------------------------------
  static final RegExp equipment = RegExp(r'\[(.*?)\]', caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🔹 Sub-items (indented or bullet lines)
  // ---------------------------------------------------------------------------
  static final RegExp subItemLine = RegExp(
    r'^\s*-\s+(.+)$',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🔹 Swim way keywords (kick, pull, drill)
  // ---------------------------------------------------------------------------
  static final RegExp kickWord = RegExp(
    r'\bkick(ing)?\b',
    caseSensitive: false,
  );

  static final RegExp pullWord = RegExp(
    r'\bpull(ing)?\b',
    caseSensitive: false,
  );

  static final RegExp drillWord = RegExp(
    r'\bdrill(s)?\b',
    caseSensitive: false,
  );

  // Tags that mark items as requiring results
  static final RegExp requiresResultTag = RegExp(
    r'(\!result|\[result\]|\*[ ]?result|\#result\b)',
    caseSensitive: false,
  );

// More general result tags like #test_50free, #speed_test
  static final RegExp resultTag = RegExp(
    r'\#(test_[A-Za-z0-9_]+)',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🎨 Highlight styles (can still be used elsewhere if needed)
  // ---------------------------------------------------------------------------
  static final Map<RegExp, TextStyle> highlightMap = {
    sectionHeader: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.teal,
    ),
    distance: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.indigo,
    ),
    interval: const TextStyle(
      color: Colors.deepOrange,
      fontWeight: FontWeight.w600,
    ),
    intensityIndex: const TextStyle(
      color: Colors.orange,
      fontWeight: FontWeight.bold,
    ),
    intensityWord: const TextStyle(
      color: Colors.redAccent,
      fontWeight: FontWeight.w600,
    ),
    kickWord: const TextStyle(color: Colors.green),
    pullWord: const TextStyle(color: Colors.purple),
    drillWord:
    const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
    equipment: const TextStyle(
      color: Colors.brown,
      fontWeight: FontWeight.w500,
    ),
  };
}
