import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../main.dart';
import 'admin_ads_screen.dart';
import 'admin_details_screen.dart';

class ViewAdminsScreen extends StatefulWidget {
  const ViewAdminsScreen({super.key});

  @override
  State<ViewAdminsScreen> createState() => _ViewAdminsScreenState();
}

class _ViewAdminsScreenState extends State<ViewAdminsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('admins');

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Business Admins',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_mall_directory_outlined,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Business Admins Yet!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a business admin to get started',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> adminsMap =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> adminsList = adminsMap.entries.map((e) {
            return {
              'uid': e.key,
              ...Map<String, dynamic>.from(e.value),
            };
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminsList.length,
            itemBuilder: (context, index) {
              final admin = adminsList[index];
              final isActive = (admin['status'] ?? 'active') == 'active';

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessAdminDetailsScreen(
                        adminId: admin['uid'],
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              admin['name'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if ((admin['businessName'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                admin['businessName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              admin['email'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE3F6EF)
                                    : const Color(0xFFFBEAEA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? const Color(0xFF1D9E75)
                                      : const Color(0xFFE24B4A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminAdsScreen(
                                    adminId: admin['uid'],
                                    adminName: admin['name'] ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            onSelected: (value) async {
                              if (value == 'activate') {
                                bool confirm = await showConfirmDialog(
                                  context,
                                  title: 'Activate Admin',
                                  message:
                                  'Are you sure you want to activate this business admin?',
                                );
                                if (!confirm) return;
                                await FirebaseDatabase.instance
                                    .ref('admins/${admin['uid']}/status')
                                    .set('active');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text('Business Admin Activated'),
                                      backgroundColor: Color(0xFF1D9E75),
                                    ),
                                  );
                                }
                              }

                              if (value == 'deactivate') {
                                bool confirm = await showConfirmDialog(
                                  context,
                                  title: 'Deactivate Admin',
                                  message:
                                  'Are you sure you want to deactivate this business admin?',
                                );
                                if (!confirm) return;
                                await FirebaseDatabase.instance
                                    .ref('admins/${admin['uid']}/status')
                                    .set('inactive');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Business Admin Deactivated'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) {
                              return [
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
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}