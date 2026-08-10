import 'package:digitalads/modules/user/screens/user_login_screen.dart';
import 'package:digitalads/modules/user/screens/wallet_screen.dart';
import 'package:digitalads/modules/user/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../admin/screens/post_ad_screen.dart';
import '../../admin/screens/view_enquiries_screen.dart';
import '../../admin/screens/view_my_ads_screen.dart';
import 'edit_profile_screen.dart';

class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String _name = 'User';
  String _accountType = 'normal';
  String _email = '';
  String _photoUrl = '';
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
    await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _name = data['name'] ?? 'User';
        _accountType = data['accountType'] ?? 'normal';
        _points = (data['points'] ?? 0) as int;
        _email = data['email'] ?? '';
        _photoUrl = data['photoUrl'] ?? '';
      });
    }
  }

  void _goToProfile() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    ).then((_) => _loadUserData());
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ── Header with clickable avatar ─────────────────────────────
          GestureDetector(
            onTap: _goToProfile,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        backgroundImage: _photoUrl.isNotEmpty
                            ? NetworkImage(_photoUrl)
                            : null,
                        child: _photoUrl.isEmpty
                            ? Text(
                          _name.isNotEmpty
                              ? _name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                            : null,
                      ),
                      // Edit icon
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Points chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_points Points',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Menu items ───────────────────────────────────────────────
          _tile(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => Navigator.pop(context),
          ),

          _tile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          // ── Seller options ───────────────────────────────────────────
          if (_accountType == 'seller') ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELLER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            _tile(
              icon: Icons.add_box_outlined,
              label: 'Post New Ad',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostAdScreen()),
                );
              },
            ),
            _tile(
              icon: Icons.list_alt_rounded,
              label: 'My Ads',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ViewMyAdsScreen()),
                );
              },
            ),
            _tile(
              icon: Icons.question_answer_outlined,
              label: 'Enquiries',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ViewEnquiriesScreen()),
                );
              },
            ),
            _tile(
              icon: Icons.wallet_outlined,
              label: 'Wallet ($_points pts)',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
            ),
          ],

          const Spacer(),
          const Divider(height: 1),

          // ── Logout ───────────────────────────────────────────────────
          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserLoginScreen(),
                  ),
                      (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}