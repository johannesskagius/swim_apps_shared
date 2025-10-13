// lib/users/swimmer.dart
import 'package:swim_apps_shared/src/objects/user.dart';
import 'package:swim_apps_shared/src/objects/user_types.dart';

class Swimmer extends AppUser {
  String? headCoachId;
  String? secondCoachId;
  String? thirdCoachId;
  List<String>? memberOfTeams;

  Swimmer({
    required super.id,
    required super.name,
    required super.email,
    super.lastName,
    super.profilePicturePath,
    super.registerDate,
    super.clubId,
    super.updatedAt,
    this.memberOfTeams,
    super.creatorId,
    this.secondCoachId,
    this.thirdCoachId,
  }) : super(userType: UserType.swimmer);

  factory Swimmer.fromJson(String docId, Map<String, dynamic> json) {
    return Swimmer(
      id: docId,
      name: json['name'] as String? ?? 'Swimmer',
      lastName: json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      profilePicturePath: json['profilePicturePath'] as String?,
      registerDate: AppUser.parseDateTime(json['registerDate']),
      updatedAt: AppUser.parseDateTime(json['updatedAt']),
      clubId: json['clubId'] as String?, // Standardized from memberOfClubId
      memberOfTeams: json['memberOfTeams'] != null ? List<String>.from(json['memberOfTeams'] as List<dynamic>) : [],
      creatorId: json['creatorId'] ?? json['coachCreatorId'] as String?,
      secondCoachId: json['secondCoachId'] as String?,
      thirdCoachId: json['thirdCoachId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      if (creatorId != null) 'coachCreatorId': creatorId,
      if (secondCoachId != null) 'secondCoachId': secondCoachId,
      if (thirdCoachId != null) 'thirdCoachId': thirdCoachId,
      if (memberOfTeams != null) 'memberOfTeams': memberOfTeams,
    });
    return json;
  }//

  @override
  Swimmer copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    UserType? userType,
    String? profilePicturePath,
    DateTime? registerDate,
    DateTime? updatedAt,
    String? clubId, // Standardized from memberOfClubId
    List<String>? memberOfTeams,
    String? creatorId,
    String? secondCoachId,
    String? thirdCoachId,
  }) {
    return Swimmer(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      registerDate: registerDate ?? this.registerDate,
      updatedAt: updatedAt ?? this.updatedAt,
      clubId: clubId ?? this.clubId,
      memberOfTeams: memberOfTeams ?? this.memberOfTeams,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}
