import 'package:digitalads/modules/admin/screens/post_ad_screen.dart';
import 'package:digitalads/modules/admin/screens/view_enquiries_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'view_my_ads_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Business Admin Dashboard',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Business Admin! 🏪',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            _actionButton(
              icon: Icons.add_box,
              label: 'Post New Ad',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PostAdScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: Icons.list_alt,
              label: 'View My Ads',
              color: Colors.orange,
              onTap: () {  Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewMyAdsScreen(),
                ),
              );},
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: Icons.question_answer,
              label: 'View Enquiries',
              color: Colors.orange,
              onTap: () {Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewEnquiriesScreen(),
                ),
              );},
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