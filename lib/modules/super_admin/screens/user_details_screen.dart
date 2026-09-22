import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../main.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> user = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final snapshot =
      await FirebaseDatabase.instance.ref('users/${widget.userId}').get();

      if (snapshot.exists) {
        user = Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _get(String key) {
    final value = user[key];
    if (value == null) return '';
    return value.toString();
  }

  String get _photoUrl {
    final p = user['photoUrl'] ?? user['profileImage'] ?? '';
    return p.toString();
  }

  Future<void> _updateStatus(String status) async {
    await FirebaseDatabase.instance
        .ref('users/${widget.userId}/status')
        .set(status);

    setState(() => user['status'] = status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(status == 'active' ? 'User Activated' : 'User Deactivated'),
          backgroundColor:
          status == 'active' ? const Color(0xFF1D9E75) : Colors.orange,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User?'),
        content: Text(
          'This will permanently remove "${_get('name')}" from the database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseDatabase.instance.ref('users/${widget.userId}').remove();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final status = _get('status').isEmpty ? 'active' : _get('status');
    final isActive = status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && user.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'activate') _updateStatus('active');
                if (value == 'deactivate') _updateStatus('inactive');
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                if (!isActive)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Text('Activate'),
                  ),
                if (isActive)
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Deactivate'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
        onRefresh: _loadUser,
        color: AppColors.primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 900 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeader(isActive, status),
                      const SizedBox(height: 24),
                      isWide
                          ? Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSectionCard(
                              isDark: isDark,
                              title: 'Personal Details',
                              icon:
                              Icons.person_outline_rounded,
                              rows: [
                                _row(isDark, Icons.person,
                                    'Full Name',
                                    _get('name')),
                                _row(isDark, Icons.email,
                                    'Email', _get('email')),
                                _row(isDark, Icons.phone,
                                    'Phone', _get('phone')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSectionCard(
                              isDark: isDark,
                              title: 'Location',
                              icon:
                              Icons.location_on_outlined,
                              rows: [
                                _row(isDark, Icons.home,
                                    'Address',
                                    _get('address')),
                                _row(
                                    isDark,
                                    Icons.location_city,
                                    'City',
                                    _get('city')),
                                _row(isDark, Icons.pin_drop,
                                    'Pincode',
                                    _get('pincode')),
                              ],
                            ),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          _buildSectionCard(
                            isDark: isDark,
                            title: 'Personal Details',
                            icon: Icons.person_outline_rounded,
                            rows: [
                              _row(isDark, Icons.person,
                                  'Full Name', _get('name')),
                              _row(isDark, Icons.email,
                                  'Email', _get('email')),
                              _row(isDark, Icons.phone,
                                  'Phone', _get('phone')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            isDark: isDark,
                            title: 'Location',
                            icon: Icons.location_on_outlined,
                            rows: [
                              _row(isDark, Icons.home,
                                  'Address', _get('address')),
                              _row(isDark, Icons.location_city,
                                  'City', _get('city')),
                              _row(isDark, Icons.pin_drop,
                                  'Pincode',
                                  _get('pincode')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'Account Information',
                        icon: Icons.admin_panel_settings_outlined,
                        rows: [
                          _row(isDark, Icons.badge, 'Account Type',
                              _get('accountType').isEmpty
                                  ? 'User'
                                  : _get('accountType')),
                          _row(isDark, Icons.verified, 'Status',
                              status[0].toUpperCase() +
                                  status.substring(1)),
                          _row(isDark, Icons.calendar_today,
                              'Joined On',
                              _formatDate(_get('createdAt'))),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 60,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'User details not found',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isActive, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF7A72D6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white.withOpacity(.15),
              backgroundImage:
              _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
              child: _photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 42, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _get('name').isEmpty ? 'Unnamed User' : _get('name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _get('email'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(.85)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isActive ? const Color(0xFF1D9E75) : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isActive ? const Color(0xFF1D9E75) : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .3,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Divider(
            height: 22,
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(bool isDark, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }
}