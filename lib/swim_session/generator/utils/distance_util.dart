// Helper extension (place outside class or in a utility file if not already)
extension NumRounding on num {
  int roundToNearest50() {
    if (this == 0) return 0;
    return ((this + 24.999) / 25).floor() *
        50; // Add small epsilon for borderline cases before floor
  }
}
