import 'package:flutter/foundation.dart';

@immutable
class SetItemResult {
  final String resultId;
  final String sessionId;
  final String setItemId;
  final String swimmerId;

  final DateTime recordedAt;

  /// For long-term comparison (e.g. "50_free_push", "8x50_thr_avg").
  final String? testKey;

  // Core performance
  final Duration? time;
  final List<Duration>? repTimes;
  final List<int>? repStrokeCounts;
  final List<double>? repUnderwaters;
  final List<Duration>? splits;
  final int? heartRate;
  final double? rpe;
  final bool? success;

  // Context
  final int? poolLength;
  final List<String>? equipmentUsed;
  final String? lane;
  final Map<String, dynamic>? environment;

  // Flexible metrics
  final Map<String, dynamic>? metrics;

  final String? notes;
  final int schemaVersion;

  const SetItemResult({
    required this.resultId,
    required this.sessionId,
    required this.setItemId,
    required this.swimmerId,
    required this.recordedAt,
    this.testKey,
    this.time,
    this.repTimes,
    this.repStrokeCounts,
    this.repUnderwaters,
    this.splits,
    this.heartRate,
    this.rpe,
    this.success,
    this.poolLength,
    this.equipmentUsed,
    this.lane,
    this.environment,
    this.metrics,
    this.notes,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'sessionId': sessionId,
      'setItemId': setItemId,
      'swimmerId': swimmerId,
      'recordedAt': recordedAt.toIso8601String(),
      'testKey': testKey,
      'time': time?.inMilliseconds,
      'repTimes': repTimes?.map((t) => t.inMilliseconds).toList(),
      'repStrokeCounts': repStrokeCounts,
      'repUnderwaters': repUnderwaters,
      'splits': splits?.map((t) => t.inMilliseconds).toList(),
      'heartRate': heartRate,
      'rpe': rpe,
      'success': success,
      'poolLength': poolLength,
      'equipmentUsed': equipmentUsed,
      'lane': lane,
      'environment': environment,
      'metrics': metrics,
      'notes': notes,
      'schemaVersion': schemaVersion,
    };
  }

  factory SetItemResult.fromJson(Map<String, dynamic> json) {
    List<int>? ints(dynamic x) =>
        x is List ? x.whereType<num>().map((e) => e.toInt()).toList() : null;

    List<double>? doubles(dynamic x) =>
        x is List ? x.whereType<num>().map((e) => e.toDouble()).toList() : null;

    List<Duration>? times(dynamic x) => x is List
        ? x
        .whereType<num>()
        .map((e) => Duration(milliseconds: e.toInt()))
        .toList()
        : null;

    return SetItemResult(
      resultId: json['resultId'] as String,
      sessionId: json['sessionId'] as String,
      setItemId: json['setItemId'] as String,
      swimmerId: json['swimmerId'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      testKey: json['testKey'] as String?,
      time: json['time'] is num
          ? Duration(milliseconds: (json['time'] as num).toInt())
          : null,
      repTimes: times(json['repTimes']),
      repStrokeCounts: ints(json['repStrokeCounts']),
      repUnderwaters: doubles(json['repUnderwaters']),
      splits: times(json['splits']),
      heartRate: json['heartRate'] as int?,
      rpe: json['rpe'] is num ? (json['rpe'] as num).toDouble() : null,
      success: json['success'] as bool?,
      poolLength: json['poolLength'] as int?,
      equipmentUsed:
      (json['equipmentUsed'] as List?)?.whereType<String>().toList(),
      lane: json['lane'] as String?,
      environment: json['environment'] is Map
          ? Map<String, dynamic>.from(json['environment'] as Map)
          : null,
      metrics: json['metrics'] is Map
          ? Map<String, dynamic>.from(json['metrics'] as Map)
          : null,
      notes: json['notes'] as String?,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }
}
