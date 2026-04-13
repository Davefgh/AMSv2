class Enrollment {
  final int id;
  final int studentId;
  final int sectionId;
  final int subjectId;
  final String enrollmentType;
  final String academicYear;
  final String semester;
  
  // Optional display fields often returned by check/view endpoints
  final String? studentName;
  final String? sectionName;
  final String? subjectName;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.sectionId,
    required this.subjectId,
    required this.enrollmentType,
    required this.academicYear,
    required this.semester,
    this.studentName,
    this.sectionName,
    this.subjectName,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      sectionId: json['sectionId'] ?? 0,
      subjectId: json['subjectId'] ?? 0,
      enrollmentType: json['enrollmentType'] ?? 'Regular',
      academicYear: json['academicYear'] ?? '',
      semester: json['semester'] ?? '',
      studentName: json['studentName'] ?? (json['student'] != null ? '${json['student']['firstname']} ${json['student']['lastname']}' : null),
      sectionName: json['sectionName'] ?? (json['section'] != null ? json['section']['name'] : null),
      subjectName: json['subjectName'] ?? (json['subject'] != null ? json['subject']['name'] : null),
    );
  }
}
