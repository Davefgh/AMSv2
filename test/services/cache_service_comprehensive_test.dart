import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/services/cache_service.dart';
import 'package:amsv2/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive tests for CacheService covering all edge cases
void main() {
  group('CacheService - Comprehensive Tests', () {
    late CacheService cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      cache = CacheService();
    });

    tearDown(() async {
      await cache.clearAll();
    });

    group('clearAll() - Only Cache Keys', () {
      test('should only remove cache keys, not other storage', () async {
        // Set a cache key
        await cache.set<String>(key: 'test', data: 'value', toJson: (d) => d);

        // Set non-cache keys directly in storage
        await StorageService.setString('user_token', 'abc123');
        await StorageService.setString('user_id', '456');
        await StorageService.setBool('is_logged_in', true);

        // Clear cache
        await cache.clearAll();

        // Cache should be cleared
        expect(
            await cache.get<String>(key: 'test', fromJson: (j) => j as String),
            isNull);

        // Non-cache keys should remain
        expect(StorageService.getString('user_token'), 'abc123');
        expect(StorageService.getString('user_id'), '456');
        expect(StorageService.getBool('is_logged_in'), true);
      });

      test('should clear multiple cache entries', () async {
        // Set multiple caches
        await cache.set<String>(key: 'key1', data: 'value1', toJson: (d) => d);
        await cache.set<String>(key: 'key2', data: 'value2', toJson: (d) => d);
        await cache.set<String>(key: 'key3', data: 'value3', toJson: (d) => d);

        // Clear all
        await cache.clearAll();

        // All should be null
        expect(
            await cache.get<String>(key: 'key1', fromJson: (j) => j as String),
            isNull);
        expect(
            await cache.get<String>(key: 'key2', fromJson: (j) => j as String),
            isNull);
        expect(
            await cache.get<String>(key: 'key3', fromJson: (j) => j as String),
            isNull);
      });
    });

    group('invalidatePattern() - Precise Invalidation', () {
      test('should invalidate pattern from both memory and disk', () async {
        // Set cache with persistence
        await cache.set<String>(
          key: 'user_profile_1',
          data: 'Profile 1',
          toJson: (data) => data,
          config: const CacheConfig(ttl: Duration(hours: 1), persistToDisk: true),
        );

        await cache.set<String>(
          key: 'user_profile_2',
          data: 'Profile 2',
          toJson: (data) => data,
          config: const CacheConfig(ttl: Duration(hours: 1), persistToDisk: true),
        );

        // Clear memory cache to force disk read
        cache.clearMemory();

        // Invalidate pattern (should remove from disk too)
        await cache.invalidatePattern('user_profile');

        // Should not be available from disk
        final cached1 = await cache.get<String>(
          key: 'user_profile_1',
          fromJson: (json) => json as String,
          config: const CacheConfig(ttl: Duration(hours: 1), persistToDisk: true),
        );

        final cached2 = await cache.get<String>(
          key: 'user_profile_2',
          fromJson: (json) => json as String,
          config: const CacheConfig(ttl: Duration(hours: 1), persistToDisk: true),
        );

        expect(cached1, isNull);
        expect(cached2, isNull);
      });

      test('should not invalidate non-matching patterns', () async {
        await cache.set<String>(
            key: 'student_1', data: 'Student 1', toJson: (d) => d);
        await cache.set<String>(
            key: 'section_1', data: 'Section 1', toJson: (d) => d);
        await cache.set<String>(
            key: 'instructor_1', data: 'Instructor 1', toJson: (d) => d);

        // Invalidate only student pattern
        await cache.invalidatePattern('student');

        // Student should be invalidated
        expect(
            await cache.get<String>(
                key: 'student_1', fromJson: (j) => j as String),
            isNull);

        // Others should remain
        expect(
            await cache.get<String>(
                key: 'section_1', fromJson: (j) => j as String),
            'Section 1');
        expect(
            await cache.get<String>(
                key: 'instructor_1', fromJson: (j) => j as String),
            'Instructor 1');
      });
    });

    group('TTL Verification', () {
      test('veryShort TTL (5 min) should expire correctly', () async {
        final entry = CacheEntry<String>(
          data: 'test',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
          ttl: CacheConfig.veryShort.ttl,
        );
        expect(entry.isExpired, true);
      });

      test('short TTL (15 min) should expire correctly', () async {
        final entry = CacheEntry<String>(
          data: 'test',
          timestamp: DateTime.now().subtract(const Duration(minutes: 16)),
          ttl: CacheConfig.short.ttl,
        );
        expect(entry.isExpired, true);
      });

      test('medium TTL (1 hour) should expire correctly', () async {
        final entry = CacheEntry<String>(
          data: 'test',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ttl: CacheConfig.medium.ttl,
        );
        expect(entry.isExpired, true);
      });

      test('long TTL (6 hours) should expire correctly', () async {
        final entry = CacheEntry<String>(
          data: 'test',
          timestamp: DateTime.now().subtract(const Duration(hours: 7)),
          ttl: CacheConfig.long.ttl,
        );
        expect(entry.isExpired, true);
      });
    });

    group('Serialization Edge Cases', () {
      test('should handle empty lists', () async {
        final testData = <String>[];

        await cache.set<List<String>>(
          key: 'empty_list',
          data: testData,
          toJson: (data) => data,
        );

        final cached = await cache.get<List<String>>(
          key: 'empty_list',
          fromJson: (json) => (json as List).map((e) => e as String).toList(),
        );

        expect(cached, isEmpty);
      });

      test('should handle empty maps', () async {
        final testData = <String, String>{};

        await cache.set<Map<String, String>>(
          key: 'empty_map',
          data: testData,
          toJson: (data) => data,
        );

        final cached = await cache.get<Map<String, String>>(
          key: 'empty_map',
          fromJson: (json) => (json as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String)),
        );

        expect(cached, isEmpty);
      });

      test('should handle null values in maps', () async {
        final testData = {
          'key1': 'value1',
          'key2': null,
          'key3': 'value3',
        };

        await cache.set<Map<String, dynamic>>(
          key: 'map_with_nulls',
          data: testData,
          toJson: (data) => data,
        );

        final cached = await cache.get<Map<String, dynamic>>(
          key: 'map_with_nulls',
          fromJson: (json) => json as Map<String, dynamic>,
        );

        expect(cached!['key1'], 'value1');
        expect(cached['key2'], isNull);
        expect(cached['key3'], 'value3');
      });
    });
  });
}
