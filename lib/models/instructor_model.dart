import '../utils/id_utils.dart';

class Instructor {
  final String id;
  final String firstname;
  final String lastname;
  final String? email;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Instructor({
    this.id = '',
    required this.firstname,
    required this.lastname,
    this.email,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  String get fullName => '$firstname $lastname';

  /// Returns true if this instructor has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id']?.toString() ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] as String?,
      userId: json['userId'] ?? '',
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
      if (email != null) 'email': email,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}
