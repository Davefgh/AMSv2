import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/register_user_modal.dart';
import '../../../services/api_service.dart';
import '../../../models/app_user.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../utils/responsive.dart';
import '../../../config/routes/app_routes.dart';
import '../../../widgets/skeleton_loader.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ApiService _apiService = ApiService();
  List<AppUser> _users = [];
  bool _isLoading = true;
  bool _adminDataBusy = false;

  int _selectedLimit = 5;
  String _selectedRole = 'All';

  static const List<String> _adminDataEntities = [
    'users',
    'students',
    'instructors',
    'sections',
    'subjects',
    'schedules',
    'courses',
    'classrooms',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshUsers() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Admin',
      currentIndex: 3,
      actions: [
        Row(
          children: [
            PopupMenuButton<String>(
              tooltip: 'Data Management',
              icon: _adminDataBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      Icons.swap_vert_rounded,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
              onSelected: (value) {
                if (value == 'export') {
                  _openAdminDataExport();
                } else if (value == 'import') {
                  _openAdminDataImport();
                }
              },
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 50),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Import Data',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Export Data',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.pushNamed(context, AppRoutes.profile);
                } else if (value == 'edit_profile') {
                  Navigator.pushNamed(context, AppRoutes.editProfile);
                } else if (value == 'health') {
                  Navigator.pushNamed(context, AppRoutes.health);
                } else if (value == 'logout') {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                }
              },
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 50),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Profile', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'edit_profile',
                  child: Text('Edit Profile',
                      style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'health',
                  child: Text('Health', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Log out',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF38BDF8),
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
            ),
          ],
        ),
      ],
      body: RefreshIndicator(
        color: const Color(0xFF38BDF8),
        onRefresh: () async {
          await _refreshUsers();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            _buildSectionTitle('User Growth'),
            const SizedBox(height: 16),
            _buildUserGrowthChart(),
            const SizedBox(height: 32),
            _buildSectionTitle(
              'Role Distribution',
              trailing: _buildAddButton(),
            ),
            const SizedBox(height: 16),
            _buildRoleCards(),
            const SizedBox(height: 32),
            _buildSectionTitle('Recently Added', trailing: _buildFilters()),
            const SizedBox(height: 16),
            _buildRecentUsersList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEntity(String entity) {
    switch (entity.toLowerCase()) {
      case 'users':
        return Icons.people_outline_rounded;
      case 'students':
        return Icons.workspace_premium_outlined;
      case 'instructors':
        return Icons.badge_outlined;
      case 'sections':
        return Icons.view_module_rounded;
      case 'subjects':
        return Icons.menu_book_rounded;
      case 'schedules':
        return Icons.calendar_month_rounded;
      case 'courses':
        return Icons.account_tree_outlined;
      case 'classrooms':
        return Icons.meeting_room_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Future<String?> _pickEntity(BuildContext context, {required String title}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.65),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.hub_outlined,
                              color: Color(0xFF38BDF8), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: _adminDataEntities.length,
                        itemBuilder: (_, i) {
                          final e = _adminDataEntities[i];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx, e),
                              borderRadius: BorderRadius.circular(16),
                              splashColor: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.3),
                              highlightColor: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.1),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIconForEntity(e),
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.8),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        e[0].toUpperCase() + e.substring(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAdminDataExport() async {
    final entity = await _pickEntity(context, title: 'Export which entity?');
    if (entity == null) return;

    setState(() => _adminDataBusy = true);
    try {
      final result = await _apiService.getAdminDataExport(entity);
      final pretty = const JsonEncoder.withIndent('  ').convert(result);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Export: $entity',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: pretty));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export copied to clipboard.'),
                      backgroundColor: Color(0xFF34D399),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _adminDataBusy = false);
    }
  }

  Future<void> _openAdminDataImport() async {
    final entity =
        await _pickEntity(context, title: 'Import into which entity?');
    if (entity == null) return;

    final controller = TextEditingController();
    bool isBusy = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          Future<void> runPreview() async {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            dynamic parsed;
            try {
              parsed = jsonDecode(text);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid JSON: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            setModalState(() => isBusy = true);
            try {
              final result = await _apiService.postAdminDataImportPreview(
                entity,
                {'data': parsed},
              );
              final pretty = const JsonEncoder.withIndent('  ').convert(result);
              if (!ctx.mounted) return;
              await showDialog<void>(
                context: context,
                builder: (dctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  title: Text('Import preview: $entity',
                      style: const TextStyle(color: Colors.white)),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        pretty,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preview failed: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } finally {
              if (ctx.mounted) setModalState(() => isBusy = false);
            }
          }

          Future<void> runImport() async {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            dynamic parsed;
            try {
              parsed = jsonDecode(text);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid JSON: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            setModalState(() => isBusy = true);
            try {
              await _apiService.postAdminDataImport(entity, {'data': parsed});
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import submitted.'),
                  backgroundColor: Color(0xFF34D399),
                ),
              );
              await _refreshUsers();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Import failed: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } finally {
              if (ctx.mounted) setModalState(() => isBusy = false);
            }
          }

          Future<void> loadTemplate() async {
            setModalState(() => isBusy = true);
            try {
              final result = await _apiService.getAdminDataTemplate(entity);
              final pretty = const JsonEncoder.withIndent('  ').convert(result);
              controller.text = pretty;
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template failed: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } finally {
              if (ctx.mounted) setModalState(() => isBusy = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Import: $entity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isBusy ? null : () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                  Text(
                    'Paste JSON then Preview or Import. Tip: load Template to get the expected shape.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 6,
                    maxLines: 12,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Paste JSON here…',
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: isBusy ? null : loadTemplate,
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Template'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (isBusy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: isBusy ? null : runPreview,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: const Text('Preview'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isBusy ? null : runImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        child: const Text('Import'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const RegisterUserModal(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFF38BDF8).withValues(alpha: 0.1),
        splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF38BDF8),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return _GlassCard(
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Users',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _users.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: Colors.greenAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+14%',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 100,
            child: Row(
              children: [
                // Y-axis
                const Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('5',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('0',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 16),
                // Chart
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (index) => Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1),
                        ),
                      ),
                      // Custom Curve Graph
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedChartPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov']
                  .map((e) => Text(e,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCards() {
    final students =
        _users.where((u) => u.role.toLowerCase() == 'student').length;
    final instructors = _users
        .where((u) =>
            u.role.toLowerCase() == 'instructor' ||
            u.role.toLowerCase() == 'teacher')
        .length;
    final admins = _users
        .where((u) =>
            u.role.toLowerCase() == 'admin' ||
            u.role.toLowerCase() == 'administrator')
        .length;

    return Row(
      children: [
        Expanded(
            child: _buildSingleRoleCard('Students', students.toString(),
                Icons.school, const Color(0xFF34D399))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSingleRoleCard('Teachers', instructors.toString(),
                Icons.person, const Color(0xFF60A5FA))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSingleRoleCard('Admins', admins.toString(),
                Icons.admin_panel_settings, const Color(0xFFA78BFA))),
      ],
    );
  }

  Widget _buildSingleRoleCard(
      String title, String count, IconData icon, Color color) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ['All', 'Student', 'Instructor', 'Admin']
                      .contains(_selectedRole)
                  ? _selectedRole
                  : 'All',
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white70, size: 16),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              isDense: true,
              items:
                  ['All', 'Student', 'Instructor', 'Admin'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: [5, 10, 15].contains(_selectedLimit) ? _selectedLimit : 10,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white70, size: 16),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              isDense: true,
              items: [5, 10, 15].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value'),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLimit = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    if (_isLoading) {
      return const SkeletonListView(itemCount: 5, padding: EdgeInsets.zero);
    }

    List<AppUser> filteredUsers = _users;
    if (_selectedRole != 'All') {
      filteredUsers = filteredUsers.where((u) {
        final r = u.role.toLowerCase();
        if (_selectedRole == 'Admin') {
          return r == 'admin' || r == 'administrator';
        } else if (_selectedRole == 'Instructor') {
          return r == 'instructor' || r == 'teacher';
        }
        return r == _selectedRole.toLowerCase();
      }).toList();
    }

    filteredUsers = filteredUsers.take(_selectedLimit).toList();

    if (filteredUsers.isEmpty) {
      return _GlassCard(
        child: Center(
          child: Text(
            'No matching users found',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return _GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredUsers.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withValues(alpha: 0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final color = _getRoleColor(user.role);

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(_getRoleIcon(user.role), color: color, size: 24),
            ),
            title: Text(
              user.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              user.role,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            trailing: Text(
              'Active',
              style: TextStyle(
                color: Colors.greenAccent.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return const Color(0xFFA78BFA);
      case 'instructor':
      case 'teacher':
        return const Color(0xFF60A5FA);
      case 'student':
        return const Color(0xFF34D399);
      default:
        return Colors.white70;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return Icons.admin_panel_settings_rounded;
      case 'instructor':
      case 'teacher':
        return Icons.person_rounded;
      case 'student':
        return Icons.school_rounded;
      default:
        return Icons.people_alt_rounded;
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 3, // Users tab
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_rounded), label: 'Enrollment'),
          BottomNavigationBarItem(
              icon: Icon(Icons.class_rounded), label: 'Classes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Users'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/enrollment');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/classes');
          }
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CurvedChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Smooth sample data simulating growth
    final data = [2.0, 2.5, 3.2, 4.0, 5.5, 7.0, 7.8, 8.5, 9.2, 9.8, 10.0];
    const maxData = 12.0;

    final xStep = size.width / (data.length - 1);

    path.moveTo(0, size.height - (data[0] / maxData) * size.height);

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * xStep;
      final y1 = size.height - (data[i] / maxData) * size.height;
      final x2 = (i + 1) * xStep;
      final y2 = size.height - (data[i + 1] / maxData) * size.height;

      final ctrl1X = x1 + (x2 - x1) / 2;
      final ctrl1Y = y1;
      final ctrl2X = x1 + (x2 - x1) / 2;
      final ctrl2Y = y2;

      path.cubicTo(ctrl1X, ctrl1Y, ctrl2X, ctrl2Y, x2, y2);
    }

    // Draw main line
    canvas.drawPath(path, paint);

    // Draw gradient fill below
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.4),
          const Color(0xFF38BDF8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
