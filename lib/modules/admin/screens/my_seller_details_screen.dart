import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../main.dart';

class MySellerDetailsScreen extends StatefulWidget {
  final String sellerKey;

  const MySellerDetailsScreen({super.key, required this.sellerKey});

  @override
  State<MySellerDetailsScreen> createState() => _MySellerDetailsScreenState();
}

class _MySellerDetailsScreenState extends State<MySellerDetailsScreen> {
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
          .ref('sellers/${widget.sellerKey}')
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

  Future<void> _updateStatus(String status) async {
    final label = status == 'active' ? 'Activate' : 'Deactivate';
    final confirm = await showConfirmDialog(
      context,
      title: '$label Seller',
      message: 'Are you sure you want to ${label.toLowerCase()} this seller?',
    );
    if (!confirm) return;

    await FirebaseDatabase.instance
        .ref('sellers/${widget.sellerKey}/status')
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
      message:
      'Are you sure you want to delete "${_get('shopName')}"? This cannot be undone.',
    );
    if (!confirm) return;

    await FirebaseDatabase.instance
        .ref('sellers/${widget.sellerKey}')
        .remove();

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
                      const SizedBox(height: 24),
                      isWide
                          ? Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSectionCard(
                              isDark: isDark,
                              title: 'Shop Details',
                              icon: Icons.storefront_outlined,
                              rows: [
                                _row(isDark, Icons.store,
                                    'Shop Name',
                                    _get('shopName')),
                                _row(isDark, Icons.category,
                                    'Category',
                                    _get('category')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSectionCard(
                              isDark: isDark,
                              title: 'Owner Details',
                              icon:
                              Icons.person_outline_rounded,
                              rows: [
                                _row(isDark, Icons.person,
                                    'Owner Name',
                                    _get('ownerName')),
                                _row(isDark, Icons.phone,
                                    'Phone', _get('phone')),
                              ],
                            ),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          _buildSectionCard(
                            isDark: isDark,
                            title: 'Shop Details',
                            icon: Icons.storefront_outlined,
                            rows: [
                              _row(isDark, Icons.store,
                                  'Shop Name',
                                  _get('shopName')),
                              _row(isDark, Icons.category,
                                  'Category',
                                  _get('category')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            isDark: isDark,
                            title: 'Owner Details',
                            icon: Icons.person_outline_rounded,
                            rows: [
                              _row(isDark, Icons.person,
                                  'Owner Name',
                                  _get('ownerName')),
                              _row(isDark, Icons.phone,
                                  'Phone', _get('phone')),
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
                          _row(isDark, Icons.verified, 'Status',
                              status[0].toUpperCase() +
                                  status.substring(1)),
                          _row(isDark, Icons.calendar_today,
                              'Added On',
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
            Icons.storefront_outlined,
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
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _get('shopName').isEmpty ? 'Unnamed Shop' : _get('shopName'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _get('ownerName'),
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