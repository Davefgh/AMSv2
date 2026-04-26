import '../utils/id_utils.dart';

class Classroom {
  final String id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  Classroom({
    this.id = '',
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true if this classroom has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}
