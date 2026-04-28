import '../utils/id_utils.dart';

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String status;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? timeOut;

  AttendanceRecord({
    this.id = '',
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.timeOut,
  });

  /// Returns true if this attendance record has a valid ID
  bool get hasValidId => isValidId(id);

  /// Returns a display-friendly version of the ID (truncated if too long)
  String get displayId => id.length > 8 ? '${id.substring(0, 8)}...' : id;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'absent').toLowerCase(),
      remarks: json['remarks'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      timeOut: json['timeOut'] != null ? DateTime.parse(json['timeOut']) : null,
    );
  }

  static List<AttendanceRecord> listFromBackendResponse(dynamic response) {
    final List<dynamic> records;
    if (response is List) {
      records = response;
    } else if (response is Map<String, dynamic>) {
      records = response['attendanceRecords'] as List? ?? [];
    } else {
      records = [];
    }

    return records
        .map((record) =>
            AttendanceRecord.fromJson(record as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (sessionId.isNotEmpty) 'sessionId': sessionId,
      if (studentId.isNotEmpty) 'studentId': studentId,
      'status': status,
      'remarks': remarks,
      if (timeOut != null) 'timeOut': timeOut!.toIso8601String(),
    };
  }
}

class AttendanceSummary {
  final int totalSessions;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalExcused;
  final num attendanceRate;
  final String? averageCheckInTime;
  final String mostFrequentStatus;

  AttendanceSummary({
    required this.totalSessions,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalExcused,
    required this.attendanceRate,
    this.averageCheckInTime,
    required this.mostFrequentStatus,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalSessions: json['totalSessions'] ?? json['total'] ?? 0,
      totalPresent: json['totalPresent'] ?? json['presentCount'] ?? 0,
      totalLate: json['totalLate'] ?? json['lateCount'] ?? 0,
      totalAbsent: json['totalAbsent'] ?? json['absentCount'] ?? 0,
      totalExcused: json['totalExcused'] ?? json['excusedCount'] ?? 0,
      attendanceRate: json['attendanceRate'] ?? 0,
      averageCheckInTime: json['averageCheckInTime'],
      mostFrequentStatus: json['mostFrequentStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalPresent': totalPresent,
      'totalLate': totalLate,
      'totalAbsent': totalAbsent,
      'totalExcused': totalExcused,
      'attendanceRate': attendanceRate,
      'averageCheckInTime': averageCheckInTime,
      'mostFrequentStatus': mostFrequentStatus,
    };
  }
}

class AttendanceResponse {
  final List<AttendanceRecord> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  AttendanceResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<AttendanceRecord> itemsList =
        list.map((i) => AttendanceRecord.fromJson(i)).toList();

    return AttendanceResponse(
      items: itemsList,
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}
