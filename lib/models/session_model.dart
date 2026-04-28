import '../utils/id_utils.dart';

class ClassSession {
  final String id;
  final String scheduleId;
  final String status;
  final DateTime? sessionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final DateTime? attendanceCutOff;
  final String subjectCode;
  final String subjectName;
  final String? subjectId;
  final String sectionName;
  final String? sectionId;
  final String scheduledRoomName;
  final String? actualRoomName;
  final String scheduledTimeIn;
  final String scheduledTimeOut;
  final String? startedBy;
  final String? startedByName;
  final String? endedBy;
  final String? endedByName;
  final String? rowVersion;
  final String? description;
  final String? offScheduleReason;

  ClassSession({
    this.id = '',
    required this.scheduleId,
    required this.status,
    this.sessionDate,
    this.createdAt,
    this.updatedAt,
    this.actualStartTime,
    this.actualEndTime,
    this.attendanceCutOff,
    this.subjectCode = '',
    this.subjectName = '',
    this.subjectId,
    this.sectionName = '',
    this.sectionId,
    this.scheduledRoomName = '',
    this.actualRoomName,
    this.scheduledTimeIn = '',
    this.scheduledTimeOut = '',
    this.startedBy,
    this.startedByName,
    this.endedBy,
    this.endedByName,
    this.rowVersion,
    this.description,
    this.offScheduleReason,
  });

  /// Returns true if this session has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    String? parseString(dynamic v) {
      if (v == null) return null;
      return v.toString();
    }

    return ClassSession(
      id: json['id']?.toString() ?? '',
      scheduleId: json['scheduleId']?.toString() ?? '',
      status: json['status'] ?? 'not_started',
      sessionDate: parseDate(json['sessionDate']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      actualStartTime: parseDate(json['actualStartTime']),
      actualEndTime: parseDate(json['actualEndTime']),
      attendanceCutOff: parseDate(json['attendanceCutOff']),
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectId: parseString(json['subjectId']),
      instructorName: json['instructorName'] ??
          json['instructorFullName'] ??
          (json['instructor'] is Map
              ? json['instructor']['fullName'] ?? json['instructor']['name']
              : (json['instructor'] is String ? json['instructor'] : null)) ??
          json['startedByName'],
      sectionName: json['sectionName'] ?? '',
      sectionId: parseString(json['sectionId']),
      scheduledRoomName: json['scheduledRoomName'] ?? '',
      actualRoomName:
          json['actualRoomName'] ?? json['actualRoom'] ?? json['room'],
      scheduledTimeIn: json['scheduledTimeIn'] ?? json['timeIn'] ?? '',
      scheduledTimeOut: json['scheduledTimeOut'] ?? json['timeOut'] ?? '',
      startedBy: parseString(json['startedById'] ?? json['startedBy']),
      startedByName: json['startedByName'],
      endedBy: parseString(json['endedById'] ?? json['endedBy']),
      endedByName: json['endedByName'],
      rowVersion: json['rowVersion'],
      description: json['description'] ?? json['notes'],
      offScheduleReason: json['offScheduleReason'] ?? json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (scheduleId.isNotEmpty) 'scheduleId': scheduleId,
      'status': status,
      if (sessionDate != null) 'sessionDate': sessionDate!.toIso8601String(),
      if (actualRoomName != null) 'actualRoomName': actualRoomName,
      if (rowVersion != null) 'rowVersion': rowVersion,
      if (description != null) 'description': description,
    };
  }
}
