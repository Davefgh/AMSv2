class Section {
  final int id;
  final String name;
  final int capacity;

  Section({
    required this.id,
    required this.name,
    required this.capacity,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
    );
  }
}
