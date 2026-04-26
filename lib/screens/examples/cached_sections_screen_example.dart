/// Example: Sections Screen with Caching
///
/// This is a complete, production-ready example showing how to implement
/// a screen with response caching, offline support, and pull-to-refresh.
///
/// Copy this pattern to other screens in your app.
library;

import 'package:flutter/material.dart';
import '../../services/cached_api_service.dart';
import '../../services/api_service.dart';
import '../../models/section_model.dart';

class CachedSectionsScreen extends StatefulWidget {
  const CachedSectionsScreen({super.key});

  @override
  State<CachedSectionsScreen> createState() => _CachedSectionsScreenState();
}

class _CachedSectionsScreenState extends State<CachedSectionsScreen> {
  final _cachedApi = CachedApiService();

  List<Section> _sections = [];
  bool _loading = true;
  bool _isOffline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  /// Load sections with caching support
  ///
  /// - First load: Checks cache, loads instantly if available
  /// - Cache miss: Fetches from API and caches result
  /// - Force refresh: Bypasses cache and fetches fresh data
  /// - Offline: Shows cached data with offline indicator
  Future<void> _loadSections({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load from cache or API
      final sections = await _cachedApi.getSections(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _sections = sections;
          _loading = false;
          _isOffline = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (e.statusCode == 0) {
            // Network error - we're offline
            _isOffline = true;
            _error = 'You are offline. Showing cached data.';
          } else {
            _error = e.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Create a new section
  ///
  /// Cache is automatically invalidated after creation
  Future<void> _createSection() async {
    // Show create dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateSectionDialog(),
    );

    if (result == null) return;

    try {
      // Create section (automatically invalidates cache)
      await _cachedApi.createSection(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section created successfully')),
        );

        // Reload with fresh data
        await _loadSections(forceRefresh: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete a section
  ///
  /// Cache is automatically invalidated after deletion
  Future<void> _deleteSection(Section section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete ${section.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete section (automatically invalidates cache)
      await _cachedApi.deleteSection(section.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section deleted successfully')),
        );

        // Reload with fresh data
        await _loadSections(forceRefresh: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sections'),
        backgroundColor: _isOffline ? Colors.grey : null,
        actions: [
          // Force refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSections(forceRefresh: true),
            tooltip: 'Force refresh from server',
          ),
          // Cache stats button (debug only)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showCacheStats,
              tooltip: 'Cache statistics',
            ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Offline mode - Showing cached data',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _loadSections(forceRefresh: true),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSection,
        tooltip: 'Create section',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    // Loading state (only show if no cached data)
    if (_loading && _sections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading sections...'),
          ],
        ),
      );
    }

    // Error state (only show if no cached data)
    if (_error != null && _sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading sections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadSections(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No sections found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _createSection,
              icon: const Icon(Icons.add),
              label: const Text('Create first section'),
            ),
          ],
        ),
      );
    }

    // List with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => _loadSections(forceRefresh: true),
      child: ListView.builder(
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          return _SectionListTile(
            section: section,
            onTap: () => _navigateToSectionDetails(section),
            onDelete: () => _deleteSection(section),
          );
        },
      ),
    );
  }

  void _navigateToSectionDetails(Section section) {
    // Navigate to section details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(section.name)),
          body: const Center(child: Text('Section Details')),
        ),
      ),
    );
  }

  void _showCacheStats() {
    final stats = _cachedApi.getCacheStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Memory cache entries: ${stats['memoryCacheSize']}'),
            const SizedBox(height: 8),
            const Text('Cached keys:'),
            ...((stats['memoryCacheKeys'] as List).map((key) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• $key', style: const TextStyle(fontSize: 12)),
                ))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Section list tile widget
class _SectionListTile extends StatelessWidget {
  final Section section;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SectionListTile({
    required this.section,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(section.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          section.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Capacity: ${section.capacity ?? "N/A"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete section',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Create section dialog
class _CreateSectionDialog extends StatefulWidget {
  @override
  State<_CreateSectionDialog> createState() => _CreateSectionDialogState();
}

class _CreateSectionDialogState extends State<_CreateSectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearLevelController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _yearLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Section'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Section Name',
                hintText: 'e.g., Section A',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a section name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearLevelController,
              decoration: const InputDecoration(
                labelText: 'Year Level',
                hintText: 'e.g., 1',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a year level';
                }
                final yearLevel = int.tryParse(value);
                if (yearLevel == null || yearLevel < 1) {
                  return 'Please enter a valid year level';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'yearLevel': int.parse(_yearLevelController.text),
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
