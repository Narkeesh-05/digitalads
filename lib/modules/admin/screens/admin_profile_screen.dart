// import 'package:digitalads/modules/admin/screens/admin_settings.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// import '../../../app/theme.dart';
// import 'admin_edit_profile_screen.dart';
//
// class AdminProfileScreen extends StatefulWidget {
//   const AdminProfileScreen({super.key});
//
//   @override
//   State<AdminProfileScreen> createState() => _AdminProfileScreenState();
// }
//
// class _AdminProfileScreenState extends State<AdminProfileScreen> {
//   bool _isLoading = true;
//   Map<String, dynamic> admin = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAdmin();
//   }
//
//   Future<void> _loadAdmin() async {
//     try {
//       final uid = FirebaseAuth.instance.currentUser!.uid;
//       final snapshot =
//       await FirebaseDatabase.instance.ref('admins/$uid').get();
//
//       if (snapshot.exists) {
//         admin = Map<String, dynamic>.from(snapshot.value as Map);
//       }
//     } catch (e) {
//       debugPrint(e.toString());
//     }
//
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   String _get(String key) {
//     final value = admin[key];
//     if (value == null) return '';
//     return value.toString();
//   }
//
//   String get _photoUrl {
//     final p = admin['photoUrl'] ?? admin['profileImage'] ?? '';
//     return p.toString();
//   }
//
//   Future<void> _goToEditProfile() async {
//
//
//     final updated = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const EditAdminProfileScreen()),
//     );
//
//     // Refresh header after coming back from edit
//     if (updated == true) {
//       _loadAdmin();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F5F9),
//       appBar: AppBar(
//         title: const Text(
//           'Profile',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : LayoutBuilder(
//         builder: (context, constraints) {
//           final isWide = constraints.maxWidth > 700;
//           return SingleChildScrollView(
//             padding: EdgeInsets.symmetric(
//               horizontal: isWide ? 40 : 16,
//               vertical: 20,
//             ),
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   maxWidth: isWide ? 640 : double.infinity,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     _buildProfileHeader(),
//                     const SizedBox(height: 24),
//                     _sectionLabel('ACCOUNT'),
//                     const SizedBox(height: 10),
//                     _menuGroup([
//                       // _menuTile(
//                       //   icon: Icons.edit_rounded,
//                       //   iconColor: const Color(0xFF1D9E75),
//                       //   iconBg: const Color(0xFFE3F6EF),
//                       //   title: 'Edit Profile',
//                       //   subtitle: 'Update your personal & business info',
//                       //   onTap: _goToEditProfile,
//                       // ),
//                       _menuTile(
//                         icon: Icons.settings_rounded,
//                         iconColor: Colors.grey.shade700,
//                         iconBg: Colors.grey.shade200,
//                         title: 'Settings',
//                         subtitle: 'Theme, logout and more',
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const SettingsScreen(),
//                           ),
//                         ),
//                         isLast: true,
//                       ),
//                     ]),
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildProfileHeader() {
//     final status = _get('status').isEmpty ? 'active' : _get('status');
//     final isActive = status.toLowerCase() == 'active';
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppColors.primary, Color(0xFF7A72D6)],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(.25),
//             blurRadius: 16,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               CircleAvatar(
//                 radius: 45,
//                 backgroundColor: Colors.white,
//                 child: CircleAvatar(
//                   radius: 42,
//                   backgroundColor: Colors.white.withOpacity(.15),
//                   backgroundImage:
//                   _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
//                   child: _photoUrl.isEmpty
//                       ? const Icon(Icons.person,
//                       size: 42, color: Colors.white)
//                       : null,
//                 ),
//               ),
//               Positioned(
//                 bottom: -2,
//                 right: -2,
//                 child: GestureDetector(
//                   onTap: _goToEditProfile,
//                   child: Container(
//                     padding: const EdgeInsets.all(7),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: AppColors.primary,
//                         width: 2,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(.15),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.edit_rounded,
//                       size: 15,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           Text(
//             _get('name').isEmpty ? 'Business Admin' : _get('name'),
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           if (_get('businessName').isNotEmpty) ...[
//             const SizedBox(height: 4),
//             Text(
//               _get('businessName'),
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 13.5,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white.withOpacity(.95),
//               ),
//             ),
//           ],
//           const SizedBox(height: 4),
//           Text(
//             _get('email'),
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(.85)),
//           ),
//           if (_get('phone').isNotEmpty) ...[
//             const SizedBox(height: 2),
//             Text(
//               _get('phone'),
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12.5,
//                 color: Colors.white.withOpacity(.8),
//               ),
//             ),
//           ],
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.circle,
//                   size: 8,
//                   color: isActive ? const Color(0xFF1D9E75) : Colors.orange,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   status[0].toUpperCase() + status.substring(1),
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 12,
//                     color: isActive ? const Color(0xFF1D9E75) : Colors.orange,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _sectionLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 4),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 11.5,
//           fontWeight: FontWeight.w700,
//           letterSpacing: 1,
//           color: Colors.grey.shade600,
//         ),
//       ),
//     );
//   }
//
//   Widget _menuGroup(List<Widget> tiles) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(children: tiles),
//     );
//   }
//
//   Widget _menuTile({
//     required IconData icon,
//     required Color iconColor,
//     required Color iconBg,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//     Color? titleColor,
//     bool isLast = false,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: isLast
//           ? const BorderRadius.vertical(bottom: Radius.circular(18))
//           : BorderRadius.zero,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           border: isLast
//               ? null
//               : Border(
//             bottom: BorderSide(color: Colors.grey.shade100, width: 1),
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 42,
//               height: 42,
//               decoration: BoxDecoration(
//                 color: iconBg,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: iconColor, size: 21),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 14.5,
//                       fontWeight: FontWeight.w600,
//                       color: titleColor ?? AppColors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey.shade500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.arrow_forward_ios_rounded,
//               size: 14,
//               color: Colors.grey.shade400,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:digitalads/modules/admin/screens/admin_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../main.dart';
import 'admin_edit_profile_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> admin = {};

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot =
      await FirebaseDatabase.instance.ref('admins/$uid').get();

      if (snapshot.exists) {
        admin = Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _get(String key) {
    final value = admin[key];
    if (value == null) return '';
    return value.toString();
  }

  String get _photoUrl {
    final p = admin['photoUrl'] ?? admin['profileImage'] ?? '';
    return p.toString();
  }

  Future<void> _goToEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditAdminProfileScreen()),
    );

    // Refresh header after coming back from edit
    if (updated == true) {
      _loadAdmin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 640 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _sectionLabel('ACCOUNT', isDark),
                    const SizedBox(height: 10),
                    _menuGroup(isDark, [
                      // _menuTile(
                      //   icon: Icons.edit_rounded,
                      //   iconColor: const Color(0xFF1D9E75),
                      //   iconBg: const Color(0xFFE3F6EF),
                      //   title: 'Edit Profile',
                      //   subtitle: 'Update your personal & business info',
                      //   onTap: _goToEditProfile,
                      // ),
                      _menuTile(
                        isDark: isDark,
                        icon: Icons.settings_rounded,
                        iconColor: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade700,
                        iconBg: isDark
                            ? AppColors.darkSurfaceVariant
                            : Colors.grey.shade200,
                        title: 'Settings',
                        subtitle: 'Theme, logout and more',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final status = _get('status').isEmpty ? 'active' : _get('status');
    final isActive = status.toLowerCase() == 'active';

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
          Stack(
            clipBehavior: Clip.none,
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
                      ? const Icon(Icons.person,
                      size: 42, color: Colors.white)
                      : null,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _goToEditProfile,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _get('name').isEmpty ? 'Business Admin' : _get('name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_get('businessName').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _get('businessName'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(.95),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _get('email'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(.85)),
          ),
          if (_get('phone').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _get('phone'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withOpacity(.8),
              ),
            ),
          ],
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

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _menuGroup(bool isDark, List<Widget> tiles) {
    return Container(
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
      child: Column(children: tiles),
    );
  }

  Widget _menuTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(18))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
            bottom: BorderSide(
              color:
              isDark ? AppColors.darkBorder : Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ??
                          (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}