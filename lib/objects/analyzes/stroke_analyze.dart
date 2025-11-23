import 'package:swim_apps_shared/objects/analyzes/stroke_segment_matrix.dart';
import 'package:swim_apps_shared/objects/analyzes/stroke_under_water_matrix.dart';
import 'package:swim_apps_shared/objects/intensity_zones.dart';
import 'package:swim_apps_shared/objects/stroke.dart';

import 'analyze_base.dart';

class StrokeAnalyze with AnalyzableBase {
  String title;
  String createdById;
  final Stroke stroke;
  final IntensityZone intensity;
  final Map<String, int> markedTimestamps;
  final List<int> strokeTimestamps;
  final double strokeFrequency;

  final UnderwaterMetrics underwater;
  final SegmentMetrics segment0_15m;
  final SegmentMetrics segment15_25m;
  final SegmentMetrics segmentFull25m;

  double? averageSpeed;
  late final double strokeLength;
  late final double cycleTime;
  late final double efficiencyIndex;
  late final double totalDistance;
  late final double underwaterTime;
  late final double underwaterDistance;
  late final double underwaterVelocity;
  late final double startReaction;
  late final double turnTime;

  final String? aiInterpretation;

  StrokeAnalyze({
    String? id,
    String? coachId,
    String? swimmerId,
    String? swimmerName,
    required this.title,
    required this.createdById,
    required this.stroke,
    required this.intensity,
    required this.markedTimestamps,
    required this.strokeTimestamps,
    required this.strokeFrequency,
    required this.underwater,
    required this.segment0_15m,
    required this.segment15_25m,
    required this.segmentFull25m,
    this.aiInterpretation,
  }) {
    this.id = id;
    this.coachId = coachId;
    this.swimmerId = swimmerId;
    this.swimmerName = swimmerName;

    // Derived metrics (same as before)
    averageSpeed = _computeAverageSpeed(segmentFull25m);
    strokeLength =
        segmentFull25m.strokeLength ??
        (strokeFrequency > 0 ? averageSpeed! / strokeFrequency : 0);
    cycleTime = strokeFrequency > 0 ? 1 / strokeFrequency : 0;
    efficiencyIndex = averageSpeed! * strokeLength;
    totalDistance = 25.0;
    underwaterTime = segment0_15m.phase1Time ?? 0.0;
    underwaterDistance = segment0_15m.phase1Distance ?? 0.0;
    underwaterVelocity = underwaterTime > 0
        ? underwaterDistance / underwaterTime
        : 0.0;
    startReaction = (markedTimestamps['reaction'] ?? 0) / 1000.0;
    turnTime = (markedTimestamps['turn'] ?? 0) / 1000.0;
  }

  double _computeAverageSpeed(SegmentMetrics seg) {
    if (seg.speed != null && seg.speed! > 0) return seg.speed!;
    if (seg.time != null && seg.time! > 0) return 25.0 / seg.time!;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    ...analyzableBaseToJson(),
    'title': title,
    'createdBy': createdById,
    'stroke': stroke.name,
    'intensity': intensity.name,
    'markedTimestamps': markedTimestamps,
    'strokeTimestamps': strokeTimestamps,
    'strokeFrequency': strokeFrequency,
    'underwater': underwater.toJson(),
    'segment0_15m': segment0_15m.toJson(),
    'segment15_25m': segment15_25m.toJson(),
    'segmentFull25m': segmentFull25m.toJson(),
    'averageSpeed': averageSpeed,
    'strokeLength': strokeLength,
    'cycleTime': cycleTime,
    'efficiencyIndex': efficiencyIndex,
    'totalDistance': totalDistance,
    'underwaterTime': underwaterTime,
    'underwaterDistance': underwaterDistance,
    'underwaterVelocity': underwaterVelocity,
    'startReaction': startReaction,
    'turnTime': turnTime,
    'aiInterpretation': aiInterpretation,
  };

  factory StrokeAnalyze.fromJson(Map<String, dynamic> json) {
    final analysis = StrokeAnalyze(
      id: json['id'],
      coachId: json['coachId'],
      swimmerId: json['swimmerId'],
      swimmerName: json['swimmerName'],
      aiInterpretation: json['aiInterpretation'],
      title: json['title'],
      createdById: json['createdBy'],
      stroke: Stroke.values.byName(json['stroke']),
      intensity: IntensityZone.values.byName(json['intensity']),
      markedTimestamps: Map<String, int>.from(json['markedTimestamps'] ?? {}),
      strokeTimestamps: List<int>.from(json['strokeTimestamps'] ?? []),
      strokeFrequency: (json['strokeFrequency'] as num?)?.toDouble() ?? 0,
      underwater: UnderwaterMetrics.fromJson(
        (json['underwater'] ?? {}) as Map<String, dynamic>,
      ),
      segment0_15m: SegmentMetrics.fromJson(
        (json['segment0_15m'] ?? {}) as Map<String, dynamic>,
      ),
      segment15_25m: SegmentMetrics.fromJson(
        (json['segment15_25m'] ?? {}) as Map<String, dynamic>,
      ),
      segmentFull25m: SegmentMetrics.fromJson(
        (json['segmentFull25m'] ?? {}) as Map<String, dynamic>,
      ),
    );
    analysis.averageSpeed =
        (json['averageSpeed'] as num?)?.toDouble() ??
        analysis._computeAverageSpeed(analysis.segmentFull25m);
    analysis.loadAnalyzableBase(json, json['id'] ?? '');
    return analysis;
  }
}
