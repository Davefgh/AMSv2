import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import '../models/user_profile.dart';
import '../models/app_user.dart';
import '../models/instructor_model.dart';
import '../models/student_model.dart';
import '../models/section_model.dart';
import '../models/subject_model.dart';
import '../models/enrollment_model.dart';

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
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
