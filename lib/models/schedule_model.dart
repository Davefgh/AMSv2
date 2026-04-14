class Schedule {
  final int id;

  /// API uses `timeIn` / `timeOut`. Older clients may send `timeStart` / `timeEnd`.
  final String timeIn;
  final String timeOut;

  /// API may return an int (1-7) or a string (e.g. "Monday").
  final int? dayOfWeek;
  final String? dayName;

  final int? subjectId;
  final int? classroomId;
  final int? sectionId;
  final int? instructorId;

  /// Nested objects returned by API.
  final Map<String, dynamic>? subject;
  final Map<String, dynamic>? classroom;
  final Map<String, dynamic>? section;
  final Map<String, dynamic>? instructor;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Schedule({
    required this.id,
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
  });

  String get displayDay {
    if (dayName != null && dayName!.trim().isNotEmpty) return dayName!;
    final d = dayOfWeek;
    if (d == null) return '';
    return _dayNameFromInt(d);
  }

  String get subjectName => (subject?['name'] as String?)?.trim() ?? '';
  String get sectionName => (section?['name'] as String?)?.trim() ?? '';
  String get classroomName => (classroom?['name'] as String?)?.trim() ?? '';

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final dynamic day = json['dayOfWeek'];
    final int? dayInt = day is int ? day : int.tryParse('$day');
    final String? dayStr = day is String ? day : null;

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

    Map<String, dynamic>? readMap(String key) {
      final v = json[key];
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    return Schedule(
      id: readInt('id') ?? 0,
      timeIn: readTime('timeIn', 'timeStart'),
      timeOut: readTime('timeOut', 'timeEnd'),
      dayOfWeek: dayInt,
      dayName: dayStr,
      subjectId: readInt('subjectId'),
      classroomId: readInt('classroomId'),
      sectionId: readInt('sectionId'),
      instructorId: readInt('instructorId'),
      subject: readMap('subject'),
      classroom: readMap('classroom'),
      section: readMap('section'),
      instructor: readMap('instructor'),
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'dayOfWeek': dayOfWeek ?? dayName,
      if (subjectId != null) 'subjectId': subjectId,
      if (classroomId != null) 'classroomId': classroomId,
      if (sectionId != null) 'sectionId': sectionId,
      if (instructorId != null) 'instructorId': instructorId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (subject != null) 'subject': subject,
      if (classroom != null) 'classroom': classroom,
      if (section != null) 'section': section,
      if (instructor != null) 'instructor': instructor,
    };
  }
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
