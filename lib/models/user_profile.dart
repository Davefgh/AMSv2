class UserProfile {
  final String userId;
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StudentProfileInfo? studentProfile;
  final InstructorProfileInfo? instructorProfile;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.studentProfile,
    this.instructorProfile,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      studentProfile: json['studentProfile'] != null
          ? StudentProfileInfo.fromJson(json['studentProfile'])
          : null,
      instructorProfile: json['instructorProfile'] != null
          ? InstructorProfileInfo.fromJson(json['instructorProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'studentProfile': studentProfile?.toJson(),
      'instructorProfile': instructorProfile?.toJson(),
    };
  }
}

class StudentProfileInfo {
  final String id;
  final String? firstname;
  final String? lastname;
  final bool isRegular;
  final String sectionId;
  final String sectionName;
  final String courseId;
  final String courseName;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentProfileInfo({
    this.id = '',
    this.firstname,
    this.lastname,
    required this.isRegular,
    required this.sectionId,
    required this.sectionName,
    required this.courseId,
    required this.courseName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentProfileInfo.fromJson(Map<String, dynamic> json) {
    return StudentProfileInfo(
      id: json['id']?.toString() ?? '',
      firstname: json['firstname'],
      lastname: json['lastname'],
      isRegular: json['isRegular'] ?? false,
      sectionId: json['sectionId']?.toString() ?? '',
      sectionName: json['sectionName'] ?? '',
      courseId: json['courseId']?.toString() ?? '',
      courseName: json['courseName'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'isRegular': isRegular,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'courseId': courseId,
      'courseName': courseName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class InstructorProfileInfo {
  final String id;
  final String? firstname;
  final String? lastname;
  final DateTime createdAt;
  final DateTime updatedAt;

  InstructorProfileInfo({
    this.id = '',
    this.firstname,
    this.lastname,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstructorProfileInfo.fromJson(Map<String, dynamic> json) {
    return InstructorProfileInfo(
      id: json['id']?.toString() ?? '',
      firstname: json['firstname'],
      lastname: json['lastname'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
