class Classroom {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  Classroom({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}
