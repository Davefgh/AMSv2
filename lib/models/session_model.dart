class ClassSession {
  final int id;
  final int scheduleId;
  final String status;
  final DateTime? sessionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final DateTime? attendanceCutOff;
  final String subjectCode;
  final String subjectName;
  final String sectionName;
  final String scheduledRoomName;
  final String? actualRoomName;
  final String scheduledTimeIn;
  final String scheduledTimeOut;
  final int? startedBy;
  final String? startedByName;
  final int? endedBy;
  final String? endedByName;
  final String? rowVersion;
  final String? description;

  ClassSession({
    this.id = 0,
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
    this.sectionName = '',
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
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    int? parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return ClassSession(
      id: json['id'] ?? 0,
      scheduleId: json['scheduleId'] ?? 0,
      status: json['status'] ?? 'not_started',
      sessionDate: parseDate(json['sessionDate']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      actualStartTime: parseDate(json['actualStartTime']),
      actualEndTime: parseDate(json['actualEndTime']),
      attendanceCutOff: parseDate(json['attendanceCutOff']),
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      sectionName: json['sectionName'] ?? '',
      scheduledRoomName: json['scheduledRoomName'] ?? '',
      actualRoomName: json['actualRoomName'] ?? json['actualRoom'] ?? json['room'],
      scheduledTimeIn: json['scheduledTimeIn'] ?? json['timeIn'] ?? '',
      scheduledTimeOut: json['scheduledTimeOut'] ?? json['timeOut'] ?? '',
      startedBy: parseInt(json['startedBy']),
      startedByName: json['startedByName'],
      endedBy: parseInt(json['endedBy']),
      endedByName: json['endedByName'],
      rowVersion: json['rowVersion'],
      description: json['description'] ?? json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'scheduleId': scheduleId,
      'status': status,
      if (sessionDate != null) 'sessionDate': sessionDate!.toIso8601String(),
      if (actualRoomName != null) 'actualRoomName': actualRoomName,
      if (rowVersion != null) 'rowVersion': rowVersion,
      if (description != null) 'description': description,
    };
  }
}



