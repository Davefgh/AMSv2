class AttendanceRecord {
  final int id;
  final int sessionId;
  final int studentId;
  final String status;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      sessionId: json['sessionId'] ?? 0,
      studentId: json['studentId'] ?? 0,
      status: json['status'] ?? 'absent',
      remarks: json['remarks'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status,
      'remarks': remarks,
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
    List<AttendanceRecord> itemsList = list.map((i) => AttendanceRecord.fromJson(i)).toList();

    return AttendanceResponse(
      items: itemsList,
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}
