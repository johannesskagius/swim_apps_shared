// lib/swim/objects/result_abstract.dart (or a suitable common location)
import 'package:cloud_firestore/cloud_firestore.dart'; // If using Timestamps

abstract class Result {
  final String id; // Unique ID for this specific result entry
  final String swimmerId; // ID of the swimmer this result belongs to
  final DateTime dateRecorded; // When the result was actually recorded/achieved
  final String
  recordedByCoachId; // ID of the coach who entered/verified the result (or system if automated)

  final String?
  resultNotes; // General notes about this result (effort, conditions, etc.)
  final Map<String, dynamic>? additionalData; // For any other custom data

  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor for the abstract class
  // Subclasses will call this via super(...)
  Result({
    required this.id,
    required this.swimmerId,
    required this.dateRecorded,
    required this.recordedByCoachId,
    this.resultNotes,
    this.additionalData,
    required this.createdAt,
    required this.updatedAt,
  });

  // Common toJson logic - Subclasses can call super.toJson() and add their specific fields
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'swimmerId': swimmerId,
      'dateRecorded': dateRecorded.toIso8601String(),
      'recordedByCoachId': recordedByCoachId,
      'resultNotes': resultNotes,
      'additionalData': additionalData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // fromJson cannot be a factory in an abstract class that directly constructs Result.
  // Instead, each subclass will have its own fromJson factory.
  // However, we can have a protected static helper if needed, or subclasses handle all parsing.

  // Abstract methods or properties that subclasses might need to implement, if any.
  // For example:
  // String get displaySummary;
}

// Helper for parsing DateTime, can be placed in a utility file or used by subclasses.
DateTime parseDateTimeFromJson(
  dynamic value,
  String fieldName,
  String className,
) {
  if (value is String) {
    return DateTime.parse(value);
  } else if (value is Timestamp) {
    // If using Firestore Timestamp
    return value.toDate();
  }
  throw FormatException(
    "Invalid DateTime format for $fieldName in $className: $value",
  );
}
