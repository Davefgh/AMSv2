import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import '../models/user_profile.dart';
import '../models/app_user.dart';
import '../models/instructor_model.dart';
import '../models/student_model.dart';
import '../models/section_model.dart';
import '../models/subject_model.dart';
import '../models/enrollment_model.dart';
import '../models/schedule_model.dart';
import '../models/course_model.dart';
import '../models/classroom_model.dart';
import '../models/health_status.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';

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
  static const String baseUrl = AppConstants.apiBaseUrl;
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

  Future<Section> createSection(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/sections', data);
      return Section.fromJson(response);
    } catch (e) {
      _logger.e('createSection Error: $e');
      rethrow;
    }
  }

  Future<void> updateSection(int id, Map<String, dynamic> data) async {
    try {
      await put('/api/sections/$id', data);
    } catch (e) {
      _logger.e('updateSection Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSection(int id) async {
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

  Future<void> updateSubject(int id, Map<String, dynamic> data) async {
    try {
      await patch('/api/subjects/$id', data);
    } catch (e) {
      _logger.e('updateSubject Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
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
        return response.map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getCourses Error: $e');
      rethrow;
    }
  }

  Future<Course> getCourse(int id) async {
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

  Future<void> updateCourse(int id, Map<String, dynamic> data) async {
    try {
      await put('/api/Course/$id', data);
    } catch (e) {
      _logger.e('updateCourse Error: $e');
      rethrow;
    }
  }

  Future<void> deleteCourse(int id) async {
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

  Future<Classroom> getClassroom(int id) async {
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

  Future<void> updateClassroom(int id, Map<String, dynamic> data) async {
    try {
      await patch('/api/classrooms/$id', data);
    } catch (e) {
      _logger.e('updateClassroom Error: $e');
      rethrow;
    }
  }

  Future<void> deleteClassroom(int id) async {
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

  Future<void> dropEnrollment(int id) async {
    try {
      await patch('/api/StudentEnrollment/$id/drop', {});
    } catch (e) {
      _logger.e('dropEnrollment Error: $e');
      rethrow;
    }
  }

  Future<void> reenrollStudent(int id) async {
    try {
      await patch('/api/StudentEnrollment/$id/reenroll', {});
    } catch (e) {
      _logger.e('reenrollStudent Error: $e');
      rethrow;
    }
  }

  Future<List<Enrollment>> getEnrollmentsByStudent(int studentId) async {
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

  Future<List<Student>> getStudentsBySection(int sectionId) async {
    try {
      final response =
          await get('/api/StudentEnrollment/section/$sectionId/students');
      if (response is List) {
        return response.map((s) => Student.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      _logger.e('getStudentsBySection Error: $e');
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

  Future<Instructor> getInstructor(int id) async {
    try {
      final response = await get('/api/instructors/$id');
      return Instructor.fromJson(response);
    } catch (e) {
      _logger.e('getInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> updateInstructor(int id, Map<String, dynamic> data) async {
    try {
      await patch('/api/instructors/$id', data);
    } catch (e) {
      _logger.e('updateInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> deleteInstructor(int id) async {
    try {
      await delete('/api/instructors/$id');
    } catch (e) {
      _logger.e('deleteInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> softDeleteInstructor(int id) async {
    try {
      await patch('/api/instructors/$id/soft-delete', {});
    } catch (e) {
      _logger.e('softDeleteInstructor Error: $e');
      rethrow;
    }
  }

  Future<void> restoreInstructor(int id) async {
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

  Future<Student> getStudent(int id) async {
    try {
      final response = await get('/api/students/$id');
      return Student.fromJson(response);
    } catch (e) {
      _logger.e('getStudent Error: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    try {
      await patch('/api/students/$id', data);
    } catch (e) {
      _logger.e('updateStudent Error: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      await delete('/api/students/$id');
    } catch (e) {
      _logger.e('deleteStudent Error: $e');
      rethrow;
    }
  }

  Future<void> softDeleteStudent(int id) async {
    try {
      await patch('/api/students/$id/soft-delete', {});
    } catch (e) {
      _logger.e('softDeleteStudent Error: $e');
      rethrow;
    }
  }

  Future<void> restoreStudent(int id) async {
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

  Future<dynamic> getAdminDataTemplate(String entity) async {
    try {
      return await get('/api/admin-data/$entity/template');
    } catch (e) {
      _logger.e('getAdminDataTemplate Error: $e');
      rethrow;
    }
  }

  Future<dynamic> getAdminDataExport(String entity) async {
    try {
      return await get('/api/admin-data/$entity/export');
    } catch (e) {
      _logger.e('getAdminDataExport Error: $e');
      rethrow;
    }
  }

  Future<dynamic> postAdminDataImportPreview(
      String entity, Map<String, dynamic> body) async {
    try {
      return await post('/api/admin-data/$entity/import-preview', body);
    } catch (e) {
      _logger.e('postAdminDataImportPreview Error: $e');
      rethrow;
    }
  }

  Future<dynamic> postAdminDataImport(
      String entity, Map<String, dynamic> body) async {
    try {
      return await post('/api/admin-data/$entity/import', body);
    } catch (e) {
      _logger.e('postAdminDataImport Error: $e');
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

  Future<Schedule> getSchedule(int id) async {
    try {
      final response = await get('/api/schedules/$id');
      return Schedule.fromJson(response);
    } catch (e) {
      _logger.e('getSchedule Error: $e');
      rethrow;
    }
  }

  Future<List<Schedule>> getSchedulesBySection(int sectionId) async {
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

  Future<List<Schedule>> getSchedulesByInstructorAll(int instructorId) async {
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

  Future<void> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      await patch('/api/schedules/$id', data);
    } catch (e) {
      _logger.e('updateSchedule Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await delete('/api/schedules/$id');
    } catch (e) {
      _logger.e('deleteSchedule Error: $e');
      rethrow;
    }
  }

  // --- QR Code Methods ---

  Future<Map<String, dynamic>> generateQrCode(int sessionId) async {
    try {
      final String uniqueId = const Uuid().v4();
      final response = await post('/api/QrCode/generate', {
        'SessionId': sessionId,
        'ExpirationMinutes': 60,
        'MaxUsage': null,
        'UniqueHash': uniqueId,
      });
      return response as Map<String, dynamic>;
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

  // --- Attendance APIs ---

  Future<AttendanceResponse> getAttendances({
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await get('/api/attendance?pageNumber=$pageNumber&pageSize=$pageSize');
      return AttendanceResponse.fromJson(response);
    } catch (e) {
      _logger.e('getAttendances Error: $e');
      rethrow;
    }
  }

  Future<AttendanceRecord> getAttendanceById(int id) async {
    try {
      final response = await get('/api/attendance/$id');
      return AttendanceRecord.fromJson(response);
    } catch (e) {
      _logger.e('getAttendanceById Error: $e');
      rethrow;
    }
  }

  Future<AttendanceRecord> createAttendance(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/attendance', data);
      return AttendanceRecord.fromJson(response);
    } catch (e) {
      _logger.e('createAttendance Error: $e');
      rethrow;
    }
  }

  Future<void> updateAttendance(int id, Map<String, dynamic> data) async {
    try {
      await put('/api/attendance/$id', data);
    } catch (e) {
      _logger.e('updateAttendance Error: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      await delete('/api/attendance/$id');
    } catch (e) {
      _logger.e('deleteAttendance Error: $e');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getAttendanceByStudent(int studentId) async {
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

  Future<List<AttendanceRecord>> getAttendanceBySession(int sessionId) async {
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

  Future<ClassSession> getSessionById(int id) async {
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

  Future<void> deleteSession(int id) async {
    try {
      await delete('/api/sessions/$id');
    } catch (e) {
      _logger.e('deleteSession Error: $e');
      rethrow;
    }
  }

  Future<void> updateSessionRoom(int id, String roomName) async {
    try {
      await patch('/api/sessions/$id/room', {'room': roomName});
    } catch (e) {
      _logger.e('updateSessionRoom Error: $e');
      rethrow;
    }
  }

  Future<void> startSession(int id) async {
    try {
      await patch('/api/sessions/$id/start', {});
    } catch (e) {
      _logger.e('startSession Error: $e');
      rethrow;
    }
  }

  Future<void> endSession(int id) async {
    try {
      await patch('/api/sessions/$id/end', {});
    } catch (e) {
      _logger.e('endSession Error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = StorageService.getString('accessToken');
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

  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('GET Error: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('POST Error: $e');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('PATCH Error: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('PUT Error: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      _logger.e('DELETE Error: $e');
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.trim();
      if (body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Unknown error';
      Map<String, List<String>> fieldErrors = {};

      try {
        final body = response.body.trim();
        if (body.isNotEmpty) {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic>) {
            errorMessage = decoded['title'] ?? decoded['message'] ?? response.body;

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
        errorMessage = response.body.isNotEmpty ? response.body : response.reasonPhrase ?? 'Unknown error';
      }

      throw ApiException(
        response.statusCode,
        errorMessage,
        fieldErrors: fieldErrors,
      );
    }
  }
}
