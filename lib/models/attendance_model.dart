class AttendanceRecord {
  final int id;
  final int studentId;
  final int sessionId;
  final String status;
  final String? notes;
  final DateTime? checkInTime;

  AttendanceRecord({
    this.id = 0,
    required this.studentId,
    required this.sessionId,
    required this.status,
    this.notes,
    this.checkInTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    return AttendanceRecord(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? json['StudentId'] ?? 0,
      sessionId: json['sessionId'] ?? json['SessionId'] ?? 0,
      status: json['status'] ?? json['Status'] ?? 'Unknown',
      notes: json['notes'] ?? json['Notes'],
      checkInTime: parseDate(json['checkInTime'] ?? json['CheckInTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'studentId': studentId,
      'sessionId': sessionId,
      'status': status,
      if (notes != null) 'notes': notes,
      if (checkInTime != null) 'checkInTime': checkInTime!.toIso8601String(),
    };
  }
}

class AttendanceResponse {
  final List<AttendanceRecord> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  AttendanceResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      items: (json['items'] as List?)
              ?.map((e) => AttendanceRecord.fromJson(e))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalPages: json['totalPages'] ?? 0,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}
