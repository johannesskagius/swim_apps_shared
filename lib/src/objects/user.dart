// lib/users/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swim_apps_shared/src/objects/swimmer.dart';

import 'coach.dart';
import 'user_types.dart';

abstract class AppUser {
  String id;
  String name;
  String? lastName;
  String email;
  String? photoUrl;
  UserType userType;
  String? profilePicturePath;
  DateTime? registerDate;
  DateTime? updatedAt;
  String? clubId;
  String? creatorId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.photoUrl,
    this.lastName,
    this.profilePicturePath,
    this.registerDate,
    this.updatedAt,
    this.clubId,
    this.creatorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'userType': userType.name,
      'photoUrl':photoUrl,
      if (clubId != null) 'clubId': clubId, // Added clubId to serialization
      if (profilePicturePath != null) 'profilePicturePath': profilePicturePath,
      if (registerDate != null)
        'registerDate': Timestamp.fromDate(registerDate!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (creatorId != null) 'creatorId': creatorId,
    };
  }

  factory AppUser.fromJson(String docId, Map<String, dynamic> json) {
    UserType detectedUserType = _getUserTypeFromString(
      json['userType'] as String?,
    );
    json['userType'] = detectedUserType.name;

    switch (detectedUserType) {
      case UserType.coach:
        return Coach.fromJson(docId, json);
      case UserType.swimmer:
        return Swimmer.fromJson(docId, json);
    }
  }

  static UserType _getUserTypeFromString(String? nameFromJson) {
    if (nameFromJson == null) return UserType.swimmer;
    try {
      return UserType.values.firstWhere((e) => e.name == nameFromJson);
    } catch (e) {
      return UserType.swimmer;
    }
  }

  static DateTime? parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) return value.toDate();
    return null;
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    UserType? userType,
    String? profilePicturePath,
    DateTime? registerDate,
    DateTime? updatedAt,
    String? clubId, // Standardized from memberOfClubId
  });

  static Future<AppUser?> signUpUserWithEmail({
    required String newName,
    required String newEmail,
    required String password,
    required UserType userType,
    String? profilePicturePath,
    String? clubId, // Standardized from memberOfClubId
    List<String>? coachMemberOfTeams,
    List<String>? coachOwnerOfTeams,
    String? coachCoachCreatorId,
    List<String>? swimmerMemberOfTeams,
    String? swimmerCoachCreatorId,
  }) async {
    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: newEmail, password: password);
      User? firebaseUser = userCred.user;
      if (firebaseUser == null) return null;

      if (newName.isNotEmpty) await firebaseUser.updateDisplayName(newName);

      final now = DateTime.now();
      Map<String, dynamic> profileJson = {
        'name': newName.isNotEmpty
            ? newName
            : (firebaseUser.displayName ?? newEmail.split('@')[0]),
        'email': firebaseUser.email!,
        'userType': userType.name,
        'profilePicturePath': profilePicturePath ?? firebaseUser.photoURL,
        'registerDate': Timestamp.fromDate(
          firebaseUser.metadata.creationTime ?? now,
        ),
        'updatedAt': Timestamp.fromDate(now),
        'clubId': clubId, // Standardized from memberOfClubId
        'memberOfTeams': userType == UserType.coach
            ? coachMemberOfTeams
            : (userType == UserType.swimmer ? swimmerMemberOfTeams : []),
        'ownerOfTeams': userType == UserType.coach ? coachOwnerOfTeams : [],
        'coachCreatorId': userType == UserType.coach
            ? coachCoachCreatorId
            : (userType == UserType.swimmer ? swimmerCoachCreatorId : null),
      };

      AppUser newUserProfile = AppUser.fromJson(firebaseUser.uid, profileJson);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUserProfile.id)
          .set(newUserProfile.toJson());
      return newUserProfile;
    } catch (e) {
      debugPrint("Error during signUp process: $e");
      return null;
    }
  }

  Future<void> updateFirebaseAuthDisplayName(String newDisplayName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == id) {
      if (newDisplayName.isEmpty) return;
      try {
        await currentUser.updateDisplayName(newDisplayName);
        name = newDisplayName;
        updatedAt = DateTime.now();
        await FirebaseFirestore.instance.collection('users').doc(id).update({
          'name': newDisplayName,
          'updatedAt': Timestamp.fromDate(updatedAt!),
        });
      } catch (e) {
        debugPrint("Error updating display name for ID $id: $e");
      }
    }
  }
}
