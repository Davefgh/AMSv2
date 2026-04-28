import '../utils/id_utils.dart';

class Schedule {
  final String id;

  /// API uses `timeIn` / `timeOut`. Older clients may send `timeStart` / `timeEnd`.
  final String timeIn;
  final String timeOut;

  /// API may return an int (1-7) or a string (e.g. "Monday").
  final int? dayOfWeek;
  final String? dayName;

  final String? subjectId;
  final String? classroomId;
  final String? sectionId;
  final String? instructorId;

  /// Nested objects returned by API.
  final Map<String, dynamic>? subject;
  final Map<String, dynamic>? classroom;
  final Map<String, dynamic>? section;
  final Map<String, dynamic>? instructor;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? attendanceCutoffMinutes;

  const Schedule({
    this.id = '',
    required this.timeIn,
    required this.timeOut,
    this.dayOfWeek,
    this.dayName,
    this.subjectId,
    this.classroomId,
    this.sectionId,
    this.instructorId,
    this.subject,
    this.classroom,
    this.section,
    this.instructor,
    this.createdAt,
    this.updatedAt,
    this.attendanceCutoffMinutes,
  });

  String get displayDay {
    if (dayName != null && dayName!.trim().isNotEmpty) return dayName!;
    final d = dayOfWeek;
    if (d == null) return '';
    return _dayNameFromInt(d);
  }

  String get subjectName => (subject?['name'] as String?)?.trim() ?? '';
  String get subjectCode =>
      (subject?['subjectCode'] as String?)?.trim() ??
      (subject?['code'] as String?)?.trim() ??
      '';
  String get sectionName => (section?['name'] as String?)?.trim() ?? '';
  String get classroomName => (classroom?['name'] as String?)?.trim() ?? '';

  /// Returns true if this schedule has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final dynamic day = json['dayOfWeek'];
    int? dayInt = day is int ? day : int.tryParse('$day');
    final String? dayStr = day is String ? day : null;

    // If dayInt is still null, try to derive it from dayName
    if (dayInt == null && dayStr != null) {
      dayInt = _dayIntFromName(dayStr);
    }

    String readTime(String primary, String fallback) {
      final v = (json[primary] ?? json[fallback])?.toString();
      return v ?? '';
    }

    DateTime? readDate(String key) {
      final v = json[key];
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? readInt(String key) {
      final v = json[key];
      if (v is int) return v;
      return int.tryParse('$v');
    }

    String? readString(String key) {
      final v = json[key];
      return v?.toString();
    }

    Map<String, dynamic>? readMap(String key) {
      final v = json[key];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    return Schedule(
      id: readString('id') ?? '',
      timeIn: readTime('timeIn', 'timeStart'),
      timeOut: readTime('timeOut', 'timeEnd'),
      dayOfWeek: dayInt,
      dayName: dayStr,
      subjectId: readString('subjectId') ?? (readMap('subject')?['id'] ?? readMap('subject')?['subjectId'] ?? readMap('subject')?['subject_id'])?.toString(),
      classroomId: readString('classroomId') ?? (readMap('classroom')?['id'] ?? readMap('classroom')?['classroomId'])?.toString(),
      sectionId: readString('sectionId') ?? (readMap('section')?['id'] ?? readMap('section')?['sectionId'] ?? readMap('section')?['section_id'])?.toString(),
      instructorId: readString('instructorId') ?? (readMap('instructor')?['id'] ?? readMap('instructor')?['instructorId'])?.toString(),
      subject: readMap('subject'),
      classroom: readMap('classroom'),
      section: readMap('section'),
      instructor: readMap('instructor'),
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
      attendanceCutoffMinutes: readInt('attendanceCutoffMinutes'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'dayOfWeek': dayOfWeek ?? dayName,
      if (subjectId != null && subjectId!.isNotEmpty) 'subjectId': subjectId,
      if (classroomId != null && classroomId!.isNotEmpty)
        'classroomId': classroomId,
      if (sectionId != null && sectionId!.isNotEmpty) 'sectionId': sectionId,
      if (instructorId != null && instructorId!.isNotEmpty)
        'instructorId': instructorId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (subject != null) 'subject': subject,
      if (classroom != null) 'classroom': classroom,
      if (section != null) 'section': section,
      if (instructor != null) 'instructor': instructor,
      if (attendanceCutoffMinutes != null)
        'attendanceCutoffMinutes': attendanceCutoffMinutes,
    };
  }
}

int? _dayIntFromName(String name) {
  final n = name.trim().toLowerCase();
  if (n.contains('mon')) return 1;
  if (n.contains('tue')) return 2;
  if (n.contains('wed')) return 3;
  if (n.contains('thu')) return 4;
  if (n.contains('fri')) return 5;
  if (n.contains('sat')) return 6;
  if (n.contains('sun')) return 7;
  return null;
}

String _dayNameFromInt(int day) {
  switch (day) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    case 7:
      return 'Sunday';
    default:
      return 'Day $day';
  }
}
