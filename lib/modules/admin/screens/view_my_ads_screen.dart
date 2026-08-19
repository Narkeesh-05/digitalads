//  import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../app/theme.dart';
// import '../../../core/widgets/confirm_dialog.dart';
// import '../../../main.dart';
//
// class ViewMyAdsScreen extends StatelessWidget {
//   const ViewMyAdsScreen({super.key});
//
//   List<String> _extractImageUrls(Map<String, dynamic> ad) {
//     List<String> urls = [];
//
//     if (ad['imageUrls'] != null) {
//       if (ad['imageUrls'] is List) {
//         urls = List<String>.from(ad['imageUrls']);
//       } else if (ad['imageUrls'] is Map) {
//         urls = Map<dynamic, dynamic>.from(ad['imageUrls'])
//             .values
//             .map((e) => e.toString())
//             .toList();
//       }
//     }
//
//     if (urls.isEmpty &&
//         ad['imageUrl'] != null &&
//         ad['imageUrl'].toString().isNotEmpty) {
//       urls.add(ad['imageUrl'].toString());
//     }
//
//     return urls;
//   }
//
//   Future<void> _deleteAd(BuildContext context, String adId) async {
//     final confirm = await showConfirmDialog(
//       context,
//       title: 'Delete Ad',
//       message: 'Are you sure you want to delete this ad? This cannot be undone.',
//     );
//     if (!confirm) return;
//
//     await FirebaseDatabase.instance.ref('ads/$adId').remove();
//
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Ad Deleted'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final adminId = FirebaseAuth.instance.currentUser!.uid;
//     final isDark = context.watch<ThemeProvider>().isDark;
//
//     return Scaffold(
//       backgroundColor:
//       isDark ? AppColors.darkBackground : AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         title: const Text(
//           'My Ads',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder(
//         stream: FirebaseDatabase.instance.ref('ads').onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             );
//           }
//
//           if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
//             return _emptyState(isDark);
//           }
//
//           Map<dynamic, dynamic> adsMap =
//           snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//
//           List<Map<String, dynamic>> adsList = adsMap.entries
//               .where((e) =>
//           Map<String, dynamic>.from(e.value)['adminId'] == adminId)
//               .map((e) => {
//             'id': e.key,
//             ...Map<String, dynamic>.from(e.value),
//           })
//               .toList();
//
//           // Most recent first
//           adsList.sort((a, b) {
//             final aDate = a['createdAt'] ?? '';
//             final bDate = b['createdAt'] ?? '';
//             return bDate.toString().compareTo(aDate.toString());
//           });
//
//           if (adsList.isEmpty) return _emptyState(isDark);
//
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               final isWide = constraints.maxWidth > 700;
//
//               if (!isWide) {
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: adsList.length,
//                   itemBuilder: (context, index) => _AdCard(
//                     ad: adsList[index],
//                     imageUrls: _extractImageUrls(adsList[index]),
//                     isDark: isDark,
//                     onDelete: () =>
//                         _deleteAd(context, adsList[index]['id']),
//                   ),
//                 );
//               }
//
//               final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;
//
//               return GridView.builder(
//                 padding: const EdgeInsets.all(16),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: crossAxisCount,
//                   mainAxisExtent: 360,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                 ),
//                 itemCount: adsList.length,
//                 itemBuilder: (context, index) => _AdCard(
//                   ad: adsList[index],
//                   imageUrls: _extractImageUrls(adsList[index]),
//                   isDark: isDark,
//                   onDelete: () => _deleteAd(context, adsList[index]['id']),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _emptyState(bool isDark) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 90,
//             height: 90,
//             decoration: const BoxDecoration(
//               color: AppColors.primarySurface,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.ad_units_outlined,
//               size: 42,
//               color: AppColors.primary,
//             ),
//           ),
//           const SizedBox(height: 18),
//           Text(
//             'No Ads Posted Yet!',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Ads you post will show up here',
//             style: TextStyle(
//               fontSize: 13,
//               color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AdCard extends StatelessWidget {
//   final Map<String, dynamic> ad;
//   final List<String> imageUrls;
//   final bool isDark;
//   final VoidCallback onDelete;
//
//   const _AdCard({
//     required this.ad,
//     required this.imageUrls,
//     required this.isDark,
//     required this.onDelete,
//   });
//
//   String _formatDate(String raw) {
//     if (raw.isEmpty) return '';
//     try {
//       final date = DateTime.parse(raw);
//       const months = [
//         'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//       ];
//       return '${date.day} ${months[date.month - 1]} ${date.year}';
//     } catch (_) {
//       return '';
//     }
//   }
//
//   Widget _stat(IconData icon, int count) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon,
//             size: 14,
//             color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
//         const SizedBox(width: 4),
//         Text(
//           '$count',
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final offer = (ad['offer'] ?? '').toString();
//     final createdAt = _formatDate((ad['createdAt'] ?? '').toString());
//     final adId = ad['id'];
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: isDark ? AppColors.darkSurface : Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: isDark
//             ? []
//             : [
//           BoxShadow(
//             color: Colors.black.withOpacity(.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               ClipRRect(
//                 borderRadius:
//                 const BorderRadius.vertical(top: Radius.circular(16)),
//                 child: imageUrls.isNotEmpty
//                     ? Image.network(
//                   imageUrls.first,
//                   width: double.infinity,
//                   height: 160,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => Container(
//                     height: 160,
//                     width: double.infinity,
//                     color: isDark
//                         ? AppColors.darkSurfaceVariant
//                         : Colors.grey.shade200,
//                     child: Icon(Icons.broken_image_outlined,
//                         size: 44,
//                         color: isDark
//                             ? AppColors.darkTextSecondary
//                             : Colors.grey),
//                   ),
//                 )
//                     : Container(
//                   height: 160,
//                   width: double.infinity,
//                   color: isDark
//                       ? AppColors.darkSurfaceVariant
//                       : Colors.grey.shade200,
//                   child: Icon(Icons.image_outlined,
//                       size: 44,
//                       color: isDark
//                           ? AppColors.darkTextSecondary
//                           : Colors.grey),
//                 ),
//               ),
//               if (imageUrls.length > 1)
//                 Positioned(
//                   bottom: 8,
//                   right: 8,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(.55),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.photo_library_rounded,
//                             size: 12, color: Colors.white),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${imageUrls.length}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   ad['title'] ?? '',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 15.5,
//                     fontWeight: FontWeight.bold,
//                     color: isDark
//                         ? AppColors.darkTextPrimary
//                         : AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   ad['description'] ?? '',
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 12.5,
//                     color: isDark
//                         ? AppColors.darkTextSecondary
//                         : Colors.grey.shade600,
//                   ),
//                 ),
//                 if (offer.isNotEmpty) ...[
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.primarySurface,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       '🎯 $offer',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         color: AppColors.primary,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 10),
//
//                 // ── Engagement stats ──────────────────────────
//                 if (adId != null)
//                   StreamBuilder<DatabaseEvent>(
//                     stream:
//                     FirebaseDatabase.instance.ref('ads/$adId').onValue,
//                     builder: (context, statsSnap) {
//                       int likeCount = 0;
//                       int commentCount = 0;
//                       int viewCount = 0;
//
//                       if (statsSnap.hasData &&
//                           statsSnap.data!.snapshot.value != null) {
//                         final adData = Map<String, dynamic>.from(
//                           statsSnap.data!.snapshot.value as Map,
//                         );
//                         if (adData['likes'] is Map) {
//                           likeCount = (adData['likes'] as Map).length;
//                         }
//                         if (adData['comments'] is Map) {
//                           commentCount = (adData['comments'] as Map).length;
//                         }
//                         if (adData['views'] is Map) {
//                           viewCount = (adData['views'] as Map).length;
//                         }
//                       }
//
//                       return Row(
//                         children: [
//                           _stat(Icons.favorite_border_rounded, likeCount),
//                           const SizedBox(width: 14),
//                           _stat(Icons.chat_bubble_outline_rounded,
//                               commentCount),
//                           const SizedBox(width: 14),
//                           _stat(Icons.visibility_outlined, viewCount),
//                         ],
//                       );
//                     },
//                   ),
//
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     if (createdAt.isNotEmpty) ...[
//                       Icon(Icons.calendar_today,
//                           size: 12,
//                           color: isDark
//                               ? AppColors.darkTextSecondary
//                               : Colors.grey.shade500),
//                       const SizedBox(width: 4),
//                       Text(
//                         createdAt,
//                         style: TextStyle(
//                           fontSize: 11.5,
//                           color: isDark
//                               ? AppColors.darkTextSecondary
//                               : Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                     const Spacer(),
//                     InkWell(
//                       onTap: onDelete,
//                       borderRadius: BorderRadius.circular(20),
//                       child: const Padding(
//                         padding: EdgeInsets.all(4),
//                         child: Icon(
//                           Icons.delete_outline_rounded,
//                           color: AppColors.error,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
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
import '../../user/screens/ad_engagement_screen.dart';

class ViewMyAdsScreen extends StatelessWidget {
  const ViewMyAdsScreen({super.key});

  List<String> _extractImageUrls(Map<String, dynamic> ad) {
    List<String> urls = [];

    if (ad['imageUrls'] != null) {
      if (ad['imageUrls'] is List) {
        urls = List<String>.from(ad['imageUrls']);
      } else if (ad['imageUrls'] is Map) {
        urls = Map<dynamic, dynamic>.from(ad['imageUrls'])
            .values
            .map((e) => e.toString())
            .toList();
      }
    }

    if (urls.isEmpty &&
        ad['imageUrl'] != null &&
        ad['imageUrl'].toString().isNotEmpty) {
      urls.add(ad['imageUrl'].toString());
    }

    return urls;
  }

  Future<void> _deleteAd(BuildContext context, String adId) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Ad',
      message: 'Are you sure you want to delete this ad? This cannot be undone.',
    );
    if (!confirm) return;

    await FirebaseDatabase.instance.ref('ads/$adId').remove();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad Deleted'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser!.uid;
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Ads',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('ads').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(isDark);
          }

          Map<dynamic, dynamic> adsMap =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> adsList = adsMap.entries
              .where((e) =>
          Map<String, dynamic>.from(e.value)['adminId'] == adminId)
              .map((e) => {
            'id': e.key,
            ...Map<String, dynamic>.from(e.value),
          })
              .toList();

          // Most recent first
          adsList.sort((a, b) {
            final aDate = a['createdAt'] ?? '';
            final bDate = b['createdAt'] ?? '';
            return bDate.toString().compareTo(aDate.toString());
          });

          if (adsList.isEmpty) return _emptyState(isDark);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              if (!isWide) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: adsList.length,
                  itemBuilder: (context, index) => _AdCard(
                    ad: adsList[index],
                    imageUrls: _extractImageUrls(adsList[index]),
                    isDark: isDark,
                    onDelete: () =>
                        _deleteAd(context, adsList[index]['id']),
                  ),
                );
              }

              final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 360,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: adsList.length,
                itemBuilder: (context, index) => _AdCard(
                  ad: adsList[index],
                  imageUrls: _extractImageUrls(adsList[index]),
                  isDark: isDark,
                  onDelete: () => _deleteAd(context, adsList[index]['id']),
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
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ad_units_outlined,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No Ads Posted Yet!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ads you post will show up here',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final List<String> imageUrls;
  final bool isDark;
  final VoidCallback onDelete;

  const _AdCard({
    required this.ad,
    required this.imageUrls,
    required this.isDark,
    required this.onDelete,
  });

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final date = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _stat(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = (ad['offer'] ?? '').toString();
    final createdAt = _formatDate((ad['createdAt'] ?? '').toString());
    final adId = ad['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrls.isNotEmpty
                    ? Image.network(
                  imageUrls.first,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    width: double.infinity,
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : Colors.grey.shade200,
                    child: Icon(Icons.broken_image_outlined,
                        size: 44,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey),
                  ),
                )
                    : Container(
                  height: 160,
                  width: double.infinity,
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : Colors.grey.shade200,
                  child: Icon(Icons.image_outlined,
                      size: 44,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey),
                ),
              ),
              if (imageUrls.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ad['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                  ),
                ),
                if (offer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🎯 $offer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // ── Engagement stats (tap for details) ────────
                if (adId != null)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdEngagementScreen(
                            adId: adId,
                            adTitle: (ad['title'] ?? '').toString(),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: StreamBuilder<DatabaseEvent>(
                      stream:
                      FirebaseDatabase.instance.ref('ads/$adId').onValue,
                      builder: (context, statsSnap) {
                        int likeCount = 0;
                        int commentCount = 0;
                        int viewCount = 0;

                        if (statsSnap.hasData &&
                            statsSnap.data!.snapshot.value != null) {
                          final adData = Map<String, dynamic>.from(
                            statsSnap.data!.snapshot.value as Map,
                          );
                          if (adData['likes'] is Map) {
                            likeCount = (adData['likes'] as Map).length;
                          }
                          if (adData['comments'] is Map) {
                            commentCount = (adData['comments'] as Map).length;
                          }
                          if (adData['views'] is Map) {
                            viewCount = (adData['views'] as Map).length;
                          }
                        }

                        return Row(
                          children: [
                            _stat(Icons.favorite_border_rounded, likeCount),
                            const SizedBox(width: 14),
                            _stat(Icons.chat_bubble_outline_rounded,
                                commentCount),
                            const SizedBox(width: 14),
                            _stat(Icons.visibility_outlined, viewCount),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textHint),
                          ],
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    if (createdAt.isNotEmpty) ...[
                      Icon(Icons.calendar_today,
                          size: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        createdAt,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}