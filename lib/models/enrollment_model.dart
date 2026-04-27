import '../utils/id_utils.dart';

class Enrollment {
  final String id;
  final String studentId;
  final String sectionId;
  final String subjectId;
  final String enrollmentType;
  final String academicYear;
  final String semester;

  // Optional display fields often returned by check/view endpoints
  final String? studentName;
  final String? sectionName;
  final String? subjectName;
  final String? subjectCode;

  Enrollment({
    this.id = '',
    required this.studentId,
    required this.sectionId,
    required this.subjectId,
    required this.enrollmentType,
    required this.academicYear,
    required this.semester,
    this.studentName,
    this.sectionName,
    this.subjectName,
    this.subjectCode,
  });

  /// Returns true if this enrollment has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      enrollmentType: json['enrollmentType'] ?? 'Regular',
      academicYear: json['academicYear'] ?? '',
      semester: json['semester'] ?? '',
      studentName: json['studentName'] ??
          (json['student'] != null
              ? '${json['student']['firstname']} ${json['student']['lastname']}'
              : null),
      sectionName: json['sectionName'] ??
          (json['section'] != null ? json['section']['name'] : null),
      subjectName: json['subjectName'] ??
          (json['subject'] != null ? json['subject']['name'] : null),
      subjectCode: json['subjectCode'] ??
          (json['subject'] != null ? json['subject']['code'] : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (studentId.isNotEmpty) 'studentId': studentId,
      if (sectionId.isNotEmpty) 'sectionId': sectionId,
      if (subjectId.isNotEmpty) 'subjectId': subjectId,
      'enrollmentType': enrollmentType,
      'academicYear': academicYear,
      'semester': semester,
    };
  }
}
