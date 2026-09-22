// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// import '../../../app/theme.dart';
// import '../../../core/widgets/confirm_dialog.dart';
// import 'my_seller_details_screen.dart';
//
// class ViewMySellersScreen extends StatelessWidget {
//   const ViewMySellersScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser!.uid;
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         title: const Text(
//           'My Sellers',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder(
//         stream: FirebaseDatabase.instance
//             .ref('sellers')
//             .orderByChild('createdBy')
//             .equalTo(uid)
//             .onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             );
//           }
//
//           if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 84,
//                       height: 84,
//                       decoration: BoxDecoration(
//                         color: AppColors.primarySurface,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.storefront_outlined,
//                         size: 38,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Text(
//                       'No sellers added yet',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       'Sellers you add will show up here',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: AppColors.textSecondary,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }
//
//           final data = Map<dynamic, dynamic>.from(
//             snapshot.data!.snapshot.value as Map,
//           );
//
//           final sellers = data.entries.map((e) {
//             final seller = Map<String, dynamic>.from(e.value);
//             seller['key'] = e.key;
//             return seller;
//           }).toList();
//
//           // Most recent first
//           sellers.sort((a, b) {
//             final aDate = a['createdAt'] ?? '';
//             final bDate = b['createdAt'] ?? '';
//             return bDate.toString().compareTo(aDate.toString());
//           });
//
//           return Column(
//             children: [
//               Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.primarySurface,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.bar_chart_rounded,
//                       color: AppColors.primaryDark,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Total sellers added: ${sellers.length}',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primaryDark,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                   itemCount: sellers.length,
//                   itemBuilder: (context, index) {
//                     final seller = sellers[index];
//                     final sellerKey = seller['key'] as String;
//                     final status = seller['status'] ?? 'active';
//                     final isActive = status == 'active';
//
//                     return Material(
//                       color: AppColors.surface,
//                       borderRadius: BorderRadius.circular(14),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(14),
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => MySellerDetailsScreen(
//                               sellerKey: sellerKey,
//                             ),
//                           ),
//                         ),
//                         child: Container(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           padding: const EdgeInsets.all(14),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(
//                               color: AppColors.border,
//                               width: 0.8,
//                             ),
//                           ),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 44,
//                                 height: 44,
//                                 decoration: BoxDecoration(
//                                   color: AppColors.primarySurface,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Icon(
//                                   Icons.storefront_rounded,
//                                   color: AppColors.primary,
//                                   size: 22,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             seller['shopName'] ?? '',
//                                             style: const TextStyle(
//                                               fontSize: 15,
//                                               fontWeight: FontWeight.w600,
//                                               color: AppColors.textPrimary,
//                                             ),
//                                           ),
//                                         ),
//                                         Container(
//                                           padding:
//                                           const EdgeInsets.symmetric(
//                                             horizontal: 8,
//                                             vertical: 3,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: isActive
//                                                 ? const Color(0xFFE3F6EF)
//                                                 : const Color(0xFFFBEAEA),
//                                             borderRadius:
//                                             BorderRadius.circular(20),
//                                           ),
//                                           child: Text(
//                                             isActive ? 'Active' : 'Inactive',
//                                             style: TextStyle(
//                                               fontSize: 10,
//                                               fontWeight: FontWeight.w600,
//                                               color: isActive
//                                                   ? const Color(0xFF1D9E75)
//                                                   : const Color(0xFFE24B4A),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       seller['ownerName'] ?? '',
//                                       style: const TextStyle(
//                                         fontSize: 13,
//                                         color: AppColors.textSecondary,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 6),
//                                     Row(
//                                       children: [
//                                         const Icon(
//                                           Icons.phone_outlined,
//                                           size: 13,
//                                           color: AppColors.textHint,
//                                         ),
//                                         const SizedBox(width: 4),
//                                         Text(
//                                           seller['phone'] ?? '',
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: AppColors.textHint,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         const Icon(
//                                           Icons.category_outlined,
//                                           size: 13,
//                                           color: AppColors.textHint,
//                                         ),
//                                         const SizedBox(width: 4),
//                                         Expanded(
//                                           child: Text(
//                                             seller['category'] ?? '',
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: AppColors.textHint,
//                                             ),
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               PopupMenuButton<String>(
//                                 icon: const Icon(
//                                   Icons.more_vert_rounded,
//                                   color: AppColors.textSecondary,
//                                   size: 20,
//                                 ),
//                                 onSelected: (value) async {
//                                   if (value == 'view') {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             MySellerDetailsScreen(
//                                               sellerKey: sellerKey,
//                                             ),
//                                       ),
//                                     );
//                                     return;
//                                   }
//
//                                   if (value == 'activate') {
//                                     bool confirm = await showConfirmDialog(
//                                       context,
//                                       title: 'Activate Seller',
//                                       message:
//                                       'Are you sure you want to activate this seller?',
//                                     );
//                                     if (!confirm) return;
//                                     await FirebaseDatabase.instance
//                                         .ref('sellers/$sellerKey/status')
//                                         .set('active');
//                                     if (context.mounted) {
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content:
//                                           Text('Seller Activated'),
//                                           backgroundColor:
//                                           Color(0xFF1D9E75),
//                                         ),
//                                       );
//                                     }
//                                   }
//
//                                   if (value == 'deactivate') {
//                                     bool confirm = await showConfirmDialog(
//                                       context,
//                                       title: 'Deactivate Seller',
//                                       message:
//                                       'Are you sure you want to deactivate this seller?',
//                                     );
//                                     if (!confirm) return;
//                                     await FirebaseDatabase.instance
//                                         .ref('sellers/$sellerKey/status')
//                                         .set('inactive');
//                                     if (context.mounted) {
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content:
//                                           Text('Seller Deactivated'),
//                                           backgroundColor: Colors.orange,
//                                         ),
//                                       );
//                                     }
//                                   }
//
//                                   if (value == 'delete') {
//                                     bool confirm = await showConfirmDialog(
//                                       context,
//                                       title: 'Delete Seller',
//                                       message:
//                                       'Are you sure you want to delete this seller? This cannot be undone.',
//                                     );
//                                     if (!confirm) return;
//                                     await FirebaseDatabase.instance
//                                         .ref('sellers/$sellerKey')
//                                         .remove();
//                                     if (context.mounted) {
//                                       ScaffoldMessenger.of(context)
//                                           .showSnackBar(
//                                         const SnackBar(
//                                           content: Text('Seller Deleted'),
//                                           backgroundColor: AppColors.error,
//                                         ),
//                                       );
//                                     }
//                                   }
//                                 },
//                                 itemBuilder: (context) => [
//                                   const PopupMenuItem(
//                                     value: 'view',
//                                     child: Text('View Details'),
//                                   ),
//                                   if (!isActive)
//                                     const PopupMenuItem(
//                                       value: 'activate',
//                                       child: Text('Activate'),
//                                     ),
//                                   if (isActive)
//                                     const PopupMenuItem(
//                                       value: 'deactivate',
//                                       child: Text('Deactivate'),
//                                     ),
//                                   const PopupMenuItem(
//                                     value: 'delete',
//                                     child: Text(
//                                       'Delete',
//                                       style:
//                                       TextStyle(color: AppColors.error),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../main.dart';
import 'my_seller_details_screen.dart';

class ViewMySellersScreen extends StatelessWidget {
  const ViewMySellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Sellers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref('sellers')
            .orderByChild('createdBy')
            .equalTo(uid)
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
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
                        Icons.storefront_outlined,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No sellers added yet',
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
                      'Sellers you add will show up here',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final sellers = data.entries.map((e) {
            final seller = Map<String, dynamic>.from(e.value);
            seller['key'] = e.key;
            return seller;
          }).toList();

          // Most recent first
          sellers.sort((a, b) {
            final aDate = a['createdAt'] ?? '';
            final bDate = b['createdAt'] ?? '';
            return bDate.toString().compareTo(aDate.toString());
          });

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withOpacity(.15)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total sellers added: ${sellers.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: sellers.length,
                  itemBuilder: (context, index) {
                    final seller = sellers[index];
                    final sellerKey = seller['key'] as String;
                    final status = seller['status'] ?? 'active';
                    final isActive = status == 'active';

                    return Material(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MySellerDetailsScreen(
                              sellerKey: sellerKey,
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            seller['shopName'] ?? '',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFFE3F6EF)
                                                : const Color(0xFFFBEAEA),
                                            borderRadius:
                                            BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? const Color(0xFF1D9E75)
                                                  : const Color(0xFFE24B4A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      seller['ownerName'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          seller['phone'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textHint,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.category_outlined,
                                          size: 13,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            seller['category'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.textHint,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
                                  if (value == 'view') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MySellerDetailsScreen(
                                              sellerKey: sellerKey,
                                            ),
                                      ),
                                    );
                                    return;
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
                                        .ref('sellers/$sellerKey/status')
                                        .set('active');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                          Text('Seller Activated'),
                                          backgroundColor:
                                          Color(0xFF1D9E75),
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
                                        .ref('sellers/$sellerKey/status')
                                        .set('inactive');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                          Text('Seller Deactivated'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  }

                                  if (value == 'delete') {
                                    bool confirm = await showConfirmDialog(
                                      context,
                                      title: 'Delete Seller',
                                      message:
                                      'Are you sure you want to delete this seller? This cannot be undone.',
                                    );
                                    if (!confirm) return;
                                    await FirebaseDatabase.instance
                                        .ref('sellers/$sellerKey')
                                        .remove();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Seller Deleted'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
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
                                      style:
                                      TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}