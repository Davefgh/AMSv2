class Student {
  final int id;
  final String firstname;
  final String lastname;
  final bool isRegular;
  final String userId;
  final int sectionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Student({
    required this.id,
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

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      isRegular: json['isRegular'] ?? false,
      userId: json['userId'] ?? '',
      sectionId: json['sectionId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
