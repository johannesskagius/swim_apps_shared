enum EventSpecialization {
  sprint,          // 50 & 100
  middleDistance,  // 200–400
  distance;        // 800–1500

  String get label {
    switch (this) {
      case EventSpecialization.sprint:
        return "Sprint (50–100m)";
      case EventSpecialization.middleDistance:
        return "Middle Distance (200–400m)";
      case EventSpecialization.distance:
        return "Distance (800–1500m)";
    }
  }

  String get description {
    switch (this) {
      case EventSpecialization.sprint:
        return "Explosive power and max velocity focus.";
      case EventSpecialization.middleDistance:
        return "Blend of aerobic and anaerobic endurance.";
      case EventSpecialization.distance:
        return "Long aerobic endurance and pacing control.";
    }
  }

  static EventSpecialization fromString(String name) {
    switch (name.toLowerCase()) {
      case "sprint":
        return EventSpecialization.sprint;
      case "middle":
      case "middledistance":
        return EventSpecialization.middleDistance;
      case "distance":
        return EventSpecialization.distance;
      default:
        return EventSpecialization.middleDistance;
    }
  }
}
