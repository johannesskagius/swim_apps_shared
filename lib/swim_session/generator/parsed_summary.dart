/// 🧾 Compact summary of a parsed text session
class ParsedSummary {
  final Map<String, double> metersByGroup;
  final double totalMeters;
  final int totalItems;
  final int totalSections;

  ParsedSummary({
    required this.metersByGroup,
    required this.totalMeters,
    required this.totalItems,
    required this.totalSections,
  });

  @override
  String toString() {
    return "ParsedSummary(groups=$metersByGroup, totalMeters=$totalMeters, totalItems=$totalItems, totalSections=$totalSections)";
  }
}
