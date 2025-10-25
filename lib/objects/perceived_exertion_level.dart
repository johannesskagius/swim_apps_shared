enum PerceivedExertionLevel {
  veryLight, // Represents 1
  light,     // Represents 2
  moderate,  // Represents 3
  hard,      // Represents 4
  veryHard;  // Represents 5

  // Helper to get a user-friendly description
  String get description {
    switch (this) {
      case PerceivedExertionLevel.veryLight:
        return '1: Very Light';
      case PerceivedExertionLevel.light:
        return '2: Light';
      case PerceivedExertionLevel.moderate:
        return '3: Moderate';
      case PerceivedExertionLevel.hard:
        return '4: Hard';
      case PerceivedExertionLevel.veryHard:
        return '5: Very Hard';
    }
  }

  // Helper to convert from an integer value (1-5)
  static PerceivedExertionLevel? fromInt(int? value) {
    if (value == null) return null;
    if (value >= 1 && value <= values.length) {
      return values[value - 1]; // Enum values are 0-indexed
    }
    return null; // Or throw error, or return a default
  }

  // Helper to convert to an integer value (1-5 for storage perhaps)
  int toInt() {
    return index + 1; // Enum values are 0-indexed
  }
}