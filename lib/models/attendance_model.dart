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
      status: json['status'] ?? 'absent',
      remarks: json['remarks'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      timeOut: json['timeOut'] != null ? DateTime.parse(json['timeOut']) : null,
    );
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
