/// Utility functions for ID validation and display
///
/// This file provides helper functions for handling string-based entity IDs,
/// including validation, display formatting, and error handling.
library;

/// Validates that an ID is not empty or null
///
/// Throws an [ArgumentError] if the ID is empty or null.
/// Use this in critical paths where an invalid ID would cause data corruption.
///
/// Example:
/// ```dart
/// validateId(studentId, 'Student');
/// final student = await apiService.getStudent(studentId);
/// ```
void validateId(String? id, String entityType) {
  if (id == null || id.isEmpty) {
    throw ArgumentError('Invalid $entityType: missing ID');
  }
}

/// Validates that an ID is not empty or null, returns boolean
///
/// Returns `true` if the ID is valid (non-null and non-empty), `false` otherwise.
/// Use this for conditional logic where you want to handle invalid IDs gracefully.
///
/// Example:
/// ```dart
/// if (isValidId(studentId)) {
///   // Proceed with operation
/// } else {
///   // Show error message
/// }
/// ```
bool isValidId(String? id) {
  return id != null && id.isNotEmpty;
}

/// Truncates long IDs (like UUIDs) for display in UI
///
/// Returns the first 8 characters followed by '...' for IDs longer than 8 characters.
/// Returns the full ID if it's 8 characters or shorter.
///
/// Example:
/// ```dart
/// displayId('550e8400-e29b-41d4-a716-446655440000') // Returns: '550e8400...'
/// displayId('123') // Returns: '123'
/// ```
String displayId(String id) {
  if (id.length > 8) {
    return '${id.substring(0, 8)}...';
  }
  return id;
}

/// Truncates long IDs with custom length
///
/// Returns the first [length] characters followed by '...' for IDs longer than [length].
/// Returns the full ID if it's [length] characters or shorter.
///
/// Example:
/// ```dart
/// displayIdWithLength('550e8400-e29b-41d4-a716-446655440000', 12) // Returns: '550e8400-e29...'
/// ```
String displayIdWithLength(String id, int length) {
  if (id.length > length) {
    return '${id.substring(0, length)}...';
  }
  return id;
}

/// Safely converts any value to a String ID
///
/// Handles both int and String IDs during transition period.
/// Returns empty string for null values.
///
/// Example:
/// ```dart
/// safeIdToString(123) // Returns: '123'
/// safeIdToString('abc-123') // Returns: 'abc-123'
/// safeIdToString(null) // Returns: ''
/// ```
String safeIdToString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

/// Validates a list of IDs
///
/// Throws an [ArgumentError] if any ID in the list is invalid.
/// Use this when validating multiple IDs at once (e.g., bulk operations).
///
/// Example:
/// ```dart
/// validateIds([studentId1, studentId2, studentId3], 'Student');
/// ```
void validateIds(List<String?> ids, String entityType) {
  for (int i = 0; i < ids.length; i++) {
    if (ids[i] == null || ids[i]!.isEmpty) {
      throw ArgumentError('Invalid $entityType at index $i: missing ID');
    }
  }
}

/// Checks if all IDs in a list are valid
///
/// Returns `true` if all IDs are valid (non-null and non-empty), `false` otherwise.
///
/// Example:
/// ```dart
/// if (areAllIdsValid([id1, id2, id3])) {
///   // Proceed with bulk operation
/// }
/// ```
bool areAllIdsValid(List<String?> ids) {
  return ids.every((id) => isValidId(id));
}

/// Exception thrown when an ID validation fails
class InvalidIdException implements Exception {
  final String message;
  final String? entityType;
  final String? invalidId;

  InvalidIdException(this.message, {this.entityType, this.invalidId});

  @override
  String toString() {
    if (entityType != null) {
      return 'InvalidIdException: $message (Entity: $entityType, ID: $invalidId)';
    }
    return 'InvalidIdException: $message';
  }
}

/// Validates an ID and throws [InvalidIdException] if invalid
///
/// Similar to [validateId] but throws a custom exception type.
/// Use this when you want to catch ID validation errors specifically.
///
/// Example:
/// ```dart
/// try {
///   validateIdOrThrow(studentId, 'Student');
/// } on InvalidIdException catch (e) {
///   showErrorDialog(e.message);
/// }
/// ```
void validateIdOrThrow(String? id, String entityType) {
  if (id == null || id.isEmpty) {
    throw InvalidIdException(
      'Missing or empty ID',
      entityType: entityType,
      invalidId: id,
    );
  }
}
