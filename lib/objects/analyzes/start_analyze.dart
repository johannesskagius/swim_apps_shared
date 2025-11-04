import 'analyze_base.dart';

class StartAnalysis with AnalyzableBase {
  final String videoPath;
  final DateTime analysisDate;
  final Set<String> enabledAttributes;

  final Duration? reactionTime;
  final Duration? flightTime;
  final double? entryAngle;
  final double? backLegAngle;
  final double? frontLegAngle;
  final Duration? timeTo15m;
  final Duration? breakoutTime;
  final int? breakoutDolphinKicks;
  final Duration? timeToFirstDolphinKick;
  final Duration? timeToPullOut;
  final Duration? timeGlidingPostPullOut;
  final Duration? glidFaceAfterPullOut;
  final double? speedToFiveMeters;
  final double? speedTo10Meters;
  final double? speedTo15Meters;

  StartAnalysis({
    String? id,
    String? coachId,
    String? swimmerId,
    String? swimmerName,
    required this.videoPath,
    required this.analysisDate,
    this.enabledAttributes = const {},
    this.reactionTime,
    this.flightTime,
    this.entryAngle,
    this.backLegAngle,
    this.frontLegAngle,
    this.timeTo15m,
    this.breakoutTime,
    this.breakoutDolphinKicks,
    this.timeToFirstDolphinKick,
    this.timeToPullOut,
    this.timeGlidingPostPullOut,
    this.glidFaceAfterPullOut,
    this.speedToFiveMeters,
    this.speedTo10Meters,
    this.speedTo15Meters,
  }) {
    this.id = id;
    this.coachId = coachId;
    this.swimmerId = swimmerId;
    this.swimmerName = swimmerName;
  }

  Map<String, dynamic> toJson() => {
    ...analyzableBaseToJson(),
    'videoPath': videoPath,
    'analysisDate': analysisDate.toIso8601String(),
    'enabledAttributes': enabledAttributes.toList(),
    'reactionTime': reactionTime?.inMilliseconds,
    'flightTime': flightTime?.inMilliseconds,
    'entryAngle': entryAngle,
    'backLegAngle': backLegAngle,
    'frontLegAngle': frontLegAngle,
    'timeTo15m': timeTo15m?.inMilliseconds,
    'breakoutTime': breakoutTime?.inMilliseconds,
    'breakoutDolphinKicks': breakoutDolphinKicks,
    'timeToFirstDolphinKick': timeToFirstDolphinKick?.inMilliseconds,
    'timeToPullOut': timeToPullOut?.inMilliseconds,
    'timeGlidingPostPullOut': timeGlidingPostPullOut?.inMilliseconds,
    'glidFaceAfterPullOut': glidFaceAfterPullOut?.inMilliseconds,
    'speedToFiveMeters': speedToFiveMeters,
    'speedTo10Meters': speedTo10Meters,
    'speedTo15Meters': speedTo15Meters,
  };

  factory StartAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = StartAnalysis(
      id: json['id'],
      coachId: json['coachId'],
      swimmerId: json['swimmerId'],
      swimmerName: json['swimmerName'],
      videoPath: json['videoPath'],
      analysisDate: DateTime.parse(json['analysisDate']),
      enabledAttributes:
      (json['enabledAttributes'] as List<dynamic>?)?.map((e) => e as String).toSet() ?? {},
      reactionTime: _durationFromJson(json['reactionTime']),
      flightTime: _durationFromJson(json['flightTime']),
      entryAngle: (json['entryAngle'] as num?)?.toDouble(),
      backLegAngle: (json['backLegAngle'] as num?)?.toDouble(),
      frontLegAngle: (json['frontLegAngle'] as num?)?.toDouble(),
      timeTo15m: _durationFromJson(json['timeTo15m']),
      breakoutTime: _durationFromJson(json['breakoutTime']),
      breakoutDolphinKicks: json['breakoutDolphinKicks'],
      timeToFirstDolphinKick: _durationFromJson(json['timeToFirstDolphinKick']),
      timeToPullOut: _durationFromJson(json['timeToPullOut']),
      timeGlidingPostPullOut: _durationFromJson(json['timeGlidingPostPullOut']),
      glidFaceAfterPullOut: _durationFromJson(json['glidFaceAfterPullOut']),
      speedToFiveMeters: (json['speedToFiveMeters'] as num?)?.toDouble(),
      speedTo10Meters: (json['speedTo10Meters'] as num?)?.toDouble(),
      speedTo15Meters: (json['speedTo15Meters'] as num?)?.toDouble(),
    );
    analysis.loadAnalyzableBase(json, json['id'] ?? '');
    return analysis;
  }

  static Duration? _durationFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return Duration(milliseconds: value);
    if (value is double) return Duration(milliseconds: value.toInt());
    return null;
  }
}
