import 'package:digitalads/modules/super_admin/screens/view_admins_screen.dart';
import 'package:digitalads/modules/super_admin/screens/view_all_ads_screen.dart';
import 'package:digitalads/modules/super_admin/screens/view_sellers_screen.dart';
import 'package:digitalads/modules/super_admin/screens/view_users_screen.dart';
import 'package:digitalads/modules/super_admin/screens/withdrawal_requests_screen.dart';
import 'package:flutter/material.dart';
import 'create_admin_screen.dart' ;
import 'package:firebase_database/firebase_database.dart';
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});


  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {

  int totalUsers = 0;
  int totalSellers = 0;
  int totalAdmins = 0;
  int totalAds = 0;
  @override
  void initState() {
    super.initState();
    loadCounts();
  }
  Future<void> loadCounts() async {
    // USERS
    final usersSnapshot =
    await FirebaseDatabase.instance.ref('users').get();

    if (usersSnapshot.exists) {
      final users =
      Map<dynamic, dynamic>.from(usersSnapshot.value as Map);

      totalUsers = users.values.where((user) {
        final data = Map<String, dynamic>.from(user);
        return data['accountType'] == 'normal';
      }).length;

      totalSellers = users.values.where((user) {
        final data = Map<String, dynamic>.from(user);
        return data['accountType'] == 'seller';
      }).length;
    }

    // ADMINS
    final adminSnapshot =
    await FirebaseDatabase.instance.ref('admins').get();

    if (adminSnapshot.exists) {
      final admins =
      Map<dynamic, dynamic>.from(adminSnapshot.value as Map);

      totalAdmins = admins.length;
    }

    // ADS
    final adsSnapshot =
    await FirebaseDatabase.instance.ref('ads').get();

    if (adsSnapshot.exists) {
      final ads =
      Map<dynamic, dynamic>.from(adsSnapshot.value as Map);

      totalAds = ads.length;
    }

    setState(() {});
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        centerTitle: true,
        title: const Text(
          'Digital Ads',
          style: TextStyle(color: Colors.white),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout, color: Colors.white),
        //     onPressed: () async {
        //       await FirebaseAuth.instance.signOut();
        //       if (context.mounted) {
        //         Navigator.pushAndRemoveUntil(
        //           context,
        //           MaterialPageRoute(
        //             builder: (_) => const RoleSelectionScreen(),
        //           ),
        //               (route) => false,
        //         );
        //       }
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Super Admin! 👑',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 24),
                // Row(
                //   children: [
                //     _statCard(
                //       icon: Icons.store,
                //       label: 'Business Admins',
                //       count: '0',
                //       color: Colors.orange,
                //     ),
                //     const SizedBox(width: 16),
                //     _statCard(
                //       icon: Icons.people,
                //       label: 'Total Users',
                //       count: '0',
                //       color: Colors.blue,
                //     ),
                //   ],
                // ),
                Row(
                  children: [
                    _statCard(
                      icon: Icons.store,
                      label: 'Business Admins',
                      count: totalAdmins.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      icon: Icons.people,
                      label: 'Users',
                      count: totalUsers.toString(),
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                    
                Row(
                  children: [
                    _statCard(
                      icon: Icons.shopping_bag,
                      label: 'Sellers',
                      count: totalSellers.toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      icon: Icons.campaign,
                      label: 'Ads',
                      count: totalAds.toString(),
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                    
                const SizedBox(height: 16),
                _actionButton(
                  icon: Icons.person_add,
                  label: 'Create Business Admin',
                  color: Colors.purple,
                  onTap: () {Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAdminScreen(),
                    ),
                  );},
                ),
                const SizedBox(height: 12),
                _actionButton(
                  icon: Icons.list,
                  label: 'View All Business Admins',
                  color: Colors.purple,
                  onTap: () { Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewAdminsScreen(),
                    ),
                  );},
                ),
                const SizedBox(height: 12),
                _actionButton(
                  icon: Icons.account_balance_wallet,
                  label: 'Withdrawal Requests',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WithdrawalRequestsScreen(),
                      ),
                    );
                  },
                ),
                _actionButton(
                  icon: Icons.people,
                  label: 'View Users',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewUsersScreen(),
                      ),
                    );
                  },
                ),
                _actionButton(
                  icon: Icons.store,
                  label: 'View Sellers',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewSellersScreen(),
                      ),
                    );
                  },
                ),
                _actionButton(
                  icon: Icons.campaign,
                  label: 'View All Ads',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewAllAdsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}