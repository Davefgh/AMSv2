class Instructor {
  final int id;
  final String firstname;
  final String lastname;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Instructor({
    required this.id,
    required this.firstname,
    required this.lastname,
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
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
