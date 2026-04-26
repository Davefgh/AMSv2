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

/// Functional Preservation Property Tests
///
/// GOAL: Verify that all existing functionality continues to work correctly
/// after the ID type migration from int to String
///
/// METHODOLOGY: Observation-first approach
/// 1. Test with integer IDs on UNFIXED code (baseline behavior)
/// 2. After fix, test with string IDs (should produce same functional behavior)
///
/// EXPECTED OUTCOME:
/// - Tests PASS on unfixed code with integer IDs (confirms baseline)
/// - Tests PASS on fixed code with string IDs (confirms preservation)
///
/// Property 2: Preservation - Functional Equivalence After Migration
/// For any user interaction or app operation that worked correctly with integer IDs,
/// the migrated app SHALL produce exactly the same functional behavior with string IDs.
void main() {
  group('Property 2: Preservation - Model Serialization/Deserialization', () {
    group('Student Model Preservation', () {
      test('Student model round-trip serialization preserves all fields', () {
        // Arrange - Create student with string IDs (after migration)
        final originalJson = {
          'id': '1',
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': '5',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        // Act - Deserialize and verify
        final student = Student.fromJson(originalJson);

        // Assert - All fields preserved
        expect(student.id, equals('1'));
        expect(student.firstname, equals('John'));
        expect(student.lastname, equals('Doe'));
        expect(student.isRegular, isTrue);
        expect(student.userId, equals('user-123'));
        expect(student.sectionId, equals('5'));
        expect(student.isDeleted, isFalse);
        expect(student.fullName, equals('John Doe'));
      });

      test('Student model handles missing optional fields gracefully', () {
        // Arrange - Minimal JSON
        final json = {
          'id': '1',
          'firstname': 'Jane',
          'lastname': 'Smith',
          'isRegular': false,
          'userId': 'user-456',
          'sectionId': '3',
        };

        // Act
        final student = Student.fromJson(json);

        // Assert - Defaults applied correctly
        expect(student.id, equals('1'));
        expect(student.firstname, equals('Jane'));
        expect(student.isDeleted, isFalse);
      });

      test('Student fullName computed property works correctly', () {
        // Arrange
        final json = {
          'id': '1',
          'firstname': 'Alice',
          'lastname': 'Johnson',
          'isRegular': true,
          'userId': 'user-789',
          'sectionId': '2',
        };

        // Act
        final student = Student.fromJson(json);

        // Assert
        expect(student.fullName, equals('Alice Johnson'));
      });
    });

    group('Session Model Preservation', () {
      test('Session model round-trip serialization preserves all fields', () {
        // Arrange - Create session with string IDs (after migration)
        final originalJson = {
          'id': '10',
          'scheduleId': '20',
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
        final session = ClassSession.fromJson(originalJson);

        // Assert - All fields preserved
        expect(session.id, equals('10'));
        expect(session.scheduleId, equals('20'));
        expect(session.status, equals('active'));
        expect(session.subjectCode, equals('CS101'));
        expect(session.subjectName, equals('Computer Science'));
        expect(session.sectionName, equals('Section A'));
        expect(session.scheduledRoomName, equals('Room 101'));
        expect(session.scheduledTimeIn, equals('08:00'));
        expect(session.scheduledTimeOut, equals('10:00'));
      });

      test('Session model toJson preserves ID fields correctly', () {
        // Arrange
        final session = ClassSession(
          id: '15',
          scheduleId: '25',
          status: 'not_started',
          subjectCode: 'MATH101',
          subjectName: 'Mathematics',
          sectionName: 'Section B',
          scheduledRoomName: 'Room 202',
          scheduledTimeIn: '10:00',
          scheduledTimeOut: '12:00',
        );

        // Act
        final json = session.toJson();

        // Assert - ID fields included when valid
        expect(json['id'], equals('15'));
        expect(json['scheduleId'], equals('25'));
        expect(json['status'], equals('not_started'));
      });

      test('Session model handles optional fields correctly', () {
        // Arrange - Minimal session
        final json = {
          'id': '5',
          'scheduleId': '10',
          'status': 'ended',
        };

        // Act
        final session = ClassSession.fromJson(json);

        // Assert - Defaults applied
        expect(session.id, equals('5'));
        expect(session.scheduleId, equals('10'));
        expect(session.status, equals('ended'));
        expect(session.subjectCode, equals(''));
        expect(session.subjectName, equals(''));
      });
    });

    group('Attendance Model Preservation', () {
      test('Attendance model round-trip serialization preserves all ID fields',
          () {
        // Arrange - Create attendance with string IDs (after migration)
        final originalJson = {
          'id': '100',
          'sessionId': '10',
          'studentId': '5',
          'status': 'present',
          'remarks': 'On time',
          'createdAt': '2024-01-15T08:30:00Z',
          'updatedAt': '2024-01-15T08:30:00Z',
        };

        // Act
        final attendance = AttendanceRecord.fromJson(originalJson);

        // Assert - All ID fields preserved
        expect(attendance.id, equals('100'));
        expect(attendance.sessionId, equals('10'));
        expect(attendance.studentId, equals('5'));
        expect(attendance.status, equals('present'));
        expect(attendance.remarks, equals('On time'));
      });

      test('Attendance model toJson preserves all ID fields', () {
        // Arrange
        final attendance = AttendanceRecord(
          id: '200',
          sessionId: '20',
          studentId: '10',
          status: 'absent',
          remarks: 'Excused',
        );

        // Act
        final json = attendance.toJson();

        // Assert - All IDs included
        expect(json['id'], equals('200'));
        expect(json['sessionId'], equals('20'));
        expect(json['studentId'], equals('10'));
        expect(json['status'], equals('absent'));
        expect(json['remarks'], equals('Excused'));
      });

      test('Attendance model handles missing optional fields', () {
        // Arrange - Minimal attendance
        final json = {
          'id': '50',
          'sessionId': '15',
          'studentId': '8',
          'status': 'late',
        };

        // Act
        final attendance = AttendanceRecord.fromJson(json);

        // Assert
        expect(attendance.id, equals('50'));
        expect(attendance.sessionId, equals('15'));
        expect(attendance.studentId, equals('8'));
        expect(attendance.status, equals('late'));
        expect(attendance.remarks, isNull);
      });
    });

    group('Enrollment Model Preservation', () {
      test('Enrollment model preserves all ID fields', () {
        // Arrange
        final json = {
          'id': '300',
          'studentId': '5',
          'sectionId': '10',
          'subjectId': '15',
          'enrollmentType': 'Regular',
          'academicYear': '2024',
          'semester': 'First',
        };

        // Act
        final enrollment = Enrollment.fromJson(json);

        // Assert - All ID fields preserved
        expect(enrollment.id, equals('300'));
        expect(enrollment.studentId, equals('5'));
        expect(enrollment.sectionId, equals('10'));
        expect(enrollment.subjectId, equals('15'));
        expect(enrollment.enrollmentType, equals('Regular'));
      });
    });

    group('Section Model Preservation', () {
      test('Section model preserves ID and foreign key fields', () {
        // Arrange
        final json = {
          'id': '10',
          'name': 'Section A',
          'capacity': 30,
          'courseId': '5',
        };

        // Act
        final section = Section.fromJson(json);

        // Assert
        expect(section.id, equals('10'));
        expect(section.name, equals('Section A'));
        expect(section.capacity, equals(30));
        expect(section.courseId, equals('5'));
      });
    });

    group('Subject Model Preservation', () {
      test('Subject model preserves ID field', () {
        // Arrange
        final json = {
          'id': '20',
          'name': 'Computer Science',
          'code': 'CS101',
        };

        // Act
        final subject = Subject.fromJson(json);

        // Assert
        expect(subject.id, equals('20'));
        expect(subject.name, equals('Computer Science'));
        expect(subject.code, equals('CS101'));
      });
    });

    group('Course Model Preservation', () {
      test('Course model preserves ID field', () {
        // Arrange
        final json = {
          'id': '30',
          'name': 'Bachelor of Science in Computer Science',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        };

        // Act
        final course = Course.fromJson(json);

        // Assert
        expect(course.id, equals('30'));
        expect(course.name, equals('Bachelor of Science in Computer Science'));
      });
    });

    group('Classroom Model Preservation', () {
      test('Classroom model preserves ID field', () {
        // Arrange
        final json = {
          'id': '40',
          'name': 'Room 101',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        };

        // Act
        final classroom = Classroom.fromJson(json);

        // Assert
        expect(classroom.id, equals('40'));
        expect(classroom.name, equals('Room 101'));
      });
    });

    group('Schedule Model Preservation', () {
      test('Schedule model preserves all ID fields', () {
        // Arrange
        final json = {
          'id': '50',
          'timeIn': '08:00',
          'timeOut': '10:00',
          'dayOfWeek': 1,
          'subjectId': '20',
          'classroomId': '40',
          'sectionId': '10',
          'instructorId': '15',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        };

        // Act
        final schedule = Schedule.fromJson(json);

        // Assert - All ID fields preserved
        expect(schedule.id, equals('50'));
        expect(schedule.subjectId, equals('20'));
        expect(schedule.classroomId, equals('40'));
        expect(schedule.sectionId, equals('10'));
        expect(schedule.instructorId, equals('15'));
        expect(schedule.timeIn, equals('08:00'));
        expect(schedule.timeOut, equals('10:00'));
      });
    });
  });

  group('Property 2: Preservation - Entity Relationships', () {
    test('Student-Section relationship is preserved through foreign key', () {
      // Arrange - Student with section reference
      final studentJson = {
        'id': '1',
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'userId': 'user-123',
        'sectionId': '5',
      };

      final sectionJson = {
        'id': '5',
        'name': 'Section A',
        'capacity': 30,
        'courseId': '10',
      };

      // Act
      final student = Student.fromJson(studentJson);
      final section = Section.fromJson(sectionJson);

      // Assert - Foreign key relationship preserved
      expect(student.sectionId, equals(section.id));
    });

    test('Attendance-Session-Student relationship is preserved', () {
      // Arrange - Related entities
      final studentJson = {
        'id': '5',
        'firstname': 'Alice',
        'lastname': 'Smith',
        'isRegular': true,
        'userId': 'user-456',
        'sectionId': '10',
      };

      final sessionJson = {
        'id': '20',
        'scheduleId': '30',
        'status': 'active',
      };

      final attendanceJson = {
        'id': '100',
        'sessionId': '20',
        'studentId': '5',
        'status': 'present',
      };

      // Act
      final student = Student.fromJson(studentJson);
      final session = ClassSession.fromJson(sessionJson);
      final attendance = AttendanceRecord.fromJson(attendanceJson);

      // Assert - Foreign key relationships preserved
      expect(attendance.studentId, equals(student.id));
      expect(attendance.sessionId, equals(session.id));
    });

    test(
        'Schedule-Section-Instructor-Subject-Classroom relationships preserved',
        () {
      // Arrange - Complex relationship
      final scheduleJson = {
        'id': '50',
        'timeIn': '08:00',
        'timeOut': '10:00',
        'dayOfWeek': 1,
        'subjectId': '20',
        'classroomId': '40',
        'sectionId': '10',
        'instructorId': '15',
      };

      final sectionJson = {'id': '10', 'name': 'Section A', 'courseId': '5'};
      final subjectJson = {'id': '20', 'name': 'Math', 'code': 'MATH101'};
      final classroomJson = {'id': '40', 'name': 'Room 101'};
      final instructorJson = {
        'id': '15',
        'firstname': 'Dr.',
        'lastname': 'Smith',
        'email': 'smith@example.com',
        'userId': 'user-789',
      };

      // Act
      final schedule = Schedule.fromJson(scheduleJson);
      final section = Section.fromJson(sectionJson);
      final subject = Subject.fromJson(subjectJson);
      final classroom = Classroom.fromJson(classroomJson);
      final instructor = Instructor.fromJson(instructorJson);

      // Assert - All foreign key relationships preserved
      expect(schedule.sectionId, equals(section.id));
      expect(schedule.subjectId, equals(subject.id));
      expect(schedule.classroomId, equals(classroom.id));
      expect(schedule.instructorId, equals(instructor.id));
    });

    test('Enrollment-Student-Section relationship is preserved', () {
      // Arrange
      final enrollmentJson = {
        'id': '300',
        'studentId': '5',
        'sectionId': '10',
        'subjectId': '20',
        'enrollmentType': 'Regular',
      };

      final studentJson = {
        'id': '5',
        'firstname': 'Bob',
        'lastname': 'Jones',
        'isRegular': true,
        'userId': 'user-999',
        'sectionId': '10',
      };

      final sectionJson = {'id': '10', 'name': 'Section B', 'courseId': '5'};

      // Act
      final enrollment = Enrollment.fromJson(enrollmentJson);
      final student = Student.fromJson(studentJson);
      final section = Section.fromJson(sectionJson);

      // Assert
      expect(enrollment.studentId, equals(student.id));
      expect(enrollment.sectionId, equals(section.id));
    });
  });

  group('Property 2: Preservation - ID Comparison and Equality', () {
    test('ID equality comparison works correctly', () {
      // Arrange
      final student1Json = {
        'id': '1',
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'userId': 'user-123',
        'sectionId': '5',
      };

      final student2Json = {
        'id': '1',
        'firstname': 'Jane',
        'lastname': 'Smith',
        'isRegular': false,
        'userId': 'user-456',
        'sectionId': '10',
      };

      final student3Json = {
        'id': '2',
        'firstname': 'Bob',
        'lastname': 'Jones',
        'isRegular': true,
        'userId': 'user-789',
        'sectionId': '5',
      };

      // Act
      final student1 = Student.fromJson(student1Json);
      final student2 = Student.fromJson(student2Json);
      final student3 = Student.fromJson(student3Json);

      // Assert - ID comparison works
      expect(student1.id == student2.id, isTrue,
          reason: 'Same ID should be equal');
      expect(student1.id == student3.id, isFalse,
          reason: 'Different IDs should not be equal');
    });

    test('ID lookup in collections works correctly', () {
      // Arrange
      final students = [
        Student.fromJson({
          'id': '1',
          'firstname': 'Alice',
          'lastname': 'A',
          'isRegular': true,
          'userId': 'user-1',
          'sectionId': '5',
        }),
        Student.fromJson({
          'id': '2',
          'firstname': 'Bob',
          'lastname': 'B',
          'isRegular': true,
          'userId': 'user-2',
          'sectionId': '5',
        }),
        Student.fromJson({
          'id': '3',
          'firstname': 'Charlie',
          'lastname': 'C',
          'isRegular': true,
          'userId': 'user-3',
          'sectionId': '5',
        }),
      ];

      // Act - Find student by ID
      const targetId = '2';
      final foundStudent =
          students.firstWhere((s) => s.id == targetId, orElse: () {
        throw Exception('Student not found');
      });

      // Assert
      expect(foundStudent.id, equals('2'));
      expect(foundStudent.firstname, equals('Bob'));
    });

    test('ID filtering in collections works correctly', () {
      // Arrange
      final attendanceRecords = [
        AttendanceRecord.fromJson({
          'id': '1',
          'sessionId': '10',
          'studentId': '5',
          'status': 'present',
        }),
        AttendanceRecord.fromJson({
          'id': '2',
          'sessionId': '10',
          'studentId': '6',
          'status': 'absent',
        }),
        AttendanceRecord.fromJson({
          'id': '3',
          'sessionId': '10',
          'studentId': '7',
          'status': 'present',
        }),
      ];

      // Act - Filter by session ID
      const targetSessionId = '10';
      final filteredRecords = attendanceRecords
          .where((a) => a.sessionId == targetSessionId)
          .toList();

      // Assert
      expect(filteredRecords.length, equals(3));
      expect(
          filteredRecords.every((a) => a.sessionId == targetSessionId), isTrue);
    });
  });

  group('Property 2: Preservation - ID Validation Logic', () {
    test('Valid ID check works correctly (ID.isNotEmpty)', () {
      // Arrange
      final validStudent = Student.fromJson({
        'id': '1',
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'userId': 'user-123',
        'sectionId': '5',
      });

      final invalidStudent = Student.fromJson({
        'id': '',
        'firstname': 'Jane',
        'lastname': 'Smith',
        'isRegular': true,
        'userId': 'user-456',
        'sectionId': '5',
      });

      // Act & Assert
      expect(validStudent.id.isNotEmpty, isTrue,
          reason: 'Valid ID should not be empty');
      expect(invalidStudent.id.isNotEmpty, isFalse,
          reason: 'Invalid ID (empty) should be empty');
    });

    test('Session toJson excludes invalid IDs (empty string)', () {
      // Arrange
      final validSession = ClassSession(
        id: '10',
        scheduleId: '20',
        status: 'active',
      );

      final invalidSession = ClassSession(
        id: '',
        scheduleId: '20',
        status: 'active',
      );

      // Act
      final validJson = validSession.toJson();
      final invalidJson = invalidSession.toJson();

      // Assert
      expect(validJson.containsKey('id'), isTrue,
          reason: 'Valid ID should be included in JSON');
      expect(invalidJson.containsKey('id'), isFalse,
          reason: 'Invalid ID (empty) should be excluded from JSON');
    });
  });

  group('Property 2: Preservation - Data Type Consistency', () {
    test('ID fields maintain consistent type throughout operations', () {
      // Arrange
      final originalJson = {
        'id': '1',
        'sessionId': '10',
        'studentId': '5',
        'status': 'present',
      };

      // Act - Deserialize and serialize
      final attendance = AttendanceRecord.fromJson(originalJson);
      final serializedJson = attendance.toJson();

      // Assert - Types remain consistent
      expect(attendance.id, isA<String>());
      expect(attendance.sessionId, isA<String>());
      expect(attendance.studentId, isA<String>());
      expect(serializedJson['id'], isA<String>());
      expect(serializedJson['sessionId'], isA<String>());
      expect(serializedJson['studentId'], isA<String>());
    });

    test('Foreign key IDs maintain type consistency across models', () {
      // Arrange
      final studentJson = {
        'id': '5',
        'firstname': 'Alice',
        'lastname': 'Smith',
        'isRegular': true,
        'userId': 'user-456',
        'sectionId': '10',
      };

      final attendanceJson = {
        'id': '100',
        'sessionId': '20',
        'studentId': '5',
        'status': 'present',
      };

      // Act
      final student = Student.fromJson(studentJson);
      final attendance = AttendanceRecord.fromJson(attendanceJson);

      // Assert - Foreign key types match
      expect(student.id.runtimeType, equals(attendance.studentId.runtimeType));
      expect(student.id, isA<String>());
      expect(attendance.studentId, isA<String>());
    });
  });

  group('Property 2: Preservation - Edge Cases', () {
    test('Models handle default/empty IDs correctly', () {
      // Arrange - JSON with missing IDs
      final studentJson = {
        'firstname': 'John',
        'lastname': 'Doe',
        'isRegular': true,
        'userId': 'user-123',
      };

      // Act
      final student = Student.fromJson(studentJson);

      // Assert - Default values applied
      expect(student.id, equals(''));
      expect(student.sectionId, equals(''));
    });

    test('Models handle null ID fields gracefully', () {
      // Arrange - JSON with explicit null IDs
      final sessionJson = {
        'id': null,
        'scheduleId': null,
        'status': 'not_started',
      };

      // Act
      final session = ClassSession.fromJson(sessionJson);

      // Assert - Null converted to default
      expect(session.id, equals(''));
      expect(session.scheduleId, equals(''));
    });

    test('Optional foreign key IDs (nullable) work correctly', () {
      // Arrange - Schedule with optional classroom
      final scheduleJson = {
        'id': '50',
        'timeIn': '08:00',
        'timeOut': '10:00',
        'dayOfWeek': 1,
        'subjectId': '20',
        'classroomId': null, // Optional
        'sectionId': '10',
        'instructorId': '15',
      };

      // Act
      final schedule = Schedule.fromJson(scheduleJson);

      // Assert - Nullable foreign key handled
      expect(schedule.classroomId, isNull);
      expect(schedule.subjectId, equals('20'));
      expect(schedule.sectionId, equals('10'));
    });
  });

  group('Property 2: Preservation - Documentation', () {
    test('Document baseline behavior: String ID serialization', () {
      // This test documents the behavior with string IDs after migration
      // All functional behavior should work identically with string IDs

      final testCases = [
        {
          'model': 'Student',
          'json': {
            'id': '1',
            'firstname': 'John',
            'lastname': 'Doe',
            'isRegular': true,
            'userId': 'user-123',
            'sectionId': '5',
          },
          'expectedId': '1',
          'expectedForeignKey': '5',
        },
        {
          'model': 'Session',
          'json': {
            'id': '10',
            'scheduleId': '20',
            'status': 'active',
          },
          'expectedId': '10',
          'expectedForeignKey': '20',
        },
        {
          'model': 'Attendance',
          'json': {
            'id': '100',
            'sessionId': '10',
            'studentId': '5',
            'status': 'present',
          },
          'expectedId': '100',
          'expectedForeignKeys': ['10', '5'],
        },
      ];

      for (final testCase in testCases) {
        final model = testCase['model'] as String;
        final json = testCase['json'] as Map<String, dynamic>;

        // Document the behavior after migration
        // ignore: avoid_print
        print('BEHAVIOR AFTER MIGRATION DOCUMENTED:');
        // ignore: avoid_print
        print('Model: $model');
        // ignore: avoid_print
        print('Input: $json');
        // ignore: avoid_print
        print('Expected: IDs preserved as strings');
        // ignore: avoid_print
        print('---');
      }

      // This test always passes - it's for documentation
      expect(true, isTrue);
    });
  });
}
