import '../utils/id_utils.dart';

class Student {
  final String id;
  final String firstname;
  final String lastname;
  final bool isRegular;
  final String userId;
  final String sectionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Student({
    this.id = '',
    required this.firstname,
    required this.lastname,
    required this.isRegular,
    required this.userId,
    required this.sectionId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  String get fullName => '$firstname $lastname';

  /// Returns true if this student has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      isRegular: json['isRegular'] ?? false,
      userId: json['userId'] ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'isRegular': isRegular,
      'userId': userId,
      if (sectionId.isNotEmpty) 'sectionId': sectionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
