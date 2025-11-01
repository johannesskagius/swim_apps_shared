import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a swim club, including metadata, subscription info,
/// and optionally embedded groups for efficient counting.
class SwimClub {
  final String id;
  final String name;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 🟢 Subscription info (synced from clubSubscriptions)
  final String? planId; // e.g. "club_small", "club_large"
  final bool? isActive; // whether the subscription is active
  final DateTime? endDate; // expiration date of the plan

  // 🟣 NEW: group tracking fields
  final int? groupsCount; // used for frontend counting or analytics
  final int? maxGroups; // pulled from subscription plan
  final List<Map<String, dynamic>>? groups; // optional embedded group list

  SwimClub({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
    this.planId,
    this.isActive,
    this.endDate,
    this.groupsCount,
    this.maxGroups,
    this.groups,
  });

  // --- Factory: from Firestore document ---
  factory SwimClub.fromJson(Map<String, dynamic> json, String documentId) {
    return SwimClub(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Club',
      creatorId: json['creatorId'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      planId: json['planId'] as String?,
      isActive: json['isActive'] as bool?,
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      groupsCount: json['groupsCount'] as int?,
      maxGroups: json['maxGroups'] as int?,
      groups: (json['groups'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  // --- To JSON (for Firestore writes) ---
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (planId != null) 'planId': planId,
      if (isActive != null) 'isActive': isActive,
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (groupsCount != null) 'groupsCount': groupsCount,
      if (maxGroups != null) 'maxGroups': maxGroups,
      if (groups != null) 'groups': groups,
    };
  }

  // --- Helper: check if subscription is valid ---
  bool get hasActiveSubscription =>
      isActive == true &&
          (endDate == null || endDate!.isAfter(DateTime.now()));

  // --- Helper: count groups ---
  int get totalGroups => groupsCount ?? (groups?.length ?? 0);

  // --- Helper: check if club can add more groups ---
  bool get canAddGroup =>
      maxGroups == null || totalGroups < maxGroups!;

  // --- Copy with for immutability ---
  SwimClub copyWith({
    String? name,
    String? planId,
    bool? isActive,
    DateTime? endDate,
    int? groupsCount,
    int? maxGroups,
    List<Map<String, dynamic>>? groups,
  }) {
    return SwimClub(
      id: id,
      name: name ?? this.name,
      creatorId: creatorId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      planId: planId ?? this.planId,
      isActive: isActive ?? this.isActive,
      endDate: endDate ?? this.endDate,
      groupsCount: groupsCount ?? this.groupsCount,
      maxGroups: maxGroups ?? this.maxGroups,
      groups: groups ?? this.groups,
    );
  }
}
