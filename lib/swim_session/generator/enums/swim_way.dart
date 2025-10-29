enum SwimWay { pull, kick, drill, swim, uw, rest}

extension SwimWayParsingInfoHelper on SwimWay {
  List<String> get parsingKeywords {
    switch (this) {
      case SwimWay.kick:
        return ['kick', 'ki'];
      case SwimWay.drill:
        return ['drill', 'dr', 'tech', 'technical'];
      case SwimWay.pull:
        return ['pull', 'pu']; // 'pull' here refers to the action
      case SwimWay.swim:
        return ['swim', 'sw']; // 'swim' might be implicit
      case SwimWay.uw:
        return ['UW', 'uw']; //
      case SwimWay.rest:
        return ['rest', 'Rest']; //
    }
  }
}
