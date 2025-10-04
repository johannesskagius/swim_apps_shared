enum Stroke {
  butterfly('Butterfly', 'bu'),
  freestyle('Freestyle', 'fr'),
  backstroke('Backstroke', 'ba'),
  breaststroke('Breaststroke', 'br'),
  medley('Medley', 'IM'),
  choice('Choice', 'c'),
  unknown('Unknown', 'unknown');

  final String description;
  final String short;

  const Stroke(this.description, this.short);

  // Helper to get Stroke from string name (for fromJson)
  static Stroke? fromString(String? name) {
    if (name == null) return null;
    try {
      return Stroke.values.firstWhere((e) => e.name == name);
    } catch (e) {
      print('Warning: Unknown Stroke string: $name');
      return null; // Or a default, or rethrow
    }
  }

  String get displayName {
    switch (this) {
      case Stroke.freestyle:
        return 'Freestyle';
      case Stroke.backstroke:
        return 'Backstroke';
      case Stroke.breaststroke:
        return 'Breaststroke';
      case Stroke.butterfly:
        return 'Butterfly';
      case Stroke.medley:
        return 'IM';
      case Stroke.choice:
        return 'Choice';
      case Stroke.unknown:
        return 'unknown';
    }
  }
}

extension StrokeParsingHelper on Stroke {
  List<String> get parsingKeywords {
    switch (this) {
      case Stroke.freestyle:
        return ['freestyle', 'free', 'fr'];
      case Stroke.backstroke:
        return ['backstroke', 'back', 'bk'];
      case Stroke.breaststroke:
        return ['breaststroke', 'breast', 'br'];
      case Stroke.butterfly:
        return ['butterfly', 'fly', 'bu', 'bf'];
      case Stroke.medley:
        return ['im', 'i.m.', 'medley', 'individual medley', 'me'];
      case Stroke.choice:
        return ['choice', 'ch', 'c'];
      case Stroke.unknown:
        return ['uk', 'unknown'];
    }
  }
}
