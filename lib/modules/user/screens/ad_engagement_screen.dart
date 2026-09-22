import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';


// ============================================================================
// SHARED USER RESOLUTION (name / email / photo from users/{uid})
// ============================================================================

class _UserLookup {
  static final Map<String, Map<String, String>> _cache = {};

  static Future<Map<String, String>> resolve(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;

    String name = 'Unknown User';
    String email = '';
    String photoUrl = '';

    try {
      final snapshot =
      await FirebaseDatabase.instance.ref('users/$userId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        name = (data['name'] ?? 'Unknown User').toString();
        email = (data['email'] ?? '').toString();
        photoUrl =
            (data['photoUrl'] ?? data['profileImage'] ?? '').toString();
      }
    } catch (_) {}

    final result = {'name': name, 'email': email, 'photoUrl': photoUrl};
    _cache[userId] = result;
    return result;
  }
}

String _timeAgo(String raw) {
  if (raw.isEmpty) return '';
  try {
    final date = DateTime.parse(raw);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  } catch (_) {
    return '';
  }
}

// ============================================================================
// STATS ROW — drop this into any ad card. Each stat is independently
// tappable and opens ONLY that list (no tabs).
// ============================================================================

class AdEngagementStatsRow extends StatelessWidget {
  final String adId;
  final bool isDark;

  const AdEngagementStatsRow({
    super.key,
    required this.adId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('ads/$adId').onValue,
      builder: (context, snapshot) {
        int likeCount = 0;
        int commentCount = 0;
        int viewCount = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final adData =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
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
            _statButton(
              context,
              icon: Icons.favorite_border_rounded,
              count: likeCount,
              onTap: () => AdEngagementSheets.showLikes(
                context,
                adId: adId,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            _statButton(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              count: commentCount,
              onTap: () => AdEngagementSheets.showComments(
                context,
                adId: adId,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            _statButton(
              context,
              icon: Icons.visibility_outlined,
              count: viewCount,
              onTap: () => AdEngagementSheets.showViews(
                context,
                adId: adId,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statButton(
      BuildContext context, {
        required IconData icon,
        required int count,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEETS — one per stat, no tabs. Call these directly from anywhere
// (a stat button, a menu item, etc).
// ============================================================================

class AdEngagementSheets {
  AdEngagementSheets._();

  static void showLikes(
      BuildContext context, {
        required String adId,
        required bool isDark,
      }) {
    _showSheet(
      context,
      isDark: isDark,
      title: 'Likes',
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFE24B4A),
      body: (scrollController) => StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('ads/$adId/likes').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(
                isDark, Icons.favorite_border_rounded, 'No likes yet');
          }
          final userIds =
          Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map)
              .keys
              .map((e) => e.toString())
              .toList();

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: userIds.length,
            itemBuilder: (context, i) => _userTile(isDark, userIds[i]),
          );
        },
      ),
    );
  }

  static void showViews(
      BuildContext context, {
        required String adId,
        required bool isDark,
      }) {
    _showSheet(
      context,
      isDark: isDark,
      title: 'Views',
      icon: Icons.visibility_rounded,
      iconColor: Colors.blueGrey,
      body: (scrollController) => StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('ads/$adId/views').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(
                isDark, Icons.visibility_outlined, 'No views yet');
          }
          final map =
          Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final userIds = map.keys.map((e) => e.toString()).toList();

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: userIds.length,
            itemBuilder: (context, i) => _userTile(
              isDark,
              userIds[i],
              trailing: _timeAgo(map[userIds[i]]?.toString() ?? ''),
            ),
          );
        },
      ),
    );
  }

  static void showComments(
      BuildContext context, {
        required String adId,
        required bool isDark,
      }) {
    _showSheet(
      context,
      isDark: isDark,
      title: 'Comments',
      icon: Icons.chat_bubble_rounded,
      iconColor: AppColors.primary,
      body: (scrollController) => StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('ads/$adId/comments').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _emptyState(
                isDark, Icons.chat_bubble_outline_rounded, 'No comments yet');
          }
          final map =
          Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final comments =
          map.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();

          comments.sort((a, b) => (b['createdAt'] ?? '')
              .toString()
              .compareTo((a['createdAt'] ?? '').toString()));

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: comments.length,
            itemBuilder: (context, i) {
              final c = comments[i];
              final userName = (c['userName'] ?? 'User').toString();
              final text = (c['text'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        userName.isNotEmpty
                            ? userName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _timeAgo((c['createdAt'] ?? '').toString()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
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

  // -- shared sheet chrome ---------------------------------------------------

  static void _showSheet(
      BuildContext context, {
        required bool isDark,
        required String title,
        required IconData icon,
        required Color iconColor,
        required Widget Function(ScrollController scrollController) body,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                      isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                  ),
                  Expanded(child: body(scrollController)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _emptyState(bool isDark, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _userTile(bool isDark, String userId, {String? trailing}) {
    return FutureBuilder<Map<String, String>>(
      future: _UserLookup.resolve(userId),
      builder: (context, snap) {
        final name = snap.data?['name'] ?? '...';
        final email = snap.data?['email'] ?? '';
        final photoUrl = snap.data?['photoUrl'] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primarySurface,
                backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary, size: 17)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                    isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}