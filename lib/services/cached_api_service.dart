import 'api_service.dart';
import 'cache_service.dart';
import '../models/section_model.dart';
import '../models/subject_model.dart';
import '../models/course_model.dart';
import '../models/classroom_model.dart';
import '../models/instructor_model.dart';
import '../models/student_model.dart';
import '../models/schedule_model.dart';
import '../models/session_model.dart';
import '../models/enrollment_model.dart';
import '../models/student_subject_detail.dart';
import '../models/fingerprint_model.dart';
import '../models/attendance_model.dart';
import '../models/health_status.dart';

/// Cached wrapper around ApiService for static and semi-static data
class CachedApiService {
  final ApiService _api = ApiService();
  final CacheService _cache = CacheService();

  // ==================== SECTIONS ====================

  Future<List<Section>> getSections({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.sections);
    }

    return _cache.getOrFetch<List<Section>>(
      key: CacheKeys.sections,
      fetcher: () => _api.getSections(),
      fromJson: (json) => (json as List)
          .map((s) => Section.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.long,
    );
  }

  Future<List<Student>> getStudentsBySection(
    String sectionId, {
    bool forceRefresh = false,
  }) async {
    final key = CacheKeys.sectionStudents(sectionId);
    if (forceRefresh) {
      await _cache.invalidate(key);
    }

    return _cache.getOrFetch<List<Student>>(
      key: key,
      fetcher: () => _api.getStudentsBySection(sectionId),
      fromJson: (json) => (json as List)
          .map((s) => Student.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.medium,
    );
  }

  // Invalidate section-related caches after mutations
  Future<Section> createSection(Map<String, dynamic> data) async {
    final result = await _api.createSection(data);
    await _cache.invalidate(CacheKeys.sections);
    return result;
  }

  Future<void> updateSection(String id, Map<String, dynamic> data) async {
    await _api.updateSection(id, data);
    await _cache.invalidate(CacheKeys.sections);
  }

  Future<void> deleteSection(String id) async {
    await _api.deleteSection(id);
    await _cache.invalidate(CacheKeys.sections);
    await _cache.invalidatePattern('section_');
  }

  // ==================== SUBJECTS ====================

  Future<List<Subject>> getSubjects({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.subjects);
    }

    return _cache.getOrFetch<List<Subject>>(
      key: CacheKeys.subjects,
      fetcher: () => _api.getSubjects(),
      fromJson: (json) => (json as List)
          .map((s) => Subject.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.long,
    );
  }

  Future<Subject> createSubject(Map<String, dynamic> data) async {
    final result = await _api.createSubject(data);
    await _cache.invalidate(CacheKeys.subjects);
    return result;
  }

  Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    await _api.updateSubject(id, data);
    await _cache.invalidate(CacheKeys.subjects);
  }

  Future<void> deleteSubject(String id) async {
    await _api.deleteSubject(id);
    await _cache.invalidate(CacheKeys.subjects);
  }

  // ==================== COURSES ====================

  Future<List<Course>> getCourses({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.courses);
    }

    return _cache.getOrFetch<List<Course>>(
      key: CacheKeys.courses,
      fetcher: () => _api.getCourses(),
      fromJson: (json) => (json as List)
          .map((c) => Course.fromJson(c as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((c) => c.toJson()).toList(),
      config: CacheConfig.long,
    );
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    final result = await _api.createCourse(data);
    await _cache.invalidate(CacheKeys.courses);
    return result;
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    await _api.updateCourse(id, data);
    await _cache.invalidate(CacheKeys.courses);
  }

  Future<void> deleteCourse(String id) async {
    await _api.deleteCourse(id);
    await _cache.invalidate(CacheKeys.courses);
  }

  // ==================== CLASSROOMS ====================

  Future<List<Classroom>> getClassrooms({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.classrooms);
    }

    return _cache.getOrFetch<List<Classroom>>(
      key: CacheKeys.classrooms,
      fetcher: () => _api.getClassrooms(),
      fromJson: (json) => (json as List)
          .map((c) => Classroom.fromJson(c as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((c) => c.toJson()).toList(),
      config: CacheConfig.long,
    );
  }

  Future<Classroom> createClassroom(Map<String, dynamic> data) async {
    final result = await _api.createClassroom(data);
    await _cache.invalidate(CacheKeys.classrooms);
    return result;
  }

  Future<void> updateClassroom(String id, Map<String, dynamic> data) async {
    await _api.updateClassroom(id, data);
    await _cache.invalidate(CacheKeys.classrooms);
  }

  Future<void> deleteClassroom(String id) async {
    await _api.deleteClassroom(id);
    await _cache.invalidate(CacheKeys.classrooms);
  }

  // ==================== INSTRUCTORS ====================

  Future<List<Instructor>> getInstructors({
    bool includeDeleted = false,
    bool forceRefresh = false,
  }) async {
    final key =
        includeDeleted ? '${CacheKeys.instructors}_all' : CacheKeys.instructors;
    if (forceRefresh) {
      await _cache.invalidate(key);
    }

    return _cache.getOrFetch<List<Instructor>>(
      key: key,
      fetcher: () => _api.getInstructors(includeDeleted: includeDeleted),
      fromJson: (json) => (json as List)
          .map((i) => Instructor.fromJson(i as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((i) => i.toJson()).toList(),
      config: CacheConfig.medium,
    );
  }

  Future<Instructor> getInstructorProfile({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.instructorProfile);
    }

    return _cache.getOrFetch<Instructor>(
      key: CacheKeys.instructorProfile,
      fetcher: () => _api.getInstructorProfile(),
      fromJson: (json) => Instructor.fromJson(json as Map<String, dynamic>),
      toJson: (data) => data.toJson(),
      config: CacheConfig.medium,
    );
  }

  Future<void> updateInstructor(String id, Map<String, dynamic> data) async {
    await _api.updateInstructor(id, data);
    await _cache.invalidatePattern('instructor');
  }

  Future<void> deleteInstructor(String id) async {
    await _api.deleteInstructor(id);
    await _cache.invalidatePattern('instructor');
  }

  // ==================== STUDENTS ====================

  Future<List<Student>> getStudents({
    bool includeDeleted = false,
    bool forceRefresh = false,
  }) async {
    final key =
        includeDeleted ? '${CacheKeys.students}_all' : CacheKeys.students;
    if (forceRefresh) {
      await _cache.invalidate(key);
    }

    return _cache.getOrFetch<List<Student>>(
      key: key,
      fetcher: () => _api.getStudents(includeDeleted: includeDeleted),
      fromJson: (json) => (json as List)
          .map((s) => Student.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.medium,
    );
  }

  Future<Student> getStudentProfile({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.studentProfile);
    }

    return _cache.getOrFetch<Student>(
      key: CacheKeys.studentProfile,
      fetcher: () => _api.getStudentProfile(),
      fromJson: (json) => Student.fromJson(json as Map<String, dynamic>),
      toJson: (data) => data.toJson(),
      config: CacheConfig.medium,
    );
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _api.updateStudent(id, data);
    await _cache.invalidatePattern('student');
  }

  Future<void> deleteStudent(String id) async {
    await _api.deleteStudent(id);
    await _cache.invalidatePattern('student');
  }

  // ==================== SCHEDULES ====================

  Future<List<Schedule>> getMySchedules({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.mySchedules);
    }

    return _cache.getOrFetch<List<Schedule>>(
      key: CacheKeys.mySchedules,
      fetcher: () => _api.getMySchedules(),
      fromJson: (json) => (json as List)
          .map((s) => Schedule.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.short,
    );
  }

  Future<List<Schedule>> getSchedulesBySection(
    String sectionId, {
    bool forceRefresh = false,
  }) async {
    final key = CacheKeys.sectionSchedules(sectionId);
    if (forceRefresh) {
      await _cache.invalidate(key);
    }

    return _cache.getOrFetch<List<Schedule>>(
      key: key,
      fetcher: () => _api.getSchedulesBySection(sectionId),
      fromJson: (json) => (json as List)
          .map((s) => Schedule.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.medium,
    );
  }

  Future<Schedule> createSchedule(Map<String, dynamic> data) async {
    final result = await _api.createSchedule(data);
    await _cache.invalidatePattern('schedule');
    return result;
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    await _api.updateSchedule(id, data);
    await _cache.invalidatePattern('schedule');
  }

  Future<void> deleteSchedule(String id) async {
    await _api.deleteSchedule(id);
    await _cache.invalidatePattern('schedule');
  }

  // ==================== SESSIONS ====================

  Future<List<ClassSession>> getMySessions({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.mySessions);
    }

    return _cache.getOrFetch<List<ClassSession>>(
      key: CacheKeys.mySessions,
      fetcher: () => _api.getMySessions(),
      fromJson: (json) => (json as List)
          .map((s) => ClassSession.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.veryShort,
    );
  }

  // Session mutations invalidate session caches
  Future<ClassSession> createSession(Map<String, dynamic> data) async {
    final result = await _api.createSession(data);
    await _cache.invalidatePattern('session');
    return result;
  }

  Future<void> startSession(
    String id, {
    String? actualRoomId,
    int? attendanceCutoffMinutes,
    required String rowVersion,
  }) async {
    await _api.startSession(
      id,
      actualRoomId: actualRoomId,
      attendanceCutoffMinutes: attendanceCutoffMinutes,
      rowVersion: rowVersion,
    );
    await _cache.invalidatePattern('session');
  }

  Future<void> endSession(
    String id, {
    String? description,
    required String rowVersion,
  }) async {
    await _api.endSession(id, description: description, rowVersion: rowVersion);
    await _cache.invalidatePattern('session');
  }

  Future<void> deleteSession(
    String id, {
    required String reason,
    required String rowVersion,
  }) async {
    await _api.deleteSession(id, reason: reason, rowVersion: rowVersion);
    await _cache.invalidatePattern('session');
  }

  // ==================== ENROLLMENTS ====================

  Future<List<Enrollment>> getEnrollmentsByStudent(
    String studentId, {
    bool forceRefresh = false,
  }) async {
    final key = CacheKeys.studentEnrollments(studentId);
    if (forceRefresh) {
      await _cache.invalidate(key);
    }

    return _cache.getOrFetch<List<Enrollment>>(
      key: key,
      fetcher: () => _api.getEnrollmentsByStudent(studentId),
      fromJson: (json) => (json as List)
          .map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((e) => e.toJson()).toList(),
      config: CacheConfig.medium,
    );
  }

  Future<void> enrollStudent(Map<String, dynamic> data) async {
    await _api.enrollStudent(data);
    await _cache.invalidatePattern('enrollment');
  }

  Future<void> dropEnrollment(String id) async {
    await _api.dropEnrollment(id);
    await _cache.invalidatePattern('enrollment');
  }

  // ==================== STUDENT SUBJECTS ====================

  Future<List<StudentSubjectDetail>> getStudentSubjects({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.mySubjects);
    }

    return _cache.getOrFetch<List<StudentSubjectDetail>>(
      key: CacheKeys.mySubjects,
      fetcher: () => _api.getStudentSubjects(),
      fromJson: (json) => (json as List)
          .map((s) => StudentSubjectDetail.fromJson(s as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((s) => s.toJson()).toList(),
      config: CacheConfig.short,
    );
  }

  // ==================== FINGERPRINTS ====================

  Future<List<FingerprintInfo>> getFingerprintsByStudent(
    String studentId, {
    bool forceRefresh = false,
  }) async {
    final key = CacheKeys.studentFingerprints(studentId);
    if (forceRefresh) {
      await _cache.invalidate(key);
    }

    return _cache.getOrFetch<List<FingerprintInfo>>(
      key: key,
      fetcher: () => _api.getFingerprintsByStudent(studentId),
      fromJson: (json) => (json as List)
          .map((f) => FingerprintInfo.fromJson(f as Map<String, dynamic>))
          .toList(),
      toJson: (data) => data.map((f) => f.toJson()).toList(),
      config: CacheConfig.medium,
    );
  }

  Future<void> deleteFingerprint(String fingerprintId) async {
    await _api.deleteFingerprint(fingerprintId);
    await _cache.invalidatePattern('fingerprint');
  }

  // ==================== HEALTH ====================

  Future<HealthStatusResponse> getHealth({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await _cache.invalidate(CacheKeys.health);
    }

    return _cache.getOrFetch<HealthStatusResponse>(
      key: CacheKeys.health,
      fetcher: () => _api.getHealth(),
      fromJson: (json) =>
          HealthStatusResponse.fromJson(json as Map<String, dynamic>),
      toJson: (data) => data.toJson(),
      config: CacheConfig.veryShort,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Preload commonly used static data on app start
  Future<void> preloadStaticData() async {
    await Future.wait([
      _cache.preload<List<Section>>(
        key: CacheKeys.sections,
        fetcher: () => _api.getSections(),
        fromJson: (json) => (json as List)
            .map((s) => Section.fromJson(s as Map<String, dynamic>))
            .toList(),
        toJson: (data) => data.map((s) => s.toJson()).toList(),
        config: CacheConfig.long,
      ),
      _cache.preload<List<Subject>>(
        key: CacheKeys.subjects,
        fetcher: () => _api.getSubjects(),
        fromJson: (json) => (json as List)
            .map((s) => Subject.fromJson(s as Map<String, dynamic>))
            .toList(),
        toJson: (data) => data.map((s) => s.toJson()).toList(),
        config: CacheConfig.long,
      ),
      _cache.preload<List<Classroom>>(
        key: CacheKeys.classrooms,
        fetcher: () => _api.getClassrooms(),
        fromJson: (json) => (json as List)
            .map((c) => Classroom.fromJson(c as Map<String, dynamic>))
            .toList(),
        toJson: (data) => data.map((c) => c.toJson()).toList(),
        config: CacheConfig.long,
      ),
    ]);
  }

  /// Clear all caches (useful for logout)
  Future<void> clearAllCaches() async {
    await _cache.clearAll();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cache.getStats();
  }

  // ==================== PASS-THROUGH METHODS (No caching) ====================
  // These methods don't benefit from caching or are write operations

  // Direct API access for non-cacheable operations
  ApiService get api => _api;

  // Attendance operations (dynamic data)
  Future<AttendanceResponse> getAttendances({
    int pageNumber = 1,
    int pageSize = 50,
  }) =>
      _api.getAttendances(pageNumber: pageNumber, pageSize: pageSize);

  Future<AttendanceRecord> createAttendance(Map<String, dynamic> data) async {
    final result = await _api.createAttendance(data);
    await _cache.invalidatePattern('attendance');
    return result;
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    await _api.updateAttendance(id, data);
    await _cache.invalidatePattern('attendance');
  }

  // QR Code operations (dynamic, short-lived)
  Future<Map<String, dynamic>> generateQrCode(String sessionId) =>
      _api.generateQrCode(sessionId);

  Future<Map<String, dynamic>> scanQrCode({
    required String qrHash,
    required String studentId,
  }) =>
      _api.scanQrCode(qrHash: qrHash, studentId: studentId);

  // Fingerprint enrollment (dynamic)
  Future<EnrollmentSession> createFingerprintEnrollmentSession({
    required String studentId,
    required String deviceId,
  }) =>
      _api.createFingerprintEnrollmentSession(
        studentId: studentId,
        deviceId: deviceId,
      );

  Future<Map<String, dynamic>> submitFingerprintEnrollmentResult(
    Map<String, dynamic> data,
  ) =>
      _api.submitFingerprintEnrollmentResult(data);

  Future<EnrollmentSession> cancelEnrollmentSession(String sessionId) =>
      _api.cancelEnrollmentSession(sessionId);

  Future<Map<String, dynamic>> scanFingerprint(Map<String, dynamic> data) =>
      _api.scanFingerprint(data);
}
