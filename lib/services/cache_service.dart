import 'dart:convert';
import 'package:logger/logger.dart';
import 'storage_service.dart';

/// Cache entry with data and metadata
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }

  Map<String, dynamic> toJson(dynamic Function(T) toJsonT) {
    return {
      'data': toJsonT(data),
      'timestamp': timestamp.toIso8601String(),
      'ttlSeconds': ttl.inSeconds,
    };
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return CacheEntry(
      data: fromJsonT(json['data']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: Duration(seconds: json['ttlSeconds'] as int),
    );
  }
}

/// Cache configuration for different data types
class CacheConfig {
  final Duration ttl;
  final bool persistToDisk;
  final bool useMemoryCache;

  const CacheConfig({
    required this.ttl,
    this.persistToDisk = true,
    this.useMemoryCache = true,
  });

  // Predefined cache configurations
  static const CacheConfig veryShort = CacheConfig(
    ttl: Duration(minutes: 5),
    persistToDisk: false,
  );

  static const CacheConfig short = CacheConfig(
    ttl: Duration(minutes: 15),
  );

  static const CacheConfig medium = CacheConfig(
    ttl: Duration(hours: 1),
  );

  static const CacheConfig long = CacheConfig(
    ttl: Duration(hours: 6),
  );

  static const CacheConfig veryLong = CacheConfig(
    ttl: Duration(days: 1),
  );

  static const CacheConfig persistent = CacheConfig(
    ttl: Duration(days: 7),
  );
}

/// Service for caching API responses
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Logger _logger = Logger();

  // In-memory cache
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};

  // Cache key prefix for persistent storage
  static const String _cachePrefix = 'cache_';

  /// Get cached data with automatic expiration check
  Future<T?> get<T>({
    required String key,
    required T Function(dynamic) fromJson,
    CacheConfig config = CacheConfig.medium,
  }) async {
    try {
      // Check memory cache first
      if (config.useMemoryCache && _memoryCache.containsKey(key)) {
        final entry = _memoryCache[key] as CacheEntry<T>?;
        if (entry != null && !entry.isExpired) {
          _logger.d('Cache HIT (memory): $key');
          return entry.data;
        } else {
          _memoryCache.remove(key);
        }
      }

      // Check persistent cache
      if (config.persistToDisk) {
        final cached = StorageService.getString('$_cachePrefix$key');
        if (cached != null) {
          final json = jsonDecode(cached) as Map<String, dynamic>;
          final entry = CacheEntry<T>.fromJson(json, fromJson);

          if (!entry.isExpired) {
            _logger.d('Cache HIT (disk): $key');
            // Restore to memory cache
            if (config.useMemoryCache) {
              _memoryCache[key] = entry;
            }
            return entry.data;
          } else {
            // Remove expired cache
            await StorageService.remove('$_cachePrefix$key');
          }
        }
      }

      _logger.d('Cache MISS: $key');
      return null;
    } catch (e) {
      _logger.e('Cache get error for $key: $e');
      return null;
    }
  }

  /// Set cached data
  Future<void> set<T>({
    required String key,
    required T data,
    required dynamic Function(T) toJson,
    CacheConfig config = CacheConfig.medium,
  }) async {
    try {
      final entry = CacheEntry<T>(
        data: data,
        timestamp: DateTime.now(),
        ttl: config.ttl,
      );

      // Store in memory cache
      if (config.useMemoryCache) {
        _memoryCache[key] = entry;
      }

      // Store in persistent cache
      if (config.persistToDisk) {
        final json = entry.toJson(toJson);
        await StorageService.setString(
          '$_cachePrefix$key',
          jsonEncode(json),
        );
      }

      _logger.d('Cache SET: $key (TTL: ${config.ttl})');
    } catch (e) {
      _logger.e('Cache set error for $key: $e');
    }
  }

  /// Get or fetch data with caching
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    required T Function(dynamic) fromJson,
    required dynamic Function(T) toJson,
    CacheConfig config = CacheConfig.medium,
  }) async {
    // Try to get from cache
    final cached = await get<T>(
      key: key,
      fromJson: fromJson,
      config: config,
    );

    if (cached != null) {
      return cached;
    }

    // Fetch from API
    _logger.d('Fetching fresh data for: $key');
    final data = await fetcher();

    // Cache the result
    await set<T>(
      key: key,
      data: data,
      toJson: toJson,
      config: config,
    );

    return data;
  }

  /// Invalidate specific cache entry
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await StorageService.remove('$_cachePrefix$key');
    _logger.d('Cache INVALIDATED: $key');
  }

  /// Invalidate multiple cache entries by pattern
  Future<void> invalidatePattern(String pattern) async {
    // Remove from memory cache
    final memoryKeysToRemove =
        _memoryCache.keys.where((key) => key.contains(pattern)).toList();

    for (final key in memoryKeysToRemove) {
      _memoryCache.remove(key);
    }

    // Remove from persistent cache
    final allKeys = StorageService.getAllKeys();
    final persistentKeysToRemove = allKeys
        .where((key) => key.startsWith(_cachePrefix))
        .where((key) => key.substring(_cachePrefix.length).contains(pattern))
        .toList();

    for (final key in persistentKeysToRemove) {
      await StorageService.remove(key);
    }

    final totalRemoved =
        memoryKeysToRemove.length + persistentKeysToRemove.length;
    _logger.d('Cache INVALIDATED (pattern): $pattern ($totalRemoved entries)');
  }

  /// Clear all cache entries (only removes cache keys, not other storage)
  Future<void> clearAll() async {
    _memoryCache.clear();

    // Get all keys from SharedPreferences
    final allKeys = StorageService.getAllKeys();

    // Remove only cache keys (those with cache prefix)
    final cacheKeys = allKeys.where((key) => key.startsWith(_cachePrefix)).toList();
    for (final key in cacheKeys) {
      await StorageService.remove(key);
    }

    _logger.d('Cache CLEARED (${cacheKeys.length} entries)');
  }

  /// Clear only memory cache (keep persistent cache)
  void clearMemory() {
    _memoryCache.clear();
    _logger.d('Memory cache CLEARED');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'memoryCacheKeys': _memoryCache.keys.toList(),
    };
  }

  /// Preload cache with data (useful for app initialization)
  Future<void> preload<T>({
    required String key,
    required Future<T> Function() fetcher,
    required T Function(dynamic) fromJson,
    required dynamic Function(T) toJson,
    CacheConfig config = CacheConfig.medium,
  }) async {
    try {
      // Check if cache exists and is valid
      final cached = await get<T>(
        key: key,
        fromJson: fromJson,
        config: config,
      );

      if (cached != null) {
        _logger.d('Preload skipped (cache valid): $key');
        return;
      }

      // Fetch and cache
      _logger.d('Preloading: $key');
      final data = await fetcher();
      await set<T>(
        key: key,
        data: data,
        toJson: toJson,
        config: config,
      );
    } catch (e) {
      _logger.e('Preload error for $key: $e');
    }
  }
}

/// Cache keys for different data types
class CacheKeys {
  // Static data (long TTL)
  static const String sections = 'sections';
  static const String subjects = 'subjects';
  static const String courses = 'courses';
  static const String classrooms = 'classrooms';
  static const String instructors = 'instructors';
  static const String students = 'students';

  // User-specific data (medium TTL)
  static const String mySchedules = 'my_schedules';
  static const String mySessions = 'my_sessions';
  static const String mySubjects = 'my_subjects';
  static const String instructorProfile = 'instructor_profile';
  static const String studentProfile = 'student_profile';
  static const String userProfile = 'user_profile';

  // Dynamic data (short TTL)
  static const String sessions = 'sessions';
  static const String schedules = 'schedules';
  static const String enrollments = 'enrollments';

  // Health checks (very short TTL)
  static const String health = 'health';
  static const String healthReady = 'health_ready';

  // Parameterized cache keys
  static String sectionStudents(String sectionId) =>
      'section_students_$sectionId';
  static String sectionSchedules(String sectionId) =>
      'section_schedules_$sectionId';
  static String studentEnrollments(String studentId) =>
      'student_enrollments_$studentId';
  static String sessionAttendance(String sessionId) =>
      'session_attendance_$sessionId';
  static String studentAttendance(String studentId) =>
      'student_attendance_$studentId';
  static String studentFingerprints(String studentId) =>
      'student_fingerprints_$studentId';
  static String deviceFingerprints(String deviceId) =>
      'device_fingerprints_$deviceId';
}
