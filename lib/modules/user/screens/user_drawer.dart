import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shop/modules/admin/screens/post_ad_screen.dart';
import 'package:shop/modules/admin/screens/view_enquiries_screen.dart';
import 'package:shop/modules/admin/screens/view_my_ads_screen.dart';
import 'package:shop/modules/user/screens/role_selection_screen.dart';
import 'package:shop/modules/user/screens/wallet_screen.dart';

class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String _name = 'User';
  String _accountType = 'normal';
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
    await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _name = data['name'] ?? 'User';
        _accountType = data['accountType'] ?? 'normal';
        _points = (data['points'] ?? 0) as int;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            accountName: Text(
              _name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              _accountType == 'seller' ? '🏪 Seller' : '👤 Normal User',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.wallet, color: Colors.blue),
            title: const Text('Wallet'),
            subtitle: Text('$_points Points'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletScreen(),
                ),
              );
            },
          ),
          if (_accountType == 'seller') ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seller Options',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.orange),
              title: const Text('Post New Ad'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PostAdScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading:
              const Icon(Icons.list_alt, color: Colors.orange),
              title: const Text('My Ads'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewMyAdsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer,
                  color: Colors.orange),
              title: const Text('Enquiries'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewEnquiriesScreen(),
                  ),
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}