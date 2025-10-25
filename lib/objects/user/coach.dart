

import 'package:swim_apps_shared/objects/user/user.dart';
import 'package:swim_apps_shared/objects/user/user_types.dart';

class Coach extends AppUser {
  List<String> memberOfTeams;
  List<String> ownerOfTeams;
  bool isAccountHolder;

  Coach({
    required super.id,
    required super.name,
    required super.email,
    super.lastName,
    super.profilePicturePath,
    super.photoUrl,
    super.registerDate,
    super.updatedAt,
    super.clubId,
    super.creatorId,
    List<String>? memberOfTeams,
    List<String>? ownerOfTeams,
    this.isAccountHolder = false,
  })  : memberOfTeams = memberOfTeams ?? [],
        ownerOfTeams = ownerOfTeams ?? [],
        super(userType: UserType.coach);

  factory Coach.fromJson(String docId, Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value.map((e) => e.toString()));
      if (value is Map) return value.values.map((e) => e.toString()).toList();
      return [];
    }

    return Coach(
      id: docId,
      name: json['name'] as String? ?? 'Coach',
      lastName: json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      isAccountHolder: json['isAccountHolder'] as bool? ?? false,
      profilePicturePath: json['profilePicturePath'] as String?,
      photoUrl: json['photoUrl'] as String?,
      registerDate: AppUser.parseDateTime(json['registerDate']),
      updatedAt: AppUser.parseDateTime(json['updatedAt']),
      clubId: json['clubId'] as String?,
      memberOfTeams: parseStringList(json['memberOfTeams']),
      ownerOfTeams: parseStringList(json['ownerOfTeams']),
      creatorId: json['creatorId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'memberOfTeams': memberOfTeams,
      'ownerOfTeams': ownerOfTeams,
      'isAccountHolder': isAccountHolder,
      if (clubId != null) 'clubId': clubId,
    });
    return json;
  }

  @override
  Coach copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    UserType? userType,
    String? profilePicturePath,
    String? photoUrl,
    DateTime? registerDate,
    DateTime? updatedAt,
    String? clubId,
    List<String>? memberOfTeams,
    List<String>? ownerOfTeams,
    String? creatorId,
    bool? isAccountHolder,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      photoUrl: photoUrl ?? this.photoUrl,
      registerDate: registerDate ?? this.registerDate,
      updatedAt: updatedAt ?? this.updatedAt,
      clubId: clubId ?? this.clubId,
      isAccountHolder: isAccountHolder ?? this.isAccountHolder,
      memberOfTeams: memberOfTeams ?? this.memberOfTeams,
      ownerOfTeams: ownerOfTeams ?? this.ownerOfTeams,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}
