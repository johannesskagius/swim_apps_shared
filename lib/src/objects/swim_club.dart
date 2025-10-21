import 'package:cloud_firestore/cloud_firestore.dart';

class SwimClub {
  final String id;
  final String name;
  final String creatorId; // The user ID of the coach who created the club
  final DateTime createdAt; // The timestamp when the club was created
  final DateTime? updatedAt; // The timestamp when the club was updated

  SwimClub({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
  });

  factory SwimClub.fromJson(Map<String, dynamic> json, String documentId) {
    return SwimClub(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Club',
      creatorId: json['creatorId'] as String? ?? '', // Default to empty string if missing
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(), // Default to now if missing
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt), // Store as a Firestore Timestamp
      if(updatedAt != null )'updatedAt': Timestamp.fromDate(updatedAt!), // Store as a Firestore Timestamp
    };
  }
}