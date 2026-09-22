import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../main.dart';

class SellerDetailsScreen extends StatefulWidget {
  final String sellerId;

  const SellerDetailsScreen({super.key, required this.sellerId});

  @override
  State<SellerDetailsScreen> createState() => _SellerDetailsScreenState();
}

class _SellerDetailsScreenState extends State<SellerDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> seller = {};

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${widget.sellerId}')
          .get();

      if (snapshot.exists) {
        seller = Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _get(String key) {
    final value = seller[key];
    if (value == null) return '';
    return value.toString();
  }

  String get _photoUrl {
    final p = seller['photoUrl'] ?? seller['profileImage'] ?? '';
    return p.toString();
  }

  Future<void> _updateStatus(String status) async {
    final label = status == 'active' ? 'Activate' : 'Deactivate';
    final confirm = await showConfirmDialog(
      context,
      title: '$label Seller',
      message: 'Are you sure you want to ${label.toLowerCase()} this seller?',
    );
    if (!confirm) return;

    await FirebaseDatabase.instance
        .ref('users/${widget.sellerId}/status')
        .set(status);

    setState(() => seller['status'] = status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              status == 'active' ? 'Seller Activated' : 'Seller Deactivated'),
          backgroundColor:
          status == 'active' ? const Color(0xFF1D9E75) : Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteSeller() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Seller',
      message: 'Are you sure you want to delete this seller?',
    );
    if (!confirm) return;

    await FirebaseDatabase.instance.ref('users/${widget.sellerId}').remove();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller Deleted'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
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
          'Seller Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && seller.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'activate') _updateStatus('active');
                if (value == 'deactivate') _updateStatus('inactive');
                if (value == 'delete') _deleteSeller();
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
          : seller.isEmpty
          ? _buildEmptyState(isDark)
          : RefreshIndicator(
        onRefresh: _loadSeller,
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
                      const SizedBox(height: 18),
                      _buildStatsRow(isDark),
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
                                _row(isDark, Icons.cake,
                                    'Age', _get('age')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSectionCard(
                              isDark: isDark,
                              title: 'Shop / Business',
                              icon: Icons.storefront_outlined,
                              rows: [
                                _row(isDark, Icons.store,
                                    'Shop Name',
                                    _get('shopName')),
                                _row(
                                    isDark,
                                    Icons.location_on,
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
                              _row(isDark, Icons.cake, 'Age',
                                  _get('age')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            isDark: isDark,
                            title: 'Shop / Business',
                            icon: Icons.storefront_outlined,
                            rows: [
                              _row(isDark, Icons.store,
                                  'Shop Name',
                                  _get('shopName')),
                              _row(isDark, Icons.location_on,
                                  'Address',
                                  _get('address')),
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
                                  ? 'Seller'
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
            Icons.store_mall_directory_outlined,
            size: 60,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Seller details not found',
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
                  ? const Icon(Icons.store_rounded,
                  size: 40, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _get('name').isEmpty ? 'Unnamed Seller' : _get('name'),
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
            style:
            TextStyle(fontSize: 13, color: Colors.white.withOpacity(.85)),
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

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.inventory_2_outlined,
            color: Colors.blue,
            label: 'Products',
            value:
            _get('productsCount').isEmpty ? '0' : _get('productsCount'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.shopping_bag_outlined,
            color: Colors.orange,
            label: 'Orders',
            value: _get('ordersCount').isEmpty ? '0' : _get('ordersCount'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.cake_outlined,
            color: AppColors.primary,
            label: 'Age',
            value: _get('age').isEmpty ? '-' : _get('age'),
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
              fontSize: small ? 13 : 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
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