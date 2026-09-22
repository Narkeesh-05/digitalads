import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../main.dart';
import 'seller_details_screen.dart';

class ViewSellersScreen extends StatefulWidget {
  const ViewSellersScreen({super.key});

  @override
  State<ViewSellersScreen> createState() => _ViewSellersScreenState();
}

class _ViewSellersScreenState extends State<ViewSellersScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Sellers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(isDark);
          }

          final usersMap =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> sellersList = [];
          usersMap.forEach((key, value) {
            final user = Map<String, dynamic>.from(value);
            if (user['accountType'] == 'seller') {
              sellersList.add({'uid': key, ...user});
            }
          });

          if (sellersList.isEmpty) return _emptyState(isDark);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              if (!isWide) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sellersList.length,
                  itemBuilder: (context, index) => _SellerCard(
                    seller: sellersList[index],
                    isDark: isDark,
                  ),
                );
              }

              final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 130,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: sellersList.length,
                itemBuilder: (context, index) => _SellerCard(
                  seller: sellersList[index],
                  isDark: isDark,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(bool isDark) {
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
              Icons.store_outlined,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Sellers Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color:
              isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final Map<String, dynamic> seller;
  final bool isDark;

  const _SellerCard({required this.seller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isActive = (seller['status'] ?? 'active') == 'active';
    final uid = seller['uid'] as String;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerDetailsScreen(sellerId: uid),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          seller['name'] ?? 'No Name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          seller['email'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Age: ${seller['age'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textHint,
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

                  // Popup menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) async {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerDetailsScreen(sellerId: uid),
                          ),
                        );
                        return;
                      }

                      if (value == 'delete') {
                        bool confirm = await showConfirmDialog(
                          context,
                          title: 'Delete Seller',
                          message:
                          'Are you sure you want to delete this seller?',
                        );
                        if (!confirm) return;
                        await FirebaseDatabase.instance
                            .ref('users/$uid')
                            .remove();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seller Deleted'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }

                      if (value == 'deactivate') {
                        bool confirm = await showConfirmDialog(
                          context,
                          title: 'Deactivate Seller',
                          message:
                          'Are you sure you want to deactivate this seller?',
                        );
                        if (!confirm) return;
                        await FirebaseDatabase.instance
                            .ref('users/$uid/status')
                            .set('inactive');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seller Deactivated'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }

                      if (value == 'activate') {
                        bool confirm = await showConfirmDialog(
                          context,
                          title: 'Activate Seller',
                          message:
                          'Are you sure you want to activate this seller?',
                        );
                        if (!confirm) return;
                        await FirebaseDatabase.instance
                            .ref('users/$uid/status')
                            .set('active');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seller Activated'),
                              backgroundColor: Color(0xFF1D9E75),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
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
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}