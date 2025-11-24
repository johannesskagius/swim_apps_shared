class StartAnalyze {
  final String id;
  final String title;
  final DateTime date;

  final String? swimmerId;
  final String? swimmerName;

  final String coachId;
  final String clubId;

  final Map<String, int> markedTimestamps;

  final double startDistance;
  final double startHeight;

  final Map<String, double>? jumpData;

  String? aiInterpretation;

  final DateTime createdDate;
  final DateTime? updatedDate;

  StartAnalyze({
    required this.id,
    required this.title,
    required this.date,
    required this.coachId,
    required this.clubId,
    required this.markedTimestamps,
    required this.startDistance,
    required this.startHeight,
    required this.createdDate,
    this.updatedDate,
    this.swimmerId,
    this.swimmerName,
    this.jumpData,
    this.aiInterpretation,
  });

  // ---------------------------------------------------------------------------
  // COPYWITH (needed for auto-save)
  // ---------------------------------------------------------------------------
  StartAnalyze copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? swimmerId,
    String? swimmerName,
    String? coachId,
    String? clubId,
    Map<String, int>? markedTimestamps,
    double? startDistance,
    double? startHeight,
    Map<String, double>? jumpData,
    String? aiInterpretation,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return StartAnalyze(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      swimmerId: swimmerId ?? this.swimmerId,
      swimmerName: swimmerName ?? this.swimmerName,
      coachId: coachId ?? this.coachId,
      clubId: clubId ?? this.clubId,
      markedTimestamps: markedTimestamps ?? this.markedTimestamps,
      startDistance: startDistance ?? this.startDistance,
      startHeight: startHeight ?? this.startHeight,
      jumpData: jumpData ?? this.jumpData,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  // ---------------------------------------------------------------------------
  // FROM MAP
  // ---------------------------------------------------------------------------
  factory StartAnalyze.fromMap(Map<String, dynamic> map, String id) {
    return StartAnalyze(
      id: id,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      clubId: map['clubId'] as String,
      coachId: map['coachId'] as String,
      createdDate: DateTime.parse(map['createdDate'] as String),
      updatedDate: map['updatedDate'] != null
          ? DateTime.parse(map['updatedDate'] as String)
          : null,
      swimmerId: map['swimmerId'] as String?,
      swimmerName: map['swimmerName'] as String?,
      markedTimestamps: Map<String, int>.from(map['markedTimestamps'] as Map),
      startDistance: (map['startDistance'] as num).toDouble(),
      startHeight: (map['startHeight'] as num).toDouble(),
      aiInterpretation: map['aiInterpretation'],
      jumpData: map['jumpData'] != null
          ? Map<String, double>.from(map['jumpData'] as Map)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TO MAP
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'swimmerId': swimmerId,
      'swimmerName': swimmerName,
      'clubId': clubId,
      'coachId': coachId,
      'createdDate': createdDate.toIso8601String(),
      if (updatedDate != null) 'updatedDate': updatedDate!.toIso8601String(),
      'markedTimestamps': markedTimestamps,
      'startDistance': startDistance,
      'startHeight': startHeight,
      'aiInterpretation': aiInterpretation,
      if (jumpData != null) 'jumpData': jumpData,
    };
  }
}

// ---------------------------------------------------------------------------
// TABLE ROW DATA MODEL (move this to shared file)
// ---------------------------------------------------------------------------

class TableRowData {
  final String label;
  final double timeSeconds;
  final double distanceMeters;
  final double speed;

  TableRowData({
    required this.label,
    required this.timeSeconds,
    required this.distanceMeters,
    required this.speed,
  });

  Map<String, dynamic> toMap() => {
    "label": label,
    "timeSeconds": timeSeconds,
    "distanceMeters": distanceMeters,
    "speed": speed,
  };

  factory TableRowData.fromMap(Map<String, dynamic> map) {
    return TableRowData(
      label: map["label"],
      timeSeconds: (map["timeSeconds"] as num).toDouble(),
      distanceMeters: (map["distanceMeters"] as num).toDouble(),
      speed: (map["speed"] as num).toDouble(),
    );
  }
}
