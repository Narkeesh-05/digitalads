import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../main.dart';

class BusinessAdminDetailsScreen extends StatefulWidget {
  final String adminId;

  const BusinessAdminDetailsScreen({super.key, required this.adminId});

  @override
  State<BusinessAdminDetailsScreen> createState() =>
      _BusinessAdminDetailsScreenState();
}

class _BusinessAdminDetailsScreenState
    extends State<BusinessAdminDetailsScreen> {
  bool _isLoading = true;

  Map<String, dynamic> admin = {};

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    try {
      debugPrint("Admin ID: ${widget.adminId}");

      final snapshot = await FirebaseDatabase.instance
          .ref('admins/${widget.adminId}')
          .get();

      debugPrint("Admin exists: ${snapshot.exists}");
      debugPrint("Admin data: ${snapshot.value}");

      if (snapshot.exists && snapshot.value != null) {
        admin = Map<String, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
      }
    } catch (e) {
      debugPrint("Admin loading error: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _get(String key) {
    final value = admin[key];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  String get _photoUrl {
    final value = admin['photoUrl'] ?? admin['profileImage'] ?? '';

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    final status = _get('status').isEmpty ? 'active' : _get('status');

    final isActive = status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF4F5F9),

      appBar: AppBar(
        title: const Text(
          'Business Admin Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : admin.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
              onRefresh: _loadAdmin,
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
                            _buildProfileHeader(isDark, isActive, status),

                            const SizedBox(height: 18),

                            _buildStatsRow(isDark),

                            const SizedBox(height: 24),

                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildPersonalDetails(isDark),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildBusinessDetails(isDark),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildPersonalDetails(isDark),
                                  const SizedBox(height: 16),
                                  _buildBusinessDetails(isDark),
                                ],
                              ),

                            const SizedBox(height: 16),

                            _buildAddressDetails(isDark),

                            const SizedBox(height: 16),

                            _buildAccountDetails(isDark, status),

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

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business_center_outlined,
            size: 60,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          Text(
            'Business admin details not found',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE HEADER
  // ------------------------------------------------------------

  Widget _buildProfileHeader(bool isDark, bool isActive, String status) {
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
              backgroundImage: _photoUrl.isNotEmpty
                  ? NetworkImage(_photoUrl)
                  : null,
              child: _photoUrl.isEmpty
                  ? const Icon(Icons.business, size: 42, color: Colors.white)
                  : null,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _get('name').isEmpty ? 'Unnamed Admin' : _get('name'),
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(.85),
            ),
          ),

          const SizedBox(height: 4),

          if (_get('businessName').isNotEmpty)
            Text(
              _get('businessName'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(.85),
              ),
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

  // ------------------------------------------------------------
  // STATS
  // ------------------------------------------------------------

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.campaign_outlined,
            color: Colors.blue,
            label: 'Ads',
            value: _get('adsCount').isEmpty ? '0' : _get('adsCount'),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.question_answer_outlined,
            color: Colors.orange,
            label: 'Enquiries',
            value: _get('enquiryCount').isEmpty ? '0' : _get('enquiryCount'),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.phone_android_outlined,
            color: AppColors.primary,
            label: 'Phone',
            value: _get('phone').isEmpty ? '-' : _get('phone'),
            small: true,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    bool small = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 12 : 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PERSONAL DETAILS
  // ------------------------------------------------------------

  Widget _buildPersonalDetails(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Personal Details',
      icon: Icons.person_outline_rounded,
      rows: [
        _row(isDark, Icons.person, 'Full Name', _get('name')),

        _row(isDark, Icons.email, 'Email', _get('email')),

        _row(isDark, Icons.phone, 'Phone', _get('phone')),

        _row(isDark, Icons.cake_outlined, 'Age', _get('age')),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUSINESS DETAILS
  // ------------------------------------------------------------

  Widget _buildBusinessDetails(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Business Details',
      icon: Icons.business_outlined,
      rows: [
        _row(isDark, Icons.business, 'Business Name', _get('businessName')),

        _row(
          isDark,
          Icons.category_outlined,
          'Category',
          _get('businessCategory'),
        ),

        _row(isDark, Icons.badge_outlined, 'GST Number', _get('gstNumber')),
      ],
    );
  }

  // ------------------------------------------------------------
  // ADDRESS
  // ------------------------------------------------------------

  Widget _buildAddressDetails(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Business Address',
      icon: Icons.location_on_outlined,
      rows: [
        _row(isDark, Icons.home_outlined, 'Address', _get('address')),

        _row(
          isDark,
          Icons.location_city_outlined,
          'City / District',
          _get('city'),
        ),

        _row(
          isDark,
          Icons.pin_drop_outlined,
          'Pincode',
          _get('pincode').isNotEmpty ? _get('pincode') : _get('zipcode'),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ACCOUNT INFORMATION
  // ------------------------------------------------------------

  Widget _buildAccountDetails(bool isDark, String status) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Account Information',
      icon: Icons.admin_panel_settings_outlined,
      rows: [
        _row(
          isDark,
          Icons.badge,
          'Role',
          _get('role').isEmpty
              ? (_get('accountType').isEmpty
                    ? 'Business Admin'
                    : _get('accountType'))
              : _get('role'),
        ),

        _row(
          isDark,
          Icons.verified_outlined,
          'Status',
          status[0].toUpperCase() + status.substring(1),
        ),

        _row(
          isDark,
          Icons.calendar_today_outlined,
          'Created On',
          _formatDate(_get('createdAt')),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION CARD
  // ------------------------------------------------------------

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
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),

              const SizedBox(width: 9),

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

  // ------------------------------------------------------------
  // ROW
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatDate(String raw) {
    if (raw.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(raw);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return raw;
    }
  }
}
