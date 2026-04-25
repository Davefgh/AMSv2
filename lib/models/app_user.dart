class AppUser {
  final String userId;
  final String username;
  final String email;
  final String role;
  final UserProfileDetails? profile;

  AppUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.profile,
  });

  String get fullName {
    if (profile == null) return username;
    return '${profile!.firstname} ${profile!.lastname}'.trim();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Determine which profile is present
    Map<String, dynamic>? profileData;
    if (json['adminProfile'] != null) {
      profileData = json['adminProfile'];
    } else if (json['instructorProfile'] != null) {
      profileData = json['instructorProfile'];
    } else if (json['studentProfile'] != null) {
      profileData = json['studentProfile'];
    }

    return AppUser(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      profile:
          profileData != null ? UserProfileDetails.fromJson(profileData) : null,
    );
  }
}

class UserProfileDetails {
  final String id;
  final String firstname;
  final String lastname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  UserProfileDetails({
    this.id = '',
    required this.firstname,
    required this.lastname,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) {
    return UserProfileDetails(
      id: json['id']?.toString() ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
