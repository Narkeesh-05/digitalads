
import 'dart:async';

import 'package:digitalads/modules/super_admin/screens/super_admin_drawer.dart';
import 'package:digitalads/modules/super_admin/screens/view_admins_screen.dart';
import 'package:digitalads/modules/super_admin/screens/view_all_ads_screen.dart';
import 'package:digitalads/modules/super_admin/screens/view_sellers_screen.dart';
import 'package:digitalads/modules/super_admin/screens/view_users_screen.dart';
import 'package:digitalads/modules/super_admin/screens/withdrawal_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_admin_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../app/theme.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  String _profileImageUrl = "";
  int totalUsers = 0;
  int totalSellers = 0;
  int totalAdmins = 0;
  int totalAds = 0;

  StreamSubscription<DatabaseEvent>? _usersSub;
  StreamSubscription<DatabaseEvent>? _adminsSub;
  StreamSubscription<DatabaseEvent>? _adsSub;

  @override
  void initState() {
    super.initState();
    _listenCounts();
    _loadProfileImage();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _adminsSub?.cancel();
    _adsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
    await FirebaseDatabase.instance.ref("users/$uid").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _profileImageUrl = data["photoUrl"] ?? "";
      });
    }
  }

  // Real-time listeners — counts update instantly on any add/edit/delete,
  // no matter which screen made the change.
  void _listenCounts() {
    _usersSub =
        FirebaseDatabase.instance.ref('users').onValue.listen((event) {
          if (!mounted) return;

          int users = 0;
          int sellers = 0;
          final value = event.snapshot.value;

          if (value != null) {
            final usersMap = Map<dynamic, dynamic>.from(value as Map);
            users = usersMap.values.where((user) {
              final data = Map<String, dynamic>.from(user);
              return data['accountType'] == 'normal';
            }).length;
            sellers = usersMap.values.where((user) {
              final data = Map<String, dynamic>.from(user);
              return data['accountType'] == 'seller';
            }).length;
          }

          setState(() {
            totalUsers = users;
            totalSellers = sellers;
          });
        });

    _adminsSub =
        FirebaseDatabase.instance.ref('admins').onValue.listen((event) {
          if (!mounted) return;

          final value = event.snapshot.value;
          final count =
          value != null ? Map<dynamic, dynamic>.from(value as Map).length : 0;

          setState(() {
            totalAdmins = count;
          });
        });

    _adsSub = FirebaseDatabase.instance.ref('ads').onValue.listen((event) {
      if (!mounted) return;

      final value = event.snapshot.value;
      final count =
      value != null ? Map<dynamic, dynamic>.from(value as Map).length : 0;

      setState(() {
        totalAds = count;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SuperAdminDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : null,
                child: _profileImageUrl.isEmpty
                    ? const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                )
                    : null,
              ),
            ),
          ),
        ),
        title: const Text(
          'DigitalAds',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome ────────────────────────────────────────────────
            Text(
              'Welcome, Super Admin! 👑',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your platform from here',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // ── Stat Cards ─────────────────────────────────────────────
            Row(
              children: [
                _statCard(
                  context: context,
                  icon: Icons.store_rounded,
                  label: 'Business Admins',
                  count: totalAdmins.toString(),
                  color: const Color(0xFFBA7517),
                  bgColor: const Color(0xFFFFF3CD),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ViewAdminsScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _statCard(
                  context: context,
                  icon: Icons.people_rounded,
                  label: 'Users',
                  count: totalUsers.toString(),
                  color: AppColors.primary,
                  bgColor: AppColors.primarySurface,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ViewUsersScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  context: context,
                  icon: Icons.shopping_bag_rounded,
                  label: 'Sellers',
                  count: totalSellers.toString(),
                  color: const Color(0xFF1D9E75),
                  bgColor: const Color(0xFFE3F6EF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ViewSellersScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _statCard(
                  context: context,
                  icon: Icons.campaign_rounded,
                  label: 'Total Ads',
                  count: totalAds.toString(),
                  color: const Color(0xFFE24B4A),
                  bgColor: const Color(0xFFFBEAEA),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ViewAllAdsScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}