// import 'package:flutter/material.dart';
// import '../admin_dashboard.dart';
// import '../admin_profile_screen.dart';
// import '../../../../app/theme.dart';
//
// class AdminHomeScreen extends StatefulWidget {
//   const AdminHomeScreen({super.key});
//
//   @override
//   State<AdminHomeScreen> createState() => _AdminHomeScreenState();
// }
//
// class _AdminHomeScreenState extends State<AdminHomeScreen> {
//   int _selectedIndex = 0;
//
//   final List<Widget> _screens = [
//     const AdminDashboard(),
//     const AdminProfileScreen(),
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.06),
//               blurRadius: 12,
//               offset: const Offset(0, -3),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _navItem(
//                   icon: Icons.dashboard_rounded,
//                   label: 'Dashboard',
//                   index: 0,
//                 ),
//                 _navItem(
//                   icon: Icons.person_rounded,
//                   label: 'Profile',
//                   index: 1,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _navItem({
//     required IconData icon,
//     required String label,
//     required int index,
//   }) {
//     final isSelected = _selectedIndex == index;
//
//     return InkWell(
//       onTap: () => _onItemTapped(index),
//       borderRadius: BorderRadius.circular(14),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primarySurface : Colors.transparent,
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? AppColors.primary : Colors.grey.shade500,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11.5,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
//                 color: isSelected ? AppColors.primary : Colors.grey.shade500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_dashboard.dart';
import '../admin_profile_screen.dart';
import '../../../../app/theme.dart';
import '../../../../main.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(
                  isDark: isDark,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                ),
                _navItem(
                  isDark: isDark,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final unselectedColor =
    isDark ? AppColors.darkTextSecondary : Colors.grey.shade500;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
              ? AppColors.primary.withOpacity(.18)
              : AppColors.primarySurface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}