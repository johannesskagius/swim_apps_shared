// lib/swim/parser/parser_spec.dart
class ParserSpec {
  static const version = "1.0.0";

  static const overview = """
The textToSessionParser converts a coach's textual swim_session description into structured SessionSetConfiguration objects.
Each line defines a swim set or instruction using a strict format.
""";

  static const formattingRules = [
    "Use [Reps]x[Distance][Unit] format, e.g. 4x100m.",
    "Intervals are specified with @ or on, e.g. @ 1:30.",
    "Each instruction must be on its own line.",
    "Use #, //, or () for comments.",
  ];

  static const semanticRules = [
    "Section headers end with ':', e.g. Warm-up:, Main set:, Cool-down:.",
    "Swimmer/group targeting uses square brackets: [Group A] or [Alice].",
    "Units default to meters (m) if omitted.",
  ];

  static const parserBehavior = [
    "Unknown lines are ignored or treated as notes.",
    "Missing intervals result in null interval values.",
    "Greedy extraction for partial matches.",
  ];

  static const examples = {
    "valid": [
      "Warm-up:\n4x100m Fr @ 1:45\n8x50y Kick on 55",
      "[Group A] 6x200m IM @ 3:10 (focus on transitions)"
    ],
    "invalid": [
      "@ 1:30 4x100m Fr // wrong order",
      "Four 100s freestyle on one thirty"
    ]
  };

  static const coachChecklist = [
    "[ ] One instruction per line.",
    "[ ] Use stroke abbreviations (Fr, Bk, Br, Fl, IM).",
    "[ ] Use '@' or 'on' for intervals.",
    "[ ] Add sections with ':' (Warm-up:, Main set:).",
    "[ ] Tag groups/swimmers with [].",
  ];

  /// Returns a map identical to the expected AI JSON format
  static Map<String, dynamic> toJson() => {
    "version": version,
    "overview": overview,
    "formattingRequirements": formattingRules,
    "semanticRequirements": semanticRules,
    "examples": examples,
    "parserBehavior": parserBehavior,
    "coachWritingChecklist": coachChecklist,
  };
}
