import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../app/theme.dart';

class AdminAdsScreen extends StatelessWidget {
  final String adminId;
  final String adminName;

  const AdminAdsScreen({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  String _getFirstImageUrl(Map<String, dynamic> ad) {
    if (ad['imageUrls'] != null) {
      if (ad['imageUrls'] is List) {
        final list = List<dynamic>.from(ad['imageUrls']);
        if (list.isNotEmpty) return list.first.toString();
      } else if (ad['imageUrls'] is Map) {
        final map = Map<dynamic, dynamic>.from(ad['imageUrls']);
        if (map.isNotEmpty) return map.values.first.toString();
      }
    }
    if (ad['imageUrl'] != null && ad['imageUrl'].toString().isNotEmpty) {
      return ad['imageUrl'].toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '$adminName\'s Ads',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            return _emptyState('No Ads Found');
          }

          final adsMap = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final adsList = adsMap.entries.where((e) {
            final ad = Map<String, dynamic>.from(e.value);
            return ad['adminId'] == adminId;
          }).toList();

          if (adsList.isEmpty) {
            return _emptyState('No Ads Posted by this Admin');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adsList.length,
            itemBuilder: (context, index) {
              final ad = Map<String, dynamic>.from(adsList[index].value);
              final imageUrl = _getFirstImageUrl(ad);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _AdDetailScreen(
                        ad: ad,
                        adKey: adsList[index].key.toString(),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14),
                        ),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(),
                        )
                            : _imagePlaceholder(),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if ((ad['description'] ?? '').isNotEmpty)
                                Text(
                                  ad['description'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      ad['location'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Delete + arrow
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text('Delete Ad'),
                                  content: const Text(
                                    'Are you sure you want to delete this ad?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseDatabase.instance
                                    .ref('ads/${adsList[index].key}')
                                    .remove();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ad deleted'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                      const SizedBox(width: 4),
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

  Widget _emptyState(String message) {
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
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textHint,
        size: 28,
      ),
    );
  }
}

// ── Ad Detail Screen ──────────────────────────────────────────────────────────
class _AdDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ad;
  final String adKey;

  const _AdDetailScreen({required this.ad, required this.adKey});

  List<String> _getAllImageUrls() {
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
    if (ad['imageUrl'] != null && ad['imageUrl'].toString().isNotEmpty) {
      urls.add(ad['imageUrl'].toString());
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _getAllImageUrls();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          ad['title'] ?? 'Ad Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text('Delete Ad'),
                  content: const Text(
                      'Are you sure you want to delete this ad?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseDatabase.instance.ref('ads/$adKey').remove();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            if (imageUrls.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: AppColors.textHint,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if ((ad['description'] ?? '').isNotEmpty) ...[
                    Text(
                      ad['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if ((ad['offer'] ?? '').isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🎯 ${ad['offer']}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if ((ad['location'] ?? '').isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          ad['location'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),
                  Text(
                    'Posted: ${ad['createdAt']?.toString().split('T').first ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}