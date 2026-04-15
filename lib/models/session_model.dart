class ClassSession {
  final int id;
  final int scheduleId;
  final String status;
  final DateTime? sessionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String subjectCode;
  final String subjectName;
  final String sectionName;
  final String scheduledRoomName;
  final String? actualRoom;
  final String? cutoff;

  ClassSession({
    this.id = 0,
    required this.scheduleId,
    required this.status,
    this.sessionDate,
    this.createdAt,
    this.updatedAt,
    this.subjectCode = '',
    this.subjectName = '',
    this.sectionName = '',
    this.scheduledRoomName = '',
    this.actualRoom,
    this.cutoff,
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

    return ClassSession(
      id: json['id'] ?? 0,
      scheduleId: json['scheduleId'] ?? 0,
      status: json['status'] ?? 'not_started',
      sessionDate: parseDate(json['sessionDate']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      sectionName: json['sectionName'] ?? '',
      scheduledRoomName: json['scheduledRoomName'] ?? '',
      actualRoom: json['actualRoom'] ?? json['room'],
      cutoff: json['cutoff'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'scheduleId': scheduleId,
      'status': status,
      if (sessionDate != null) 'sessionDate': sessionDate!.toIso8601String(),
      if (actualRoom != null) 'actualRoom': actualRoom,
      if (cutoff != null) 'cutoff': cutoff,
    };
  }
}
