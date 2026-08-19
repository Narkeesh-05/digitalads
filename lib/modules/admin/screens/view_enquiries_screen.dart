//  import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
//
// import '../../../app/theme.dart';
//
// class ViewEnquiriesScreen extends StatelessWidget {
//   const ViewEnquiriesScreen({super.key});
//
//   String _formatDateTime(String raw) {
//     if (raw.isEmpty) return '';
//     try {
//       final date = DateTime.parse(raw);
//       const months = [
//         'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//       ];
//       final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
//       final minute = date.minute.toString().padLeft(2, '0');
//       final period = date.hour >= 12 ? 'PM' : 'AM';
//       return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:$minute $period';
//     } catch (_) {
//       return '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final adminId = FirebaseAuth.instance.currentUser!.uid;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F5F9),
//       appBar: AppBar(
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//         title: const Text(
//           'Enquiries',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: StreamBuilder(
//         stream: FirebaseDatabase.instance.ref('enquiries').onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             );
//           }
//
//           if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
//             return _emptyState();
//           }
//
//           Map<dynamic, dynamic> enquiriesMap =
//           snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//
//           List<Map<String, dynamic>> enquiriesList = enquiriesMap.entries
//               .where((e) =>
//           Map<String, dynamic>.from(e.value)['adminId'] == adminId)
//               .map((e) => {
//             'id': e.key,
//             ...Map<String, dynamic>.from(e.value),
//           })
//               .toList();
//
//           // Most recent first
//           enquiriesList.sort((a, b) {
//             final aDate = a['createdAt'] ?? '';
//             final bDate = b['createdAt'] ?? '';
//             return bDate.toString().compareTo(aDate.toString());
//           });
//
//           if (enquiriesList.isEmpty) return _emptyState();
//
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               final isWide = constraints.maxWidth > 700;
//
//               if (!isWide) {
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: enquiriesList.length,
//                   itemBuilder: (context, index) => _EnquiryCard(
//                     enquiry: enquiriesList[index],
//                     formattedDate: _formatDateTime(
//                         (enquiriesList[index]['createdAt'] ?? '')
//                             .toString()),
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
//                   mainAxisExtent: 240,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                 ),
//                 itemCount: enquiriesList.length,
//                 itemBuilder: (context, index) => _EnquiryCard(
//                   enquiry: enquiriesList[index],
//                   formattedDate: _formatDateTime(
//                       (enquiriesList[index]['createdAt'] ?? '').toString()),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _emptyState() {
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
//               Icons.question_answer_outlined,
//               size: 42,
//               color: AppColors.primary,
//             ),
//           ),
//           const SizedBox(height: 18),
//           const Text(
//             'No Enquiries Yet!',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Customer enquiries will show up here',
//             style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _EnquiryCard extends StatelessWidget {
//   final Map<String, dynamic> enquiry;
//   final String formattedDate;
//
//   const _EnquiryCard({
//     required this.enquiry,
//     required this.formattedDate,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final message = (enquiry['message'] ?? '').toString();
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 21,
//                 backgroundColor: AppColors.primarySurface,
//                 child: const Icon(Icons.person_rounded,
//                     color: AppColors.primary, size: 21),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       enquiry['userName'] ?? 'Unknown',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       enquiry['userPhone'] ?? '',
//                       style: TextStyle(
//                         fontSize: 12.5,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//             decoration: BoxDecoration(
//               color: AppColors.primarySurface,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.ad_units_rounded,
//                     size: 15, color: AppColors.primary),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     enquiry['adTitle'] ?? '',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12.5,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (message.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Text(
//               message,
//               maxLines: 3,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: AppColors.textPrimary,
//                 height: 1.4,
//               ),
//             ),
//           ],
//           if (formattedDate.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Icon(Icons.access_time_rounded,
//                     size: 13, color: Colors.grey.shade500),
//                 const SizedBox(width: 4),
//                 Text(
//                   formattedDate,
//                   style: TextStyle(
//                     fontSize: 11.5,
//                     color: Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class ViewEnquiriesScreen extends StatelessWidget {
  const ViewEnquiriesScreen({super.key});

  String _formatDateTime(String raw) {
    if (raw.isEmpty) return '';

    try {
      final date = DateTime.parse(raw);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

      final minute = date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '${date.day} ${months[date.month - 1]} '
          '${date.year} • $hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser?.uid;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (adminId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Enquiries',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text(
            'Please login again',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Enquiries',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // =========================================================
      // BODY
      // =========================================================
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('enquiries').onValue,

        builder: (context, snapshot) {
          // -------------------------------------------------------
          // LOADING
          // -------------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // -------------------------------------------------------
          // ERROR
          // -------------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load enquiries',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // -------------------------------------------------------
          // EMPTY
          // -------------------------------------------------------

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(context);
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData is! Map) {
            return _emptyState(context);
          }

          final enquiriesMap = Map<dynamic, dynamic>.from(rawData);

          // -------------------------------------------------------
          // FILTER ADMIN ENQUIRIES
          // -------------------------------------------------------

          final List<Map<String, dynamic>> enquiriesList = [];

          for (final entry in enquiriesMap.entries) {
            if (entry.value is! Map) continue;

            final data = Map<String, dynamic>.from(entry.value as Map);

            if (data['adminId']?.toString() == adminId) {
              enquiriesList.add({'id': entry.key, ...data});
            }
          }

          // -------------------------------------------------------
          // SORT — MOST RECENT FIRST
          // -------------------------------------------------------

          enquiriesList.sort((a, b) {
            final aDate = a['createdAt'] ?? '';
            final bDate = b['createdAt'] ?? '';

            return bDate.toString().compareTo(aDate.toString());
          });

          if (enquiriesList.isEmpty) {
            return _emptyState(context);
          }

          // -------------------------------------------------------
          // RESPONSIVE LAYOUT
          // -------------------------------------------------------

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              // =================================================
              // MOBILE
              // =================================================

              if (!isWide) {
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: enquiriesList.length,
                  itemBuilder: (context, index) {
                    final enquiry = enquiriesList[index];

                    return _EnquiryCard(
                      enquiry: enquiry,
                      formattedDate: _formatDateTime(
                        (enquiry['createdAt'] ?? '').toString(),
                      ),
                    );
                  },
                );
              }

              // =================================================
              // TABLET / DESKTOP
              // =================================================

              final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 240,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: enquiriesList.length,
                itemBuilder: (context, index) {
                  final enquiry = enquiriesList[index];

                  return _EnquiryCard(
                    enquiry: enquiry,
                    formattedDate: _formatDateTime(
                      (enquiry['createdAt'] ?? '').toString(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withOpacity(.16)
                    : AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.question_answer_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No Enquiries Yet!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Customer enquiries will show up here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// ENQUIRY CARD
// =================================================================

class _EnquiryCard extends StatelessWidget {
  final Map<String, dynamic> enquiry;
  final String formattedDate;

  const _EnquiryCard({required this.enquiry, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final message = (enquiry['message'] ?? '').toString();

    final userName = (enquiry['userName'] ?? 'Unknown').toString();

    final userPhone = (enquiry['userPhone'] ?? '').toString();

    final adTitle = (enquiry['adTitle'] ?? '').toString();

    // Theme-aware colors
    final cardColor = theme.cardColor;

    final secondaryText = colorScheme.onSurface.withOpacity(.60);

    final dividerColor = colorScheme.onSurface.withOpacity(.08);

    final primarySurface = isDark
        ? AppColors.primary.withOpacity(.14)
        : AppColors.primarySurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: dividerColor, width: 1),

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

        mainAxisSize: MainAxisSize.min,

        children: [
          // =======================================================
          // USER
          // =======================================================
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 3),

                    if (userPhone.isNotEmpty)
                      Text(
                        userPhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: secondaryText),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =======================================================
          // AD TITLE
          // =======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),

            decoration: BoxDecoration(
              color: primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.ad_units_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    adTitle.isEmpty ? 'Advertisement' : adTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =======================================================
          // MESSAGE
          // =======================================================
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),

            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],

          // =======================================================
          // DATE
          // =======================================================
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: secondaryText),

                const SizedBox(width: 4),

                Expanded(
                  child: Text(
                    formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: secondaryText),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
