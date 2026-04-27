import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../utils/constants.dart';
import '../utils/id_utils.dart';
import 'storage_service.dart';
import 'notification_hub_service.dart';
import '../models/user_profile.dart';
import '../models/app_user.dart';
import '../models/instructor_model.dart';
import '../models/student_model.dart';
import '../models/section_model.dart';
import '../models/subject_model.dart';
import '../models/enrollment_model.dart';
import '../models/schedule_model.dart';
import '../models/course_model.dart';
import '../models/student_subject_detail.dart';
import '../models/classroom_model.dart';
import '../models/health_status.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';
import '../models/fingerprint_model.dart';
import '../main.dart' show navigatorKey;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  ApiException(this.statusCode, this.message, {this.fieldErrors = const {}});

  @override
  String toString() {
    if (fieldErrors.isNotEmpty) {
      return 'API Error ($statusCode): $message\nValidation errors: $fieldErrors';
    }
    return 'API Error ($statusCode): $message';
  }
}

class ApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;
  final Logger _logger = Logger();

  Future<List<Section>> getSections() async {
    try {
      final response = await get('/api/sections');
      if (response is List) {
        return response.map((s) => Section.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getSections Error: $e');
      rethrow;
    }
  }

  Future<List<Student>> getStudentsBySection(String sectionId) async {
    validateId(sectionId, 'Section');
    try {
      final allStudents = await getStudents();
      return allStudents.where((s) => s.sectionId == sectionId).toList();
    } catch (e) {
      _logger.e('getStudentsBySection Error: $e');
      rethrow;
    }
  }

  Future<Section> createSection(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/sections', data);
      return Section.fromJson(response);
    } catch (e) {
      _logger.e('createSection Error: $e');
      rethrow;
    }
  }

  Future<void> updateSection(String id, Map<String, dynamic> data) async {
    validateId(id, 'Section');
    try {
      await put('/api/sections/$id', data);
    } catch (e) {
      _logger.e('updateSection Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSection(String id) async {
    validateId(id, 'Section');
    try {
      await delete('/api/sections/$id');
    } catch (e) {
      _logger.e('deleteSection Error: $e');
      rethrow;
    }
  }

  Future<List<Subject>> getSubjects() async {
    try {
      final response = await get('/api/subjects');
      if (response is List) {
        return response.map((s) => Subject.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getSubjects Error: $e');
      rethrow;
    }
  }

  Future<Subject> createSubject(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/subjects', data);
      return Subject.fromJson(response);
    } catch (e) {
      _logger.e('createSubject Error: $e');
      rethrow;
    }
  }

  Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    validateId(id, 'Subject');
    try {
      await patch('/api/subjects/$id', data);
    } catch (e) {
      _logger.e('updateSubject Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(String id) async {
    validateId(id, 'Subject');
    try {
      await delete('/api/subjects/$id');
    } catch (e) {
      _logger.e('deleteSubject Error: $e');
      rethrow;
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await get('/api/Course');
      if (response is List) {
        return response
            .map((c) => Course.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('getCourses Error: $e');
      rethrow;
    }
  }

  Future<Course> getCourse(String id) async {
    validateId(id, 'Course');
    try {
      final response = await get('/api/Course/$id');
      return Course.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getCourse Error: $e');
      rethrow;
    }
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/Course', data);
      return Course.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('createCourse Error: $e');
      rethrow;
    }
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    validateId(id, 'Course');
    try {
      await put('/api/Course/$id', data);
    } catch (e) {
      _logger.e('updateCourse Error: $e');
      rethrow;
    }
  }

  Future<void> deleteCourse(String id) async {
    validateId(id, 'Course');
    try {
      await delete('/api/Course/$id');
    } catch (e) {
      _logger.e('deleteCourse Error: $e');
      rethrow;
    }
  }

  Future<List<Classroom>> getClassrooms() async {
    try {
      final response = await get('/api/classrooms');
      if (response is List) {
        return response
            .map((c) => Classroom.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('getClassrooms Error: $e');
      rethrow;
    }
  }

  Future<Classroom> getClassroom(String id) async {
    validateId(id, 'Classroom');
    try {
      final response = await get('/api/classrooms/$id');
      return Classroom.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getClassroom Error: $e');
      rethrow;
    }
  }

  Future<Classroom> createClassroom(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/classrooms', data);
      return Classroom.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('createClassroom Error: $e');
      rethrow;
    }
  }

  Future<void> updateClassroom(String id, Map<String, dynamic> data) async {
    validateId(id, 'Classroom');
    try {
      await patch('/api/classrooms/$id', data);
    } catch (e) {
      _logger.e('updateClassroom Error: $e');
      rethrow;
    }
  }

  Future<void> deleteClassroom(String id) async {
    validateId(id, 'Classroom');
    try {
      await delete('/api/classrooms/$id');
    } catch (e) {
      _logger.e('deleteClassroom Error: $e');
      rethrow;
    }
  }

  Future<void> enrollStudent(Map<String, dynamic> data) async {
    try {
      await post('/api/StudentEnrollment/enroll', data);
    } catch (e) {
      _logger.e('enrollStudent Error: $e');
      rethrow;
    }
  }

  Future<List<Enrollment>> getEnrollments() async {
    try {
      final response = await get('/api/StudentEnrollment/check');
      if (response is List) {
        return response.map((e) => Enrollment.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getEnrollments Error: $e');
      rethrow;
    }
  }

  Future<void> dropEnrollment(String id) async {
    validateId(id, 'Enrollment');
    try {
      await patch('/api/StudentEnrollment/$id/drop', {});
    } catch (e) {
      _logger.e('dropEnrollment Error: $e');
      rethrow;
    }
  }

  Future<void> reenrollStudent(String id) async {
    validateId(id, 'Enrollment');
    try {
      await patch('/api/StudentEnrollment/$id/reenroll', {});
    } catch (e) {
      _logger.e('reenrollStudent Error: $e');
      rethrow;
    }
  }

  Future<List<Enrollment>> getEnrollmentsByStudent(String studentId) async {
    validateId(studentId, 'Student');
    try {
      final response = await get('/api/StudentEnrollment/student/$studentId');
      if (response is List) {
        return response.map((e) => Enrollment.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getEnrollmentsByStudent Error: $e');
      rethrow;
    }
  }

  Future<List<Instructor>> getInstructors({bool includeDeleted = false}) async {
    try {
      final endpoint =
          includeDeleted ? '/api/instructors?status=all' : '/api/instructors';
      final response = await get(endpoint);
      if (response is List) {
        return response.map((i) => Instructor.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getInstructors Error: $e');
      rethrow;
    }
  }

  Future<Instructor> getInstructorProfile() async {
    try {
      final response = await get('/api/instructors/profile');
      return Instructor.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getInstructorProfile Error: $e');
      rethrow;
    }
  }

  Future<Instructor> getInstructor(String id) async {
    validateId(id, 'Instructor');
    try {
      final response = await get('/api/instructors/$id');
      return Instructor.fromJson(response);
    } catch (e) {
      _logger.e('getInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> updateInstructor(String id, Map<String, dynamic> data) async {
    validateId(id, 'Instructor');
    try {
      await patch('/api/instructors/$id', data);
    } catch (e) {
      _logger.e('updateInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> deleteInstructor(String id) async {
    validateId(id, 'Instructor');
    try {
      await delete('/api/instructors/$id');
    } catch (e) {
      _logger.e('deleteInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> softDeleteInstructor(String id) async {
    validateId(id, 'Instructor');
    try {
      await patch('/api/instructors/$id/soft-delete', {});
    } catch (e) {
      _logger.e('softDeleteInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> restoreInstructor(String id) async {
    validateId(id, 'Instructor');
    try {
      await patch('/api/instructors/$id/restore', {});
    } catch (e) {
      _logger.e('restoreInstructor Error: $e');
      rethrow;
    }
  }

  Future<List<Instructor>> searchInstructorsByName(String name) async {
    try {
      final response = await get('/api/instructors/search/name?name=$name');
      if (response is List) {
        return response.map((i) => Instructor.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('searchInstructorsByName Error: $e');
      rethrow;
    }
  }

  Future<List<Student>> getStudents({bool includeDeleted = false}) async {
    try {
      final endpoint =
          includeDeleted ? '/api/students?status=all' : '/api/students';
      final response = await get(endpoint);
      if (response is List) {
        return response.map((s) => Student.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getStudents Error: $e');
      rethrow;
    }
  }

  Future<Student> getStudent(String id) async {
    validateId(id, 'Student');
    try {
      final response = await get('/api/students/$id');
      return Student.fromJson(response);
    } catch (e) {
      _logger.e('getStudent Error: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    validateId(id, 'Student');
    try {
      await patch('/api/students/$id', data);
    } catch (e) {
      _logger.e('updateStudent Error: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    validateId(id, 'Student');
    try {
      await delete('/api/students/$id');
    } catch (e) {
      _logger.e('deleteStudent Error: $e');
      rethrow;
    }
  }

  Future<void> softDeleteStudent(String id) async {
    validateId(id, 'Student');
    try {
      await patch('/api/students/$id/soft-delete', {});
    } catch (e) {
      _logger.e('softDeleteStudent Error: $e');
      rethrow;
    }
  }

  Future<void> restoreStudent(String id) async {
    validateId(id, 'Student');
    try {
      await patch('/api/students/$id/restore', {});
    } catch (e) {
      _logger.e('restoreStudent Error: $e');
      rethrow;
    }
  }

  Future<List<Student>> searchStudentsByName(String name) async {
    try {
      final response = await get('/api/students/search/name?name=$name');
      if (response is List) {
        return response.map((s) => Student.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('searchStudentsByName Error: $e');
      rethrow;
    }
  }

  Future<List<Student>> searchStudentsByEmail(String email) async {
    try {
      final response = await get('/api/students/search/email?email=$email');
      if (response is List) {
        return response.map((s) => Student.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('searchStudentsByEmail Error: $e');
      rethrow;
    }
  }

  Future<List<AppUser>> getUsers() async {
    try {
      final response = await get('/api/users');
      if (response is List) {
        return response.map((u) => AppUser.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getUsers Error: $e');
      rethrow;
    }
  }

  Future<HealthStatusResponse> getHealth() async {
    try {
      final response = await get('/api/health');
      return HealthStatusResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getHealth Error: $e');
      rethrow;
    }
  }

  Future<HealthStatusResponse> getHealthReady() async {
    try {
      final response = await get('/api/health/ready');
      return HealthStatusResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getHealthReady Error: $e');
      rethrow;
    }
  }

  Future<HealthStatusResponse> getHealthLive() async {
    try {
      final response = await get('/api/health/live');
      return HealthStatusResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getHealthLive Error: $e');
      rethrow;
    }
  }

  Future<HealthStatusResponse> getHealthDataIntegrity() async {
    try {
      final response = await get('/api/health/data-integrity');
      return HealthStatusResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getHealthDataIntegrity Error: $e');
      rethrow;
    }
  }

  Future<List<Schedule>> getSchedules() async {
    try {
      final response = await get('/api/schedules');
      if (response is List) {
        return response.map((s) => Schedule.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getSchedules Error: $e');
      rethrow;
    }
  }

  Future<List<Schedule>> getMySchedules() async {
    try {
      final response = await get('/api/schedules/my-schedules');
      if (response is List) {
        return response.map((s) => Schedule.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getMySchedules Error: $e');
      rethrow;
    }
  }

  Future<Schedule> getSchedule(String id) async {
    validateId(id, 'Schedule');
    try {
      final response = await get('/api/schedules/$id');
      return Schedule.fromJson(response);
    } catch (e) {
      _logger.e('getSchedule Error: $e');
      rethrow;
    }
  }

  Future<List<Schedule>> getSchedulesBySection(String sectionId) async {
    validateId(sectionId, 'Section');
    try {
      final response = await get('/api/schedules/by-section/$sectionId');
      if (response is List) {
        return response.map((s) => Schedule.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getSchedulesBySection Error: $e');
      rethrow;
    }
  }

  Future<List<Schedule>> getSchedulesByInstructorAll(
      String instructorId) async {
    validateId(instructorId, 'Instructor');
    try {
      final response = await get('/api/schedules/$instructorId/all');
      if (response is List) {
        return response.map((s) => Schedule.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getSchedulesByInstructorAll Error: $e');
      rethrow;
    }
  }

  Future<Schedule> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/schedules', data);
      return Schedule.fromJson(response);
    } catch (e) {
      _logger.e('createSchedule Error: $e');
      rethrow;
    }
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    validateId(id, 'Schedule');
    try {
      await patch('/api/schedules/$id', data);
    } catch (e) {
      _logger.e('updateSchedule Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    validateId(id, 'Schedule');
    try {
      await delete('/api/schedules/$id');
    } catch (e) {
      _logger.e('deleteSchedule Error: $e');
      rethrow;
    }
  }

  // --- QR Code Methods ---

  Future<Map<String, dynamic>> generateQrCode(String sessionId, {int? expirationMinutes, int? maxUsage, String? qrHash}) async {
    validateId(sessionId, 'Session');
    try {
      final response = await post('/api/QrCode/generate', {
        'SessionId': sessionId,
        'ExpirationMinutes': expirationMinutes ?? 15,
        if (maxUsage != null) 'MaxUsage': maxUsage,
        if (qrHash != null) 'UniqueHash': qrHash,
      });
      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('generateQrCode Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQrCodeByHash(String hash) async {
    try {
      final response = await get('/api/QrCode/hash/$hash');
      return response as Map<String, dynamic>;
    } catch (e) {
      _logger.e('getQrCodeByHash Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getQrScanHistory(String qrId) async {
    validateId(qrId, 'QR Code');
    try {
      final response = await get('/api/QrCode/$qrId/scan-history');
      return response as List<dynamic>? ?? [];
    } catch (e) {
      _logger.e('getQrScanHistory Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNotificationPreference() async {
    try {
      final response =
          await get('/api/NotificationPreference/realtime-checkin');
      return response as Map<String, dynamic>;
    } catch (e) {
      _logger.e('getNotificationPreference Error: $e');
      rethrow;
    }
  }

  Future<void> updateNotificationPreference(bool enabled) async {
    try {
      await put('/api/NotificationPreference/realtime-checkin', {
        'enabled': enabled,
      });
    } catch (e) {
      _logger.e('updateNotificationPreference Error: $e');
      rethrow;
    }
  }

  Future<List<StudentSubjectDetail>> getStudentSubjects() async {
    try {
      final response = await get('/api/students/my-subjects');
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              StudentSubjectDetail.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('getStudentSubjects Error: $e');
      rethrow;
    }
  }

  // --- Attendance APIs ---

  Future<AttendanceResponse> getAttendances({
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await get(
          '/api/attendance?pageNumber=$pageNumber&pageSize=$pageSize');
      return AttendanceResponse.fromJson(response);
    } catch (e) {
      _logger.e('getAttendances Error: $e');
      rethrow;
    }
  }

  Future<AttendanceRecord> getAttendanceById(String id) async {
    validateId(id, 'Attendance');
    try {
      final response = await get('/api/attendance/$id');
      return AttendanceRecord.fromJson(response);
    } catch (e) {
      _logger.e('getAttendanceById Error: $e');
      rethrow;
    }
  }

  Future<AttendanceRecord> createAttendance(Map<String, dynamic> data) async {
    // Validate IDs in the data payload
    if (data['studentId'] != null) {
      validateId(data['studentId'].toString(), 'Student');
    }
    if (data['sessionId'] != null) {
      validateId(data['sessionId'].toString(), 'Session');
    }
    try {
      final response = await post('/api/attendance', data);
      return AttendanceRecord.fromJson(response);
    } catch (e) {
      _logger.e('createAttendance Error: $e');
      rethrow;
    }
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    validateId(id, 'Attendance');
    try {
      await put('/api/attendance/$id', data);
    } catch (e) {
      _logger.e('updateAttendance Error: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendance(String id) async {
    validateId(id, 'Attendance');
    try {
      await delete('/api/attendance/$id');
    } catch (e) {
      _logger.e('deleteAttendance Error: $e');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getAttendanceByStudent(
      String studentId) async {
    validateId(studentId, 'Student');
    try {
      final response = await get('/api/attendance/student/$studentId');
      if (response is List) {
        return response.map((e) => AttendanceRecord.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getAttendanceByStudent Error: $e');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getAttendanceBySession(
      String sessionId) async {
    validateId(sessionId, 'Session');
    try {
      final response = await get('/api/attendance/session/$sessionId');
      if (response is List) {
        return response.map((e) => AttendanceRecord.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getAttendanceBySession Error: $e');
      rethrow;
    }
  }

  Future<dynamic> getAttendanceSummary() async {
    try {
      return await get('/api/attendance/summary');
    } catch (e) {
      _logger.e('getAttendanceSummary Error: $e');
      rethrow;
    }
  }

  // --- Session APIs ---

  Future<List<ClassSession>> getSessions() async {
    try {
      final response = await get('/api/sessions');
      if (response is List) {
        return response.map((s) => ClassSession.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getSessions Error: $e');
      rethrow;
    }
  }

  Future<List<ClassSession>> getMySessions() async {
    try {
      final response = await get('/api/sessions/my-sessions');
      if (response is List) {
        return response.map((s) => ClassSession.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getMySessions Error: $e');
      rethrow;
    }
  }

  Future<ClassSession> getSessionById(String id) async {
    validateId(id, 'Session');
    try {
      final response = await get('/api/sessions/$id');
      return ClassSession.fromJson(response);
    } catch (e) {
      _logger.e('getSessionById Error: $e');
      rethrow;
    }
  }

  Future<ClassSession> createSession(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/sessions', data);
      return ClassSession.fromJson(response);
    } catch (e) {
      _logger.e('createSession Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSession(String id,
      {required String reason, required String rowVersion}) async {
    validateId(id, 'Session');
    try {
      await delete('/api/sessions/$id',
          body: {'reason': reason, 'rowVersion': rowVersion});
    } catch (e) {
      _logger.e('deleteSession Error: $e');
      rethrow;
    }
  }

  Future<void> updateSessionRoom(String id,
      {required String actualRoomId, required String rowVersion}) async {
    validateId(id, 'Session');
    try {
      await patch('/api/sessions/$id/room', {
        'ActualRoomId': actualRoomId,
        'RowVersion': rowVersion,
      });
    } catch (e) {
      _logger.e('updateSessionRoom Error: $e');
      rethrow;
    }
  }

  Future<void> startSession(String id,
      {String? actualRoomId,
      int? attendanceCutoffMinutes,
      required String rowVersion}) async {
    validateId(id, 'Session');
    try {
      await patch('/api/sessions/$id/start', {
        if (actualRoomId != null) 'actualRoomId': actualRoomId,
        if (attendanceCutoffMinutes != null)
          'attendanceCutoffMinutes': attendanceCutoffMinutes,
        'rowVersion': rowVersion,
      });
    } catch (e) {
      _logger.e('startSession Error: $e');
      rethrow;
    }
  }

  Future<void> endSession(String id,
      {String? description, required String rowVersion}) async {
    validateId(id, 'Session');
    try {
      await patch('/api/sessions/$id/end', {
        if (description != null) 'description': description,
        'rowVersion': rowVersion,
      });
    } catch (e) {
      _logger.e('endSession Error: $e');
      rethrow;
    }
  }

  Future<Student> getStudentProfile() async {
    try {
      final me = await getMe();

      if (me.role.toLowerCase() != 'student' || me.studentProfile == null) {
        throw ApiException(
            404, 'Your account is not linked to any Student record.');
      }

      final sp = me.studentProfile!;
      return Student(
        id: sp.id,
        firstname: sp.firstname ?? '',
        lastname: sp.lastname ?? '',
        isRegular: sp.isRegular,
        userId: me.userId,
        sectionId: sp.sectionId,
        createdAt: sp.createdAt,
        updatedAt: sp.updatedAt,
      );
    } catch (e) {
      _logger.e('getStudentProfile Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> scanQrCode({
    required String qrHash,
    required String studentId,
  }) async {
    validateId(studentId, 'Student');
    try {
      final response = await post('/api/QrCode/scan', {
        'QrHash': qrHash,
        'StudentId': studentId,
      });
      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('scanQrCode Error: $e');
      rethrow;
    }
  }


  Future<List<dynamic>> getQrCodesBySession(String sessionId) async {
    validateId(sessionId, 'Session');
    try {
      final response = await get('/api/QrCode/session/$sessionId');
      if (response is List) return response;
      if (response is Map) return [response];
      return [];
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) return [];
      _logger.e('getQrCodesBySession Error: $e');
      rethrow;
    }
  }

  Future<void> revokeQrCode(String sessionId) async {
    validateId(sessionId, 'Session');
    try {
      await post('/api/QrCode/revoke', {'SessionId': sessionId});
    } catch (e) {
      _logger.e('revokeQrCode Error: $e');
      rethrow;
    }
  }

  // --- Fingerprint APIs ---

  /// POST /api/Fingerprint/enrollment-sessions
  /// Creates an enrollment session for a student on a device.
  Future<EnrollmentSession> createFingerprintEnrollmentSession({
    required String studentId,
    required String deviceId,
  }) async {
    validateId(studentId, 'Student');
    validateId(deviceId, 'Device');
    try {
      final response = await post('/api/Fingerprint/enrollment-sessions', {
        'studentId': studentId,
        'deviceId': deviceId,
      });
      return EnrollmentSession.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('createFingerprintEnrollmentSession Error: $e');
      rethrow;
    }
  }

  /// GET /api/Fingerprint/devices/{deviceId}/enrollment-session
  /// Gets the active enrollment session for a device.
  Future<EnrollmentSession?> getDeviceEnrollmentSession(String deviceId) async {
    validateId(deviceId, 'Device');
    try {
      final response =
          await get('/api/Fingerprint/devices/$deviceId/enrollment-session');
      if (response == null) return null;
      return EnrollmentSession.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logger.e('getDeviceEnrollmentSession Error: $e');
      rethrow;
    }
  }

  /// DELETE /api/Fingerprint/{fingerprintId}
  Future<void> deleteFingerprint(String fingerprintId) async {
    validateId(fingerprintId, 'Fingerprint');
    try {
      await delete('/api/Fingerprint/$fingerprintId');
    } catch (e) {
      _logger.e('deleteFingerprint Error: $e');
      rethrow;
    }
  }

  /// POST /api/Fingerprint/devices/enrollment-result
  Future<Map<String, dynamic>> submitFingerprintEnrollmentResult(
      Map<String, dynamic> data) async {
    try {
      final response =
          await post('/api/Fingerprint/devices/enrollment-result', data);
      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('submitFingerprintEnrollmentResult Error: $e');
      rethrow;
    }
  }

  /// POST /api/Fingerprint/devices/scan
  Future<Map<String, dynamic>> scanFingerprint(
      Map<String, dynamic> data) async {
    try {
      final response = await post('/api/Fingerprint/devices/scan', data);
      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('scanFingerprint Error: $e');
      rethrow;
    }
  }

  /// GET /api/Fingerprint/student/{studentId}
  Future<List<FingerprintInfo>> getFingerprintsByStudent(
      String studentId) async {
    validateId(studentId, 'Student');
    try {
      final response = await get('/api/Fingerprint/student/$studentId');
      if (response is List) {
        return response.map((f) => FingerprintInfo.fromJson(f)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getFingerprintsByStudent Error: $e');
      rethrow;
    }
  }

  /// GET /api/Fingerprint/device/{deviceId}
  Future<List<FingerprintInfo>> getFingerprintsByDevice(String deviceId) async {
    validateId(deviceId, 'Device');
    try {
      final response = await get('/api/Fingerprint/device/$deviceId');
      if (response is List) {
        return response.map((f) => FingerprintInfo.fromJson(f)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getFingerprintsByDevice Error: $e');
      rethrow;
    }
  }

  /// GET /api/Fingerprint
  Future<List<FingerprintInfo>> getAllFingerprints() async {
    try {
      final response = await get('/api/Fingerprint');
      if (response is List) {
        return response.map((f) => FingerprintInfo.fromJson(f)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getAllFingerprints Error: $e');
      rethrow;
    }
  }

  /// GET /api/Fingerprint/check/{studentId}
  Future<Map<String, dynamic>> checkStudentFingerprint(String studentId) async {
    validateId(studentId, 'Student');
    try {
      final response = await get('/api/Fingerprint/check/$studentId');
      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('checkStudentFingerprint Error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = StorageService.getString(AppConstants.storageKeyToken);
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserProfile> getMe() async {
    try {
      final response = await get('/api/account/me');
      return UserProfile.fromJson(response);
    } catch (e) {
      _logger.e('getMe Error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await patch('/api/account/profile', data);
    } catch (e) {
      _logger.e('updateProfile Error: $e');
      rethrow;
    }
  }

  /// Updates teacher account profile
  /// 
  /// Parameters:
  /// - [firstname]: Optional first name
  /// - [lastname]: Optional last name
  /// - [email]: Optional email
  /// - [currentPassword]: Required if changing password
  /// - [newPassword]: New password (requires currentPassword)
  /// - [confirmNewPassword]: Confirm new password (must match newPassword)
  Future<void> updateTeacherProfile({
    String? firstname,
    String? lastname,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? confirmNewPassword,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (firstname != null) data['firstname'] = firstname;
      if (lastname != null) data['lastname'] = lastname;
      if (email != null) data['email'] = email;
      if (currentPassword != null) data['currentPassword'] = currentPassword;
      if (newPassword != null) data['newPassword'] = newPassword;
      if (confirmNewPassword != null) data['confirmNewPassword'] = confirmNewPassword;
      
      await patch('/api/account/profile', data);
    } catch (e) {
      _logger.e('updateTeacherProfile Error: $e');
      rethrow;
    }
  }

  // Prevents concurrent refresh attempts
  bool _isRefreshing = false;

  /// Tries to refresh the access token using the stored refresh token.
  /// Returns true if successful, false otherwise.
  Future<bool> tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken =
          StorageService.getString(AppConstants.storageKeyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/account/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'] ?? data['token'];
        final newRefresh = data['refreshToken'];
        if (newToken != null) {
          await StorageService.setString(
              AppConstants.storageKeyToken, newToken);
          if (newRefresh != null) {
            await StorageService.setString(
                AppConstants.storageKeyRefreshToken, newRefresh);
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Checks if the current token is still valid via /api/account/check.
  /// Returns true if valid, false if expired/invalid.
  Future<bool> checkToken() async {
    try {
      final token = StorageService.getString(AppConstants.storageKeyToken);
      if (token == null || token.isEmpty) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/api/account/check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.trim();
      if (body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      final urlStr = response.request?.url.toString().toLowerCase() ?? '';
      _logger.w('401 Unauthorized detected for: $urlStr');

      // Don't logout if we're actually trying to login or refresh
      // Logout will be handled by _withRefresh after refresh attempt fails
      if (!urlStr.contains('login') && !urlStr.contains('refresh')) {
        _logger.i(
            '401 on non-auth endpoint - will attempt refresh then logout if fails');
        throw ApiException(401, 'Session expired. Please log in again.');
      }
    }

    String errorMessage = 'Unknown error';
    Map<String, List<String>> fieldErrors = {};

    try {
      final body = response.body.trim();
      if (body.isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          errorMessage =
              decoded['title'] ?? decoded['message'] ?? response.body;
          if (decoded['errors'] != null) {
            final errorsObj = decoded['errors'] as Map<String, dynamic>;
            errorsObj.forEach((key, value) {
              if (value is List) {
                fieldErrors[key] = value.map((e) => e.toString()).toList();
              } else if (value is String) {
                fieldErrors[key] = [value];
              }
            });
          }
        } else {
          errorMessage = body;
        }
      }
    } catch (_) {
      errorMessage = response.body.isNotEmpty
          ? response.body
          : response.reasonPhrase ?? 'Unknown error';
    }

    throw ApiException(response.statusCode, errorMessage,
        fieldErrors: fieldErrors);
  }

  /// Wraps a request so that on a 401 it attempts a token refresh and retries once.
  Future<dynamic> _withRefresh(Future<dynamic> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      // Only attempt refresh if it's a 401
      // Note: _handleResponse already verified this is not a login/refresh endpoint
      if (e.statusCode == 401) {
        // Attempt token refresh
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          return await request();
        }

        // Refresh failed - logout and navigate to login
        _logger.i('Token refresh failed, logging out');
        await _handleLogout();
      }
      rethrow;
    }
  }

  Future<dynamic> get(String endpoint) async {
    return _withRefresh(() async {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    return _withRefresh(() async {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    return _withRefresh(() async {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return _withRefresh(() async {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    return _withRefresh(() async {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    });
  }

  Future<void> _handleLogout() async {
    await NotificationHubService().stop();
    await StorageService.remove(AppConstants.storageKeyToken);
    await StorageService.remove(AppConstants.storageKeyRefreshToken);
    await StorageService.remove(AppConstants.storageKeyUser);
    await StorageService.remove(AppConstants.storageKeyRole);
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }
}
