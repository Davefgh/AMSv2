class Instructor {
  final int id;
  final String firstname;
  final String lastname;
  final String? email;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Instructor({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.email,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  String get fullName => '$firstname $lastname';

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] as String?,
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
