import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/utils/id_utils.dart';

void main() {
  group('ID Validation Tests', () {
    test('validateId throws ArgumentError for null ID', () {
      expect(
        () => validateId(null, 'Student'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validateId throws ArgumentError for empty ID', () {
      expect(
        () => validateId('', 'Student'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validateId does not throw for valid ID', () {
      expect(() => validateId('123', 'Student'), returnsNormally);
      expect(
          () => validateId('550e8400-e29b-41d4-a716-446655440000', 'Student'),
          returnsNormally);
    });

    test('isValidId returns false for null or empty', () {
      expect(isValidId(null), false);
      expect(isValidId(''), false);
    });

    test('isValidId returns true for valid IDs', () {
      expect(isValidId('123'), true);
      expect(isValidId('550e8400-e29b-41d4-a716-446655440000'), true);
    });
  });

  group('ID Display Tests', () {
    test('displayId truncates long IDs', () {
      const longId = '550e8400-e29b-41d4-a716-446655440000';
      expect(displayId(longId), '550e8400...');
    });

    test('displayId returns short IDs unchanged', () {
      expect(displayId('123'), '123');
      expect(displayId('12345678'), '12345678');
    });

    test('displayIdWithLength truncates at custom length', () {
      const longId = '550e8400-e29b-41d4-a716-446655440000';
      expect(displayIdWithLength(longId, 12), '550e8400-e29...');
      expect(displayIdWithLength(longId, 4), '550e...');
    });
  });

  group('Safe ID Conversion Tests', () {
    test('safeIdToString handles various types', () {
      expect(safeIdToString(123), '123');
      expect(safeIdToString('abc-123'), 'abc-123');
      expect(safeIdToString(null), '');
      expect(safeIdToString(456.789), '456.789');
    });
  });

  group('Bulk ID Validation Tests', () {
    test('validateIds throws for any invalid ID', () {
      expect(
        () => validateIds(['123', '', '456'], 'Student'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => validateIds(['123', null, '456'], 'Student'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validateIds does not throw for all valid IDs', () {
      expect(
        () => validateIds(['123', '456', '789'], 'Student'),
        returnsNormally,
      );
    });

    test('areAllIdsValid returns false if any ID is invalid', () {
      expect(areAllIdsValid(['123', '', '456']), false);
      expect(areAllIdsValid(['123', null, '456']), false);
    });

    test('areAllIdsValid returns true if all IDs are valid', () {
      expect(areAllIdsValid(['123', '456', '789']), true);
    });
  });

  group('InvalidIdException Tests', () {
    test('validateIdOrThrow throws InvalidIdException for invalid ID', () {
      expect(
        () => validateIdOrThrow(null, 'Student'),
        throwsA(isA<InvalidIdException>()),
      );
      expect(
        () => validateIdOrThrow('', 'Student'),
        throwsA(isA<InvalidIdException>()),
      );
    });

    test('validateIdOrThrow does not throw for valid ID', () {
      expect(() => validateIdOrThrow('123', 'Student'), returnsNormally);
    });

    test('InvalidIdException has correct message format', () {
      try {
        validateIdOrThrow('', 'Student');
        fail('Should have thrown InvalidIdException');
      } on InvalidIdException catch (e) {
        expect(e.entityType, 'Student');
        expect(e.message, 'Missing or empty ID');
        expect(e.toString(), contains('InvalidIdException'));
        expect(e.toString(), contains('Student'));
      }
    });
  });
}
