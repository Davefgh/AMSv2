import 'package:amsv2/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseStudentFingerprintsResponse', () {
    test('wraps the backend single fingerprint response in a list', () {
      final fingerprints = parseStudentFingerprintsResponse({
        'id': '43d6ef2c-f36b-1410-8d5b-001b1fc94d01',
        'studentId': '7584433e-f36b-1410-8d59-001b1fc94d01',
        'deviceId': 'device-1',
        'studentName': 'Jane Student',
        'status': 'Active',
        'createdAt': '2026-04-28T10:30:00Z',
      });

      expect(fingerprints, hasLength(1));
      expect(fingerprints.single.id, '43d6ef2c-f36b-1410-8d5b-001b1fc94d01');
      expect(
        fingerprints.single.studentId,
        '7584433e-f36b-1410-8d59-001b1fc94d01',
      );
    });

    test('preserves list responses for compatibility', () {
      final fingerprints = parseStudentFingerprintsResponse([
        {
          'id': '43d6ef2c-f36b-1410-8d5b-001b1fc94d01',
          'studentId': '7584433e-f36b-1410-8d59-001b1fc94d01',
        },
      ]);

      expect(fingerprints, hasLength(1));
      expect(fingerprints.single.studentId,
          '7584433e-f36b-1410-8d59-001b1fc94d01');
    });

    test('returns empty for missing response bodies', () {
      expect(parseStudentFingerprintsResponse(null), isEmpty);
      expect(parseStudentFingerprintsResponse({}), isEmpty);
    });
  });
}
