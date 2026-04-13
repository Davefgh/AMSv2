class Section {
  final int id;
  final String name;
  final int? capacity;
  final int? courseId;

  Section({
    required this.id,
    required this.name,
    this.capacity,
    this.courseId,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      capacity: json['capacity'],
      courseId: json['courseId'],
    );
  }
}
