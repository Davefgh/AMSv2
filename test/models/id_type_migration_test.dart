import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/models/student_model.dart';
import 'package:amsv2/models/instructor_model.dart';
import 'package:amsv2/models/session_model.dart';
import 'package:amsv2/models/attendance_model.dart';
import 'package:amsv2/models/enrollment_model.dart';
import 'package:amsv2/models/section_model.dart';
import 'package:amsv2/models/subject_model.dart';
import 'package:amsv2/models/course_model.dart';
import 'package:amsv2/models/classroom_model.dart';
import 'package:amsv2/models/schedule_model.dart';
import 'package:amsv2/models/user_profile.dart';
import 'package:amsv2/models/device_model.dart';

/// Bug Condition Exploration Test - Post-Fix Verification
///
/// This test validates that the ID type migration fix is working correctly.
/// After the fix, all models should successfully deserialize JSON with string IDs.
///
/// EXPECTED OUTCOME: All tests PASS - models successfully handle string IDs
///
/// This test encodes the expected behavior and validates the fix implementation.
void main() {
  group('Bug Condition Exploration - String ID Deserialization', () {
    test('Student model should deserialize with string ID', () {
      // Arrange - API response with string ID (UUID)
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'userId': 'user-123',
        'sectionId': 'section-456',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
        'isDeleted': false,
      };

      // Act
      final student = Student.fromJson(json);

      // Assert - Verify successful deserialization with string IDs
      expect(student.id, equals('550e8400-e29b-41d4-a716-446655440000'),
          reason: 'Student ID should be preserved as string');
      expect(student.sectionId, equals('section-456'),
          reason: 'Foreign key sectionId should be preserved as string');
      expect(student.firstname, equals('John'));
      expect(student.lastname, equals('Doe'));
    });

    test('Instructor model should deserialize with string ID', () {
      // Arrange - API response with string ID (UUID)
      final json = {
        'id': '660e8400-e29b-41d4-a716-446655440001',
        'firstname': 'Jane',
        'lastname': 'Smith',
        'email': 'jane.smith@example.com',
        'userId': 'user-456',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
        'isDeleted': false,
      };

      // Act
      final instructor = Instructor.fromJson(json);

      // Assert - Verify successful deserialization with string ID
      expect(instructor.id, equals('660e8400-e29b-41d4-a716-446655440001'),
          reason: 'Instructor ID should be preserved as string');
      expect(instructor.firstname, equals('Jane'));
      expect(instructor.lastname, equals('Smith'));
    });

    test('ClassSession model should preserve string ID values', () {
      // Arrange - API response with string IDs
      final json = {
        'id': 'session-123',
        'scheduleId': 'schedule-456',
        'status': 'active',
        'sessionDate': '2024-01-15T00:00:00Z',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
        'subjectCode': 'CS101',
        'subjectName': 'Computer Science',
        'sectionName': 'Section A',
        'scheduledRoomName': 'Room 101',
        'scheduledTimeIn': '08:00',
        'scheduledTimeOut': '10:00',
      };

      // Act
      final session = ClassSession.fromJson(json);

      // Assert - Verify string IDs are preserved (not converted to 0)
      expect(session.id, equals('session-123'),
          reason: 'Session ID should be preserved as string');
      expect(session.scheduleId, equals('schedule-456'),
          reason: 'Foreign key scheduleId should be preserved as string');
      expect(session.status, equals('active'));
    });

    test(
        'AttendanceRecord model should deserialize with string IDs (multiple foreign keys)',
        () {
      // Arrange - API response with string IDs
      final json = {
        'id': 'attendance-123',
        'sessionId': 'session-456',
        'studentId': 'student-789',
        'status': 'present',
        'remarks': 'On time',
        'createdAt': '2024-01-15T08:30:00Z',
        'updatedAt': '2024-01-15T08:30:00Z',
      };

      // Act
      final attendance = AttendanceRecord.fromJson(json);

      // Assert - Verify all string IDs are preserved
      expect(attendance.id, equals('attendance-123'),
          reason: 'Attendance ID should be preserved as string');
      expect(attendance.sessionId, equals('session-456'),
          reason: 'Foreign key sessionId should be preserved as string');
      expect(attendance.studentId, equals('student-789'),
          reason: 'Foreign key studentId should be preserved as string');
      expect(attendance.status, equals('present'));
    });

    test('Enrollment model should deserialize with string IDs', () {
      // Arrange - API response with string IDs
      final json = {
        'id': 'enrollment-123',
        'studentId': 'student-456',
        'sectionId': 'section-789',
        'subjectId': 'subject-012',
        'enrollmentType': 'Regular',
        'academicYear': '2024',
        'semester': 'First',
      };

      // Act
      final enrollment = Enrollment.fromJson(json);

      // Assert - Verify all string IDs are preserved
      expect(enrollment.id, equals('enrollment-123'),
          reason: 'Enrollment ID should be preserved as string');
      expect(enrollment.studentId, equals('student-456'),
          reason: 'Foreign key studentId should be preserved as string');
      expect(enrollment.sectionId, equals('section-789'),
          reason: 'Foreign key sectionId should be preserved as string');
    });

    test('Section model should deserialize with string IDs', () {
      // Arrange - API response with string IDs
      final json = {
        'id': 'section-123',
        'name': 'Section A',
        'capacity': 30,
        'courseId': 'course-456',
      };

      // Act
      final section = Section.fromJson(json);

      // Assert - Verify all string IDs are preserved
      expect(section.id, equals('section-123'),
          reason: 'Section ID should be preserved as string');
      expect(section.courseId, equals('course-456'),
          reason: 'Foreign key courseId should be preserved as string');
      expect(section.name, equals('Section A'));
    });

    test('Subject model should deserialize with string ID', () {
      // Arrange - API response with string ID
      final json = {
        'id': 'subject-123',
        'name': 'Computer Science',
        'code': 'CS101',
      };

      // Act
      final subject = Subject.fromJson(json);

      // Assert - Verify string ID is preserved
      expect(subject.id, equals('subject-123'),
          reason: 'Subject ID should be preserved as string');
      expect(subject.name, equals('Computer Science'));
      expect(subject.code, equals('CS101'));
    });

    test('Course model should deserialize with string ID', () {
      // Arrange - API response with string ID
      final json = {
        'id': 'course-123',
        'name': 'Bachelor of Science in Computer Science',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      // Act
      final course = Course.fromJson(json);

      // Assert - Verify string ID is preserved
      expect(course.id, equals('course-123'),
          reason: 'Course ID should be preserved as string');
      expect(course.name, equals('Bachelor of Science in Computer Science'));
    });

    test('Classroom model should deserialize with string ID', () {
      // Arrange - API response with string ID
      final json = {
        'id': 'classroom-123',
        'name': 'Room 101',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      // Act
      final classroom = Classroom.fromJson(json);

      // Assert - Verify string ID is preserved
      expect(classroom.id, equals('classroom-123'),
          reason: 'Classroom ID should be preserved as string');
      expect(classroom.name, equals('Room 101'));
    });

    test('Schedule model should preserve string ID values', () {
      // Arrange - API response with string IDs
      final json = {
        'id': 'schedule-123',
        'timeIn': '08:00',
        'timeOut': '10:00',
        'dayOfWeek': 1,
        'subjectId': 'subject-456',
        'classroomId': 'classroom-789',
        'sectionId': 'section-012',
        'instructorId': 'instructor-345',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      // Act
      final schedule = Schedule.fromJson(json);

      // Assert - Verify all string IDs are preserved (not converted to 0/null)
      expect(schedule.id, equals('schedule-123'),
          reason: 'Schedule ID should be preserved as string');
      expect(schedule.subjectId, equals('subject-456'),
          reason: 'Foreign key subjectId should be preserved as string');
      expect(schedule.classroomId, equals('classroom-789'),
          reason: 'Foreign key classroomId should be preserved as string');
      expect(schedule.sectionId, equals('section-012'),
          reason: 'Foreign key sectionId should be preserved as string');
      expect(schedule.instructorId, equals('instructor-345'),
          reason: 'Foreign key instructorId should be preserved as string');
    });

    test('StudentProfileInfo model should deserialize with string IDs', () {
      // Arrange - API response with string IDs
      final json = {
        'id': 'student-profile-123',
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'sectionId': 'section-456',
        'sectionName': 'Section A',
        'courseId': 'course-789',
        'courseName': 'Computer Science',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      // Act
      final profile = StudentProfileInfo.fromJson(json);

      // Assert - Verify all string IDs are preserved
      expect(profile.id, equals('student-profile-123'),
          reason: 'Student profile ID should be preserved as string');
      expect(profile.sectionId, equals('section-456'),
          reason: 'Foreign key sectionId should be preserved as string');
      expect(profile.courseId, equals('course-789'),
          reason: 'Foreign key courseId should be preserved as string');
    });

    test('InstructorProfileInfo model should deserialize with string ID', () {
      // Arrange - API response with string ID
      final json = {
        'id': 'instructor-profile-123',
        'firstname': 'Jane',
        'lastname': 'Smith',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      };

      // Act
      final profile = InstructorProfileInfo.fromJson(json);

      // Assert - Verify string ID is preserved
      expect(profile.id, equals('instructor-profile-123'),
          reason: 'Instructor profile ID should be preserved as string');
      expect(profile.firstname, equals('Jane'));
      expect(profile.lastname, equals('Smith'));
    });
  });

  group('Bug Condition Documentation - Post-Fix Verification', () {
    test('Verify: Student model successfully deserializes string IDs', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'userId': 'user-123',
        'sectionId': 'section-456',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
        'isDeleted': false,
      };

      final student = Student.fromJson(json);

      // Verify successful deserialization
      expect(student.id, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(student.sectionId, equals('section-456'));
      expect(student.firstname, equals('John'));
    });

    test('Verify: Session model preserves string IDs (no data loss)', () {
      final json = {
        'id': 'session-123',
        'scheduleId': 'schedule-456',
        'status': 'active',
        'sessionDate': '2024-01-15T00:00:00Z',
        'subjectCode': 'CS101',
        'subjectName': 'Computer Science',
        'sectionName': 'Section A',
        'scheduledRoomName': 'Room 101',
        'scheduledTimeIn': '08:00',
        'scheduledTimeOut': '10:00',
      };

      final session = ClassSession.fromJson(json);

      // Verify string IDs are preserved (not converted to 0)
      expect(session.id, equals('session-123'));
      expect(session.scheduleId, equals('schedule-456'));
      expect(session.status, equals('active'));
    });

    test('Verify: Attendance with multiple foreign keys deserializes correctly',
        () {
      final json = {
        'id': 'attendance-123',
        'sessionId': 'session-456',
        'studentId': 'student-789',
        'status': 'present',
        'remarks': 'On time',
        'createdAt': '2024-01-15T08:30:00Z',
        'updatedAt': '2024-01-15T08:30:00Z',
      };

      final attendance = AttendanceRecord.fromJson(json);

      // Verify all string IDs are preserved
      expect(attendance.id, equals('attendance-123'));
      expect(attendance.sessionId, equals('session-456'));
      expect(attendance.studentId, equals('student-789'));
      expect(attendance.status, equals('present'));
    });

    test('Verify: Schedule model preserves all string IDs (no data loss)', () {
      final json = {
        'id': 'schedule-123',
        'timeIn': '08:00',
        'timeOut': '10:00',
        'dayOfWeek': 1,
        'subjectId': 'subject-456',
        'classroomId': 'classroom-789',
        'sectionId': 'section-012',
        'instructorId': 'instructor-345',
      };

      final schedule = Schedule.fromJson(json);

      // Verify all string IDs are preserved (not converted to 0/null)
      expect(schedule.id, equals('schedule-123'));
      expect(schedule.subjectId, equals('subject-456'));
      expect(schedule.classroomId, equals('classroom-789'));
      expect(schedule.sectionId, equals('section-012'));
      expect(schedule.instructorId, equals('instructor-345'));
    });

    test('Verify: Fingerprint device preserves API id and device identifier',
        () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'deviceIdentifier': 'esp32-attendance-01',
        'name': 'Front Desk Scanner',
        'location': 'Lab 1',
        'status': 'active',
        'isOnline': true,
      };

      final device = FingerprintDevice.fromJson(json);

      expect(device.id, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(device.deviceIdentifier, equals('esp32-attendance-01'));
      expect(
          device.toJson()['deviceIdentifier'], equals('esp32-attendance-01'));
    });

    test('Verify: Fingerprint device parses current backend web contract', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'deviceIdentifier': 'esp32-attendance-01',
        'name': '',
        'location': '',
        'isActive': true,
        'lastSeenAt': '2026-04-28T10:00:00Z',
      };

      final device = FingerprintDevice.fromJson(json);

      expect(device.name, equals('Unnamed Device'));
      expect(device.location, isNull);
      expect(device.status, equals('active'));
      expect(device.isOnline, isTrue);
      expect(device.toJson()['isActive'], isTrue);
      expect(device.toJson()['lastSeenAt'], equals('2026-04-28T10:00:00Z'));
    });
  });
}
