import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/services/cache_service.dart';
import 'package:amsv2/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    setUp(() async {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      cache = CacheService();
    });

    tearDown(() async {
      await cache.clearAll();
    });

    test('should cache and retrieve simple data', () async {
      final testData = {'name': 'Test', 'value': 123};

      // Set cache
      await cache.set<Map<String, dynamic>>(
        key: 'test_key',
        data: testData,
        toJson: (data) => data,
        config: CacheConfig.medium,
      );

      // Get from cache
      final cached = await cache.get<Map<String, dynamic>>(
        key: 'test_key',
        fromJson: (json) => json as Map<String, dynamic>,
        config: CacheConfig.medium,
      );

      expect(cached, isNotNull);
      expect(cached!['name'], 'Test');
      expect(cached['value'], 123);
    });

    test('should return null for non-existent cache', () async {
      final cached = await cache.get<String>(
        key: 'non_existent',
        fromJson: (json) => json as String,
      );

      expect(cached, isNull);
    });

    test('should invalidate cache entry', () async {
      const testData = 'test value';

      // Set cache
      await cache.set<String>(
        key: 'test_key',
        data: testData,
        toJson: (data) => data,
      );

      // Verify cached
      var cached = await cache.get<String>(
        key: 'test_key',
        fromJson: (json) => json as String,
      );
      expect(cached, testData);

      // Invalidate
      await cache.invalidate('test_key');

      // Verify invalidated
      cached = await cache.get<String>(
        key: 'test_key',
        fromJson: (json) => json as String,
      );
      expect(cached, isNull);
    });

    test('should handle expired cache', () async {
      const testData = 'test value';

      // Set cache with very short TTL
      await cache.set<String>(
        key: 'test_key',
        data: testData,
        toJson: (data) => data,
        config: const CacheConfig(ttl: Duration(milliseconds: 100)),
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      // Should return null for expired cache
      final cached = await cache.get<String>(
        key: 'test_key',
        fromJson: (json) => json as String,
        config: const CacheConfig(ttl: Duration(milliseconds: 100)),
      );

      expect(cached, isNull);
    });

    test('should use getOrFetch pattern', () async {
      var fetchCount = 0;

      Future<String> fetcher() async {
        fetchCount++;
        return 'fetched_value';
      }

      // First call should fetch
      final result1 = await cache.getOrFetch<String>(
        key: 'test_key',
        fetcher: fetcher,
        fromJson: (json) => json as String,
        toJson: (data) => data,
        config: CacheConfig.medium,
      );

      expect(result1, 'fetched_value');
      expect(fetchCount, 1);

      // Second call should use cache
      final result2 = await cache.getOrFetch<String>(
        key: 'test_key',
        fetcher: fetcher,
        fromJson: (json) => json as String,
        toJson: (data) => data,
        config: CacheConfig.medium,
      );

      expect(result2, 'fetched_value');
      expect(fetchCount, 1); // Should not fetch again
    });

    test('should invalidate by pattern', () async {
      // Set multiple caches
      await cache.set<String>(
        key: 'student_1',
        data: 'Student 1',
        toJson: (data) => data,
      );

      await cache.set<String>(
        key: 'student_2',
        data: 'Student 2',
        toJson: (data) => data,
      );

      await cache.set<String>(
        key: 'section_1',
        data: 'Section 1',
        toJson: (data) => data,
      );

      // Invalidate student pattern
      await cache.invalidatePattern('student');

      // Student caches should be invalidated
      final student1 = await cache.get<String>(
        key: 'student_1',
        fromJson: (json) => json as String,
      );
      expect(student1, isNull);

      final student2 = await cache.get<String>(
        key: 'student_2',
        fromJson: (json) => json as String,
      );
      expect(student2, isNull);

      // Section cache should still exist
      final section1 = await cache.get<String>(
        key: 'section_1',
        fromJson: (json) => json as String,
      );
      expect(section1, 'Section 1');
    });

    test('should track cache stats', () async {
      // Set some caches
      await cache.set<String>(
        key: 'key1',
        data: 'value1',
        toJson: (data) => data,
      );

      await cache.set<String>(
        key: 'key2',
        data: 'value2',
        toJson: (data) => data,
      );

      final stats = cache.getStats();
      expect(stats['memoryCacheSize'], 2);
      expect(stats['memoryCacheKeys'], contains('key1'));
      expect(stats['memoryCacheKeys'], contains('key2'));
    });

    test('should handle memory-only cache', () async {
      const testData = 'test value';

      // Set memory-only cache
      await cache.set<String>(
        key: 'test_key',
        data: testData,
        toJson: (data) => data,
        config: const CacheConfig(
          ttl: Duration(hours: 1),
          persistToDisk: false,
          useMemoryCache: true,
        ),
      );

      // Should be in memory cache
      final cached = await cache.get<String>(
        key: 'test_key',
        fromJson: (json) => json as String,
        config: const CacheConfig(
          ttl: Duration(hours: 1),
          persistToDisk: false,
          useMemoryCache: true,
        ),
      );

      expect(cached, testData);

      // Clear memory cache
      cache.clearMemory();

      // Should not be available after memory clear
      final cachedAfterClear = await cache.get<String>(
        key: 'test_key',
        fromJson: (json) => json as String,
        config: const CacheConfig(
          ttl: Duration(hours: 1),
          persistToDisk: false,
          useMemoryCache: true,
        ),
      );

      expect(cachedAfterClear, isNull);
    });
  });

  group('CacheKeys', () {
    test('should generate parameterized keys', () {
      expect(CacheKeys.sectionStudents('123'), 'section_students_123');
      expect(CacheKeys.studentEnrollments('456'), 'student_enrollments_456');
      expect(CacheKeys.sessionAttendance('789'), 'session_attendance_789');
    });

    test('should have static keys', () {
      expect(CacheKeys.sections, 'sections');
      expect(CacheKeys.subjects, 'subjects');
      expect(CacheKeys.mySchedules, 'my_schedules');
    });
  });

  group('CacheConfig', () {
    test('should have predefined configurations', () {
      expect(CacheConfig.veryShort.ttl, const Duration(minutes: 5));
      expect(CacheConfig.short.ttl, const Duration(minutes: 15));
      expect(CacheConfig.medium.ttl, const Duration(hours: 1));
      expect(CacheConfig.long.ttl, const Duration(hours: 6));
      expect(CacheConfig.veryLong.ttl, const Duration(days: 1));
      expect(CacheConfig.persistent.ttl, const Duration(days: 7));
    });

    test('should allow custom configuration', () {
      const custom = CacheConfig(
        ttl: Duration(minutes: 30),
        persistToDisk: false,
        useMemoryCache: true,
      );

      expect(custom.ttl, const Duration(minutes: 30));
      expect(custom.persistToDisk, false);
      expect(custom.useMemoryCache, true);
    });
  });

  group('CacheEntry', () {
    test('should detect expired entries', () {
      final entry = CacheEntry<String>(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ttl: const Duration(hours: 1),
      );

      expect(entry.isExpired, true);
    });

    test('should detect valid entries', () {
      final entry = CacheEntry<String>(
        data: 'test',
        timestamp: DateTime.now(),
        ttl: const Duration(hours: 1),
      );

      expect(entry.isExpired, false);
    });

    test('should serialize and deserialize', () {
      final entry = CacheEntry<String>(
        data: 'test value',
        timestamp: DateTime.now(),
        ttl: const Duration(hours: 1),
      );

      final json = entry.toJson((data) => data);
      final restored = CacheEntry<String>.fromJson(
        json,
        (data) => data as String,
      );

      expect(restored.data, entry.data);
      expect(restored.ttl, entry.ttl);
    });
  });
}
