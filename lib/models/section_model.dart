import '../utils/id_utils.dart';

class Section {
  final String id;
  final String name;
  final int? capacity;
  final String? courseId;

  Section({
    this.id = '',
    required this.name,
    this.capacity,
    this.courseId,
  });

  /// Returns true if this section has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'],
      courseId: json['courseId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      if (capacity != null) 'capacity': capacity,
      if (courseId != null && courseId!.isNotEmpty) 'courseId': courseId,
    };
  }
}
