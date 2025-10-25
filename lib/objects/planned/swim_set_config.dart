
import 'package:swim_apps_shared/objects/planned/swim_set.dart';

class SessionSetConfiguration {
  String sessionSetConfigId;
  String swimSetId;
  int order;
  int repetitions;
  String? notesForThisInstanceOfSet;
  bool storedSet;
  SwimSet? swimSet;
  String coachId;
  String? rawSetTypeHeaderFromText;
  List<String> unparsedTextLines;
  List<String> specificSwimmerIds;
  List<String> specificGroupIds;

  SessionSetConfiguration({
    required this.sessionSetConfigId,
    required this.swimSetId,
    required this.order,
    required this.repetitions,
    required this.storedSet,
    required this.coachId,
    this.notesForThisInstanceOfSet,
    this.swimSet,
    this.rawSetTypeHeaderFromText,
    this.unparsedTextLines = const [],
    this.specificSwimmerIds = const [],
    this.specificGroupIds = const [],
  });

  // --------------------------------------------------------------------------
  // ✅ Copy method
  // --------------------------------------------------------------------------
  SessionSetConfiguration copyWith({
    String? sessionSetConfigId,
    String? swimSetId,
    int? order,
    int? repetitions,
    String? notesForThisInstanceOfSet,
    bool? storedSet,
    SwimSet? swimSet,
    String? coachId,
    String? rawSetTypeHeaderFromText,
    List<String>? unparsedTextLines,
    List<String>? specificSwimmerIds,
    List<String>? specificGroupIds,
  }) {
    return SessionSetConfiguration(
      sessionSetConfigId: sessionSetConfigId ?? this.sessionSetConfigId,
      swimSetId: swimSetId ?? this.swimSetId,
      order: order ?? this.order,
      repetitions: repetitions ?? this.repetitions,
      notesForThisInstanceOfSet:
          notesForThisInstanceOfSet ?? this.notesForThisInstanceOfSet,
      storedSet: storedSet ?? this.storedSet,
      swimSet: swimSet ?? this.swimSet,
      coachId: coachId ?? this.coachId,
      rawSetTypeHeaderFromText:
          rawSetTypeHeaderFromText ?? this.rawSetTypeHeaderFromText,
      unparsedTextLines: unparsedTextLines ?? List.from(this.unparsedTextLines),
      specificSwimmerIds:
          specificSwimmerIds ?? List.from(this.specificSwimmerIds),
      specificGroupIds: specificGroupIds ?? List.from(this.specificGroupIds),
    );
  }

  // --------------------------------------------------------------------------
  // ✅ Serialization for Firestore
  // --------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'setConfigId': sessionSetConfigId,
      'swimSetId': swimSetId,
      'order': order,
      'repetitions': repetitions,
      'storedSet': storedSet,
      'coachId': coachId,
      'rawSetTypeHeaderFromText': rawSetTypeHeaderFromText,
      'unparsedTextLines': unparsedTextLines,
      'specificSwimmerIds': specificSwimmerIds,
      'specificGroupIds': specificGroupIds,
      if (swimSet != null && !storedSet) 'swimSet': swimSet!.toJson(),
      if (notesForThisInstanceOfSet != null)
        'notesForThisInstanceOfSet': notesForThisInstanceOfSet,
    };
  }

  // --------------------------------------------------------------------------
  // ✅ Defensive fromJson (Firestore-safe)
  // --------------------------------------------------------------------------
  factory SessionSetConfiguration.fromJson(Map<String, dynamic> json) {
    final swimSetRaw = json['swimSet'];
    final safeSwimSet = (swimSetRaw is Map<String, dynamic>)
        ? SwimSet.fromJson(swimSetRaw)
        : null;

    return SessionSetConfiguration(
      sessionSetConfigId: json['setConfigId'] ?? '',
      swimSetId: json['swimSetId'] ?? '',
      order: json['order'] ?? 0,
      repetitions: json['repetitions'] ?? 1,
      storedSet: json['storedSet'] ?? false,
      coachId: json['coachId'] ?? '',
      notesForThisInstanceOfSet: json['notesForThisInstanceOfSet'] as String?,
      rawSetTypeHeaderFromText: json['rawSetTypeHeaderFromText'] as String?,
      swimSet: safeSwimSet,
      unparsedTextLines: List<String>.from(
        json['unparsedTextLines'] as List? ?? const [],
      ),
      specificSwimmerIds: List<String>.from(
        json['specificSwimmerIds'] as List? ?? const [],
      ),
      specificGroupIds: List<String>.from(
        json['specificGroupIds'] as List? ?? const [],
      ),
    );
  }
}
