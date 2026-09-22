import 'package:digitalads/modules/user/screens/user_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // =============================================================
  // LOGOUT
  // =============================================================

  Future<void> _logout(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(.65)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final isDark = themeProvider.isDark;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ===========================================================
      // APP BAR
      // ===========================================================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ===========================================================
      // BODY
      // ===========================================================
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 40 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =================================================
                    // APPEARANCE
                    // =================================================
                    _sectionLabel(context, 'APPEARANCE'),

                    const SizedBox(height: 10),

                    _menuGroup(context, [
                      _switchTile(
                        context: context,
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: AppColors.primary,
                        iconBg: isDark
                            ? AppColors.primary.withOpacity(.15)
                            : AppColors.primarySurface,
                        title: isDark ? 'Dark Mode' : 'Light Mode',
                        subtitle: isDark
                            ? 'Switch to light theme'
                            : 'Switch to dark theme',
                        value: isDark,
                        onChanged: (value) {
                          context.read<ThemeProvider>().toggleTheme(value);
                        },
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // =================================================
                    // ACCOUNT
                    // =================================================
                    _sectionLabel(context, 'ACCOUNT'),

                    const SizedBox(height: 10),

                    _menuGroup(context, [
                      _actionTile(
                        context: context,
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        iconBg: isDark
                            ? AppColors.error.withOpacity(.14)
                            : const Color(0xFFFBEAEA),
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        titleColor: AppColors.error,
                        onTap: () => _logout(context),
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

  // =============================================================
  // SECTION LABEL
  // =============================================================

  Widget _sectionLabel(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: colorScheme.onSurface.withOpacity(.55),
        ),
      ),
    );
  }

  // =============================================================
  // MENU GROUP
  // =============================================================

  Widget _menuGroup(BuildContext context, List<Widget> tiles) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(.07)),
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

  // =============================================================
  // SWITCH TILE
  // =============================================================

  Widget _switchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final dividerColor = colorScheme.onSurface.withOpacity(.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // ---------------------------------------------------------
          // ICON
          // ---------------------------------------------------------
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

          // ---------------------------------------------------------
          // TEXT
          // ---------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(.55),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // SWITCH
          // ---------------------------------------------------------
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ACTION TILE
  // =============================================================

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final dividerColor = colorScheme.onSurface.withOpacity(.08);

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
              : Border(bottom: BorderSide(color: dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            // -------------------------------------------------------
            // ICON
            // -------------------------------------------------------
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

            // -------------------------------------------------------
            // TEXT
            // -------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(.55),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------------
            // ARROW
            // -------------------------------------------------------
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurface.withOpacity(.35),
            ),
          ],
        ),
      ),
    );
  }
}
