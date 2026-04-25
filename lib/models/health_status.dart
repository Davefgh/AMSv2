/// Response shapes for `/api/health`, `/api/health/ready`, `/api/health/live`, `/api/health/data-integrity`.
class SoftDeleteInconsistencies {
  final int students;
  final int instructors;
  final int admins;

  SoftDeleteInconsistencies({
    required this.students,
    required this.instructors,
    required this.admins,
  });

  factory SoftDeleteInconsistencies.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SoftDeleteInconsistencies(students: 0, instructors: 0, admins: 0);
    }
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    return SoftDeleteInconsistencies(
      students: n('students'),
      instructors: n('instructors'),
      admins: n('admins'),
    );
  }
}

class DataIntegrityHealth {
  final int orphanedUserCount;
  final int totalSoftDeleteInconsistencies;
  final SoftDeleteInconsistencies softDeleteInconsistencies;
  final String? checkedAt;
  final bool isHealthy;
  final String status;

  DataIntegrityHealth({
    required this.orphanedUserCount,
    required this.totalSoftDeleteInconsistencies,
    required this.softDeleteInconsistencies,
    this.checkedAt,
    required this.isHealthy,
    required this.status,
  });

  factory DataIntegrityHealth.fromJson(Map<String, dynamic> json) {
    return DataIntegrityHealth(
      orphanedUserCount: (json['orphanedUserCount'] as num?)?.toInt() ?? 0,
      totalSoftDeleteInconsistencies:
          (json['totalSoftDeleteInconsistencies'] as num?)?.toInt() ?? 0,
      softDeleteInconsistencies: SoftDeleteInconsistencies.fromJson(
        json['softDeleteInconsistencies'] as Map<String, dynamic>?,
      ),
      checkedAt: json['checkedAt'] as String?,
      isHealthy: json['isHealthy'] as bool? ?? false,
      status: json['status'] as String? ?? '',
    );
  }
}

class DatabaseHealth {
  final String status;
  final bool connected;

  DatabaseHealth({required this.status, required this.connected});

  factory DatabaseHealth.fromJson(Map<String, dynamic> json) {
    return DatabaseHealth(
      status: json['status'] as String? ?? '',
      connected: json['connected'] as bool? ?? false,
    );
  }
}

class HealthStatusResponse {
  final String status;
  final String? timestamp;
  final String? service;
  final DatabaseHealth? database;
  final DataIntegrityHealth? dataIntegrity;

  HealthStatusResponse({
    required this.status,
    this.timestamp,
    this.service,
    this.database,
    this.dataIntegrity,
  });

  factory HealthStatusResponse.fromJson(Map<String, dynamic> json) {
    DatabaseHealth? db;
    final rawDb = json['database'];
    if (rawDb is Map<String, dynamic>) {
      db = DatabaseHealth.fromJson(rawDb);
    }

    DataIntegrityHealth? di;
    final rawDi = json['dataIntegrity'];
    if (rawDi is Map<String, dynamic>) {
      di = DataIntegrityHealth.fromJson(rawDi);
    }

    return HealthStatusResponse(
      status: json['status'] as String? ?? 'unknown',
      timestamp: json['timestamp'] as String?,
      service: json['service'] as String?,
      database: db,
      dataIntegrity: di,
    );
  }

  bool get overallHealthy {
    final s = status.toLowerCase();
    if (s != 'healthy') return false;
    if (database != null && !database!.connected) return false;
    if (dataIntegrity != null && !dataIntegrity!.isHealthy) return false;
    return true;
  }
}
