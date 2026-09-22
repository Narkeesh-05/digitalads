import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../main.dart';
import '../../user/screens/ad_engagement_screen.dart';
import '../../user/screens/network_video_player.dart';

class ViewAllAdsScreen extends StatelessWidget {
  const ViewAllAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'All Ads',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('ads').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null) {
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
                      Icons.campaign_outlined,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Ads Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          final ads = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final adId = ads[index].key.toString();
              final ad = Map<String, dynamic>.from(ads[index].value);

              List<String> imageUrls = [];
              if (ad['imageUrls'] != null) {
                if (ad['imageUrls'] is List) {
                  imageUrls = List<String>.from(ad['imageUrls']);
                } else if (ad['imageUrls'] is Map) {
                  imageUrls = Map<dynamic, dynamic>.from(ad['imageUrls'])
                      .values
                      .map((e) => e.toString())
                      .toList();
                }
              }
              if (ad['imageUrl'] != null && ad['imageUrl'].toString().isNotEmpty) {
                imageUrls.add(ad['imageUrl'].toString());
              }

              String? videoUrl = ad['videoUrl'];
              final totalSlides =
                  imageUrls.length + (videoUrl != null && videoUrl.isNotEmpty ? 1 : 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (totalSlides > 0)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 220,
                            viewportFraction: 1,
                            enableInfiniteScroll: false,
                            enlargeCenterPage: false,
                          ),
                          items: [
                            ...imageUrls.map(
                                  (url) => Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: isDark
                                      ? AppColors.darkSurfaceVariant
                                      : AppColors.surfaceVariant,
                                  child: Icon(Icons.image_outlined,
                                      size: 60,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textHint),
                                ),
                              ),
                            ),
                            if (videoUrl != null && videoUrl.isNotEmpty)
                              NetworkVideoPlayer(videoUrl: videoUrl),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad['title'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if ((ad['description'] ?? '').isNotEmpty)
                            Text(
                              ad['description'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 10),
                          if ((ad['location'] ?? '').isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ad['location'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          if ((ad['offer'] ?? '').isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🎯 ${ad['offer']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ad['adminId'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                ad['createdAt']?.toString().split('T').first ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Engagement stats — each stat opens its own sheet ──
                          AdEngagementStatsRow(adId: adId, isDark: isDark),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () async {
                                bool confirm = await showConfirmDialog(
                                  context,
                                  title: 'Delete Ad',
                                  message: 'Are you sure you want to delete this ad?',
                                );
                                if (confirm) {
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
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: const Text('Delete', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}