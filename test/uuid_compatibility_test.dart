import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/models/student_model.dart';
import 'package:amsv2/models/attendance_model.dart';
import 'package:amsv2/models/session_model.dart';
import 'package:amsv2/models/section_model.dart';
import 'package:amsv2/utils/id_utils.dart';

void main() {
  group('UUID Compatibility Tests', () {
    const sampleUuid = '550e8400-e29b-41d4-a716-446655440000';
    const sampleIntId = '123';

    group('Student Model', () {
      test('parses UUID from JSON', () {
        final json = {
          'id': sampleUuid,
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': sampleUuid,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        final student = Student.fromJson(json);

        expect(student.id, sampleUuid);
        expect(student.sectionId, sampleUuid);
        expect(student.hasValidId, true);
      });

      test('parses integer ID from JSON (backward compatibility)', () {
        final json = {
          'id': 123,
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': 456,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        final student = Student.fromJson(json);

        expect(student.id, '123');
        expect(student.sectionId, '456');
        expect(student.hasValidId, true);
      });

      test('displays truncated UUID', () {
        final json = {
          'id': sampleUuid,
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': sampleUuid,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        final student = Student.fromJson(json);

        expect(student.displayId, '550e8400...');
      });
    });

    group('Attendance Model', () {
      test('parses UUID from JSON', () {
        final json = {
          'id': sampleUuid,
          'sessionId': sampleUuid,
          'studentId': sampleUuid,
          'status': 'present',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final attendance = AttendanceRecord.fromJson(json);

        expect(attendance.id, sampleUuid);
        expect(attendance.sessionId, sampleUuid);
        expect(attendance.studentId, sampleUuid);
        expect(attendance.hasValidId, true);
      });

      test('parses integer ID from JSON (backward compatibility)', () {
        final json = {
          'id': 123,
          'sessionId': 456,
          'studentId': 789,
          'status': 'present',
          'createdAt': '2024-01-01T00:00:00Z',
        };

        final attendance = AttendanceRecord.fromJson(json);

        expect(attendance.id, '123');
        expect(attendance.sessionId, '456');
        expect(attendance.studentId, '789');
        expect(attendance.hasValidId, true);
      });

      test('parses attendance records from student history wrapper', () {
        final records = AttendanceRecord.listFromBackendResponse({
          'studentId': sampleUuid,
          'studentName': 'John Doe',
          'attendanceRecords': [
            {
              'id': sampleUuid,
              'sessionId': sampleUuid,
              'studentId': sampleUuid,
              'status': 'Late',
            },
          ],
        });

        expect(records, hasLength(1));
        expect(records.single.status, 'Late');
      });

      test('parses attendance records from session attendance wrapper', () {
        final records = AttendanceRecord.listFromBackendResponse({
          'sessionId': sampleUuid,
          'attendanceRecords': [
            {
              'id': sampleUuid,
              'sessionId': sampleUuid,
              'studentId': sampleUuid,
              'status': 'Present',
            },
          ],
        });

        expect(records, hasLength(1));
        expect(records.single.status, 'Present');
      });

      test('parses backend attendance summary fields', () {
        final summary = AttendanceSummary.fromJson({
          'totalSessions': 10,
          'totalPresent': 7,
          'totalLate': 1,
          'totalAbsent': 2,
          'totalExcused': 0,
          'attendanceRate': 80,
          'mostFrequentStatus': 'Present',
        });

        expect(summary.totalSessions, 10);
        expect(summary.totalPresent, 7);
        expect(summary.totalAbsent, 2);
        expect(summary.attendanceRate, 80);
      });
    });

    group('Session Model', () {
      test('parses UUID from JSON', () {
        final json = {
          'id': sampleUuid,
          'scheduleId': sampleUuid,
          'status': 'active',
          'sessionDate': '2024-01-01T00:00:00Z',
          'subjectCode': 'CS101',
          'subjectName': 'Computer Science',
          'sectionName': 'Section A',
          'scheduledRoomName': 'Room 101',
          'scheduledTimeIn': '08:00',
          'scheduledTimeOut': '10:00',
        };

        final session = ClassSession.fromJson(json);

        expect(session.id, sampleUuid);
        expect(session.scheduleId, sampleUuid);
        expect(session.hasValidId, true);
      });

      test('parses integer ID from JSON (backward compatibility)', () {
        final json = {
          'id': 123,
          'scheduleId': 456,
          'status': 'active',
          'sessionDate': '2024-01-01T00:00:00Z',
          'subjectCode': 'CS101',
          'subjectName': 'Computer Science',
          'sectionName': 'Section A',
          'scheduledRoomName': 'Room 101',
          'scheduledTimeIn': '08:00',
          'scheduledTimeOut': '10:00',
        };

        final session = ClassSession.fromJson(json);

        expect(session.id, '123');
        expect(session.scheduleId, '456');
        expect(session.hasValidId, true);
      });
    });

    group('Section Model', () {
      test('parses UUID from JSON', () {
        final json = {
          'id': sampleUuid,
          'name': 'Section A',
          'capacity': 30,
          'courseId': sampleUuid,
        };

        final section = Section.fromJson(json);

        expect(section.id, sampleUuid);
        expect(section.courseId, sampleUuid);
        expect(section.hasValidId, true);
      });
    });

    group('ID Utilities', () {
      test('validates UUID', () {
        expect(isValidId(sampleUuid), true);
        expect(isValidId(''), false);
        expect(isValidId(null), false);
      });

      test('validates integer ID string', () {
        expect(isValidId(sampleIntId), true);
        expect(isValidId('0'), true);
      });

      test('displays UUID correctly', () {
        expect(displayId(sampleUuid), '550e8400...');
        expect(displayIdWithLength(sampleUuid, 12), '550e8400-e29...');
      });

      test('displays short ID correctly', () {
        expect(displayId(sampleIntId), sampleIntId);
        expect(displayId('12345678'), '12345678');
      });

      test('safely converts values to string', () {
        expect(safeIdToString(123), '123');
        expect(safeIdToString('abc'), 'abc');
        expect(safeIdToString(sampleUuid), sampleUuid);
        expect(safeIdToString(null), '');
      });

      test('validates multiple IDs', () {
        expect(areAllIdsValid([sampleUuid, sampleIntId, '789']), true);
        expect(areAllIdsValid([sampleUuid, '', '789']), false);
        expect(areAllIdsValid([sampleUuid, null, '789']), false);
      });

      test('throws on invalid ID', () {
        expect(
          () => validateId(null, 'Student'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => validateId('', 'Student'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws InvalidIdException', () {
        expect(
          () => validateIdOrThrow(null, 'Student'),
          throwsA(isA<InvalidIdException>()),
        );
        expect(
          () => validateIdOrThrow('', 'Student'),
          throwsA(isA<InvalidIdException>()),
        );
      });
    });

    group('JSON Serialization Round-Trip', () {
      test('Student with UUID survives round-trip', () {
        final original = Student(
          id: sampleUuid,
          firstname: 'John',
          lastname: 'Doe',
          isRegular: true,
          userId: 'user-123',
          sectionId: sampleUuid,
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
          updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final json = original.toJson();
        final restored = Student.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.sectionId, original.sectionId);
        expect(restored.firstname, original.firstname);
      });

      test('AttendanceRecord with UUID survives round-trip', () {
        final original = AttendanceRecord(
          id: sampleUuid,
          sessionId: sampleUuid,
          studentId: sampleUuid,
          status: 'present',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final json = original.toJson();
        final restored = AttendanceRecord.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.sessionId, original.sessionId);
        expect(restored.studentId, original.studentId);
      });
    });

    group('Edge Cases', () {
      test('handles empty string ID', () {
        final json = {
          'id': '',
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': '',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        final student = Student.fromJson(json);

        expect(student.id, '');
        expect(student.hasValidId, false);
      });

      test('handles null ID', () {
        final json = {
          'id': null,
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': null,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        final student = Student.fromJson(json);

        expect(student.id, '');
        expect(student.hasValidId, false);
      });

      test('handles very long UUID-like strings', () {
        const longId = '550e8400-e29b-41d4-a716-446655440000-extra-long-suffix';
        final json = {
          'id': longId,
          'firstname': 'John',
          'lastname': 'Doe',
          'isRegular': true,
          'userId': 'user-123',
          'sectionId': sampleUuid,
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
          'isDeleted': false,
        };

        final student = Student.fromJson(json);

        expect(student.id, longId);
        expect(student.hasValidId, true);
        expect(student.displayId.endsWith('...'), true);
      });
    });
  });
}
