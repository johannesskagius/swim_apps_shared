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

  static final RegExp swimmerTag =
  RegExp(r"#swimmers?\s+([^#\n\r]+)", caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🔹 Repetitions
  // ---------------------------------------------------------------------------
  static final RegExp standaloneReps =
  RegExp(r'^\s*(\d+)\s*(?:x|rounds?)\s*$', caseSensitive: false);

  static final RegExp inlineReps =
  RegExp(r'^\s*(\d+)\s*x\s*', caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🔹 Distance (50 fr, 100m, 25 bk) & Interval (@1:30)
  // ---------------------------------------------------------------------------
  static final RegExp distance =
  RegExp(r'^\s*(\d+)\s*([A-Za-z]{0,10})');

  static final RegExp interval =
  RegExp(r'@?\s*(\d{1,2}):(\d{2})');

  // ---------------------------------------------------------------------------
  // 🔹 Intensity (i1–i5, easy, moderate, threshold, sp1–3, etc.)
  // ---------------------------------------------------------------------------
  static final RegExp intensityIndex =
  RegExp(r'\bi\s*([1-5])\b', caseSensitive: false);

  static final RegExp intensityWord = RegExp(
    r'\b(max|easy|moderate|hard|threshold|sp1|sp2|sp3|drill|race|racepace|rp)\b',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 🔹 Equipment tags ([paddles], [fins], etc.)
  // ---------------------------------------------------------------------------
  static final RegExp equipment =
  RegExp(r'\[(.*?)\]', caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🔹 Sub-items (indented or bullet lines)
  // ---------------------------------------------------------------------------
  static final RegExp subItemLine =
  RegExp(r'^(?:\s{2,}|[-•>]\s+)(.+)$');

  // ---------------------------------------------------------------------------
  // 🔹 Swim way keywords (kick, pull, drill)
  // ---------------------------------------------------------------------------
  static final RegExp kickWord =
  RegExp(r'\bkick(ing)?\b', caseSensitive: false);

  static final RegExp pullWord =
  RegExp(r'\bpull(ing)?\b', caseSensitive: false);

  static final RegExp drillWord =
  RegExp(r'\bdrill(s)?\b', caseSensitive: false);

  // ---------------------------------------------------------------------------
  // 🎨 Highlight styles for CodeField (patternMap)
  // ---------------------------------------------------------------------------
  static final Map<RegExp, TextStyle> highlightMap = {
    // Headers
    sectionHeader: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.teal,
    ),

    // Distances
    distance: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.indigo,
    ),

    // Intervals @1:30
    interval: const TextStyle(
      color: Colors.deepOrange,
      fontWeight: FontWeight.w600,
    ),

    // Intensities
    intensityIndex: const TextStyle(
      color: Colors.orange,
      fontWeight: FontWeight.bold,
    ),
    intensityWord: const TextStyle(
      color: Colors.redAccent,
      fontWeight: FontWeight.w600,
    ),

    // Kick / Pull / Drill
    kickWord: const TextStyle(color: Colors.green),
    pullWord: const TextStyle(color: Colors.purple),
    drillWord: const TextStyle(
      color: Colors.blue,
      fontStyle: FontStyle.italic,
    ),

    // Equipment [paddles]
    equipment: const TextStyle(
      color: Colors.brown,
      fontWeight: FontWeight.w500,
    ),
  };
}
