import '../utils/id_utils.dart';

class Subject {
  final String id;
  final String name;
  final String code;

  Subject({
    this.id = '',
    required this.name,
    required this.code,
  });

  /// Returns true if this subject has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'code': code,
    };
  }
}
