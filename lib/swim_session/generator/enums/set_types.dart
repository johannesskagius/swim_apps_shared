enum SetType {
  warmUp,
  preSet, // Example: For a pre-main set
  mainSet,
  drillSet,
  kickSet,
  pullSet,
  postSet, // Example: For a post-main recovery or secondary set
  coolDown,
  recovery,
  custom, // For sets that don't fit predefined types or have custom names
  // Add any other types you need
}

extension SetTypeParsingInfoHelper on SetType {
  // Renamed to avoid conflict if defined elsewhere
  List<String> get parsingKeywords {
    switch (this) {
      case SetType.warmUp:
        return ['warm up', 'wu', 'Warm-up:'];
      case SetType.preSet:
        return ['pre set', 'pre-set', 'pre', 'Pre-set:'];
      case SetType.mainSet:
        return ['main set', 'main', 'ms', 'Main set:'];
      case SetType.drillSet:
        return [
          'drill set',
          'drills only',
        ]; // Keep distinct from SwimWays.drill
      case SetType.kickSet:
        return ['kick set', 'kicks only']; // Keep distinct from SwimWays.kick
      case SetType.pullSet:
        return ['pull set', 'pull only']; // Keep distinct from SwimWays.pull
      case SetType.coolDown:
        return ['cool down', 'cd', 'warm down', 'wd', 'Cool-down:'];
      case SetType.custom:
        return []; // Custom is usually by exclusion or explicit naming
      case SetType.recovery:
        return ['easy', 'rec', 'recovery'];
      case SetType.postSet:
        return ['warm down', 'post set','Post-set:'];
    }
  }

  // Ensure toDisplayString is also part of your enum or its extension
  String toDisplayString() {
    switch (this) {
      case SetType.warmUp:
        return 'Warm Up';
      case SetType.preSet:
        return 'Pre-Set';
      case SetType.mainSet:
        return 'Main Set';
      case SetType.drillSet:
        return 'Drill Set';
      case SetType.kickSet:
        return 'Kick Set';
      case SetType.pullSet:
        return 'Pull Set';
      case SetType.coolDown:
        return 'Cool Down';
      case SetType.custom:
        return 'Custom';
      default:
        String name = this.name;
        if (name.isEmpty) return 'Unknown Set Type';
        var result = name.replaceAllMapped(
          RegExp(r'(?=[A-Z])'),
          (match) => ' ${match.group(0)}',
        );
        return result[0].toUpperCase() + result.substring(1);
    }
  }
}
