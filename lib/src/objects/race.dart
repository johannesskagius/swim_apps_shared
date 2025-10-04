import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analyzed_segment.dart';

/// Represents a full race analysis, ready to be stored in Firestore.
class Race {
  final String? id;
  final String eventName;
  final String raceName;
  final DateTime raceDate;
  final int poolLength;
  final String stroke;
  final int distance;
  final String? coachId;
  final String? swimmerId;
  final List<AnalyzedSegment> segments;

  Race({
    this.id,
    required this.eventName,
    required this.raceName,
    required this.raceDate,
    required this.poolLength,
    required this.stroke,
    required this.distance,
    required this.segments,
    this.coachId,
    this.swimmerId,
  });

  /// Converts this object into a Map for Firestore.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'eventName': eventName,
      'raceName': raceName,
      'raceDate': Timestamp.fromDate(raceDate),
      'poolLength': poolLength,
      'stroke': stroke,
      'distance': distance,
      'segments': segments.map((s) => s.toJson()).toList(),
    };

    if (coachId != null) {
      data['coachId'] = coachId;
    }
    if (swimmerId != null) {
      data['swimmerId'] = swimmerId;
    }

    return data;
  }

  /// Creates a Race object from a Firestore document.
  factory Race.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Race(
      id: doc.id,
      eventName: data['eventName'] as String,
      raceName: data['raceName'] as String,
      raceDate: (data['raceDate'] as Timestamp).toDate(),
      poolLength: data['poolLength'] as int,
      stroke: data['stroke'] as String,
      distance: data['distance'] as int,
      segments: (data['segments'] as List<dynamic>)
          .map((s) => AnalyzedSegment.fromMap(s as Map<String, dynamic>))
          .toList(),
      coachId: data['coachId'] as String?,
      swimmerId: data['swimmerId'] as String?,
    );
  }
}