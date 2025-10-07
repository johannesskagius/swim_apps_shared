// lib/users/coach.dart
import 'package:swim_apps_shared/src/objects/user.dart';
import 'package:swim_apps_shared/src/objects/user_types.dart';

class Coach extends AppUser {
  List<String> memberOfTeams;
  List<String> ownerOfTeams;
  String? coachCreatorId;
  bool? isAccountHolder;

  Coach({
    required super.id,
    required super.name,
    required super.email,
    super.lastName,
    super.profilePicturePath,
    super.registerDate,
    super.updatedAt,
    super.clubId,
    List<String>? memberOfTeams,
    List<String>? ownerOfTeams,
    this.coachCreatorId,
    this.isAccountHolder,
  }) : memberOfTeams = memberOfTeams ?? [],
       ownerOfTeams = ownerOfTeams ?? [],
       super(userType: UserType.coach);

  factory Coach.fromJson(String docId, Map<String, dynamic> json) {
    return Coach(
      id: docId,
      name: json['name'] as String? ?? 'Coach',
      lastName: json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      isAccountHolder: json['isAccountHolder'] as bool? ?? false,
      profilePicturePath: json['profilePicturePath'] as String?,
      registerDate: AppUser.parseDateTime(json['registerDate']),
      updatedAt: AppUser.parseDateTime(json['updatedAt']),
      clubId: json['clubId'] as String?,
      // Standardized from memberOfClubId
      memberOfTeams: json['memberOfTeams'] != null
          ? List<String>.from(json['memberOfTeams'] as List<dynamic>)
          : [],
      ownerOfTeams: json['ownerOfTeams'] != null
          ? List<String>.from(json['ownerOfTeams'] as List<dynamic>)
          : [],
      coachCreatorId: json['coachCreatorId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'memberOfTeams': memberOfTeams,
      'ownerOfTeams': ownerOfTeams,
      if (isAccountHolder != null) 'isAccountHolder': isAccountHolder,
      if (clubId != null) 'clubId': clubId,
      if (coachCreatorId != null) 'coachCreatorId': coachCreatorId,
    });
    return json;
  }

  @override
  Coach copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? profilePicturePath,
    DateTime? registerDate,
    DateTime? updatedAt,
    String? clubId, // Standardized from memberOfClubId
    List<String>? memberOfTeams,
    List<String>? ownerOfTeams,
    String? coachCreatorId,
    bool? isAccountHolder,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      registerDate: registerDate ?? this.registerDate,
      updatedAt: updatedAt ?? this.updatedAt,
      clubId: clubId ?? this.clubId,
      isAccountHolder: isAccountHolder ?? this.isAccountHolder,
      // Corrected logic
      memberOfTeams: memberOfTeams ?? this.memberOfTeams,
      ownerOfTeams: ownerOfTeams ?? this.ownerOfTeams,
      coachCreatorId: coachCreatorId ?? this.coachCreatorId,
    );
  }
}
