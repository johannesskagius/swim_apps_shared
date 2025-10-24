import '../../enums/set_types.dart';

class MatchedSection {
  final SetType type;
  final String? notes; // Notes found on the same line as the section title

  MatchedSection(this.type, this.notes);
}
