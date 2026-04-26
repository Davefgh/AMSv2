class EnrollmentSession {
  final String? enrollmentSessionId;
  final String? studentId;
  final String? studentName;
  final String? deviceId;
  final int? assignedSensorFingerprintId;
  final String? status;
  final DateTime? expiresAt;
  final String? message;
  final bool success;

  EnrollmentSession({
    this.enrollmentSessionId,
    this.studentId,
    this.studentName,
    this.deviceId,
    this.assignedSensorFingerprintId,
    this.status,
    this.expiresAt,
    this.message,
    this.success = false,
  });

  factory EnrollmentSession.fromJson(Map<String, dynamic> json) {
    return EnrollmentSession(
      enrollmentSessionId: json['enrollmentSessionId'],
      studentId: json['studentId']?.toString(),
      studentName: json['studentName'],
      deviceId: json['deviceId'],
      assignedSensorFingerprintId: json['assignedSensorFingerprintId'],
      status: json['status'],
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      message: json['message'],
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (enrollmentSessionId != null)
        'enrollmentSessionId': enrollmentSessionId,
      if (studentId != null) 'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      if (deviceId != null) 'deviceId': deviceId,
      if (assignedSensorFingerprintId != null)
        'assignedSensorFingerprintId': assignedSensorFingerprintId,
      if (status != null) 'status': status,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (message != null) 'message': message,
      'success': success,
    };
  }
}

class FingerprintInfo {
  final String? id;
  final String? deviceId;
  final String? studentId;
  final String? studentName;
  final String? status;
  final DateTime? createdAt;

  FingerprintInfo({
    this.id,
    this.deviceId,
    this.studentId,
    this.studentName,
    this.status,
    this.createdAt,
  });

  factory FingerprintInfo.fromJson(Map<String, dynamic> json) {
    return FingerprintInfo(
      id: json['id']?.toString(),
      deviceId: json['deviceId'],
      studentId: json['studentId']?.toString(),
      studentName: json['studentName'],
      status: json['status'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (deviceId != null) 'deviceId': deviceId,
      if (studentId != null) 'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      if (status != null) 'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
