
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';  // FIXED: Added missing import
import 'package:video_player/video_player.dart';

// If you don't have AppColors defined, add this class
// Otherwise, import your theme file
class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color error = Color(0xFFD32F2F);
// Add other colors as needed
}

// OR uncomment this if you have the file:
// import '../../../app/theme.dart';

class AdDetailsScreen extends StatefulWidget {
  final String adId;
  final Map<dynamic, dynamic> ad;

  const AdDetailsScreen({
    super.key,
    required this.adId,
    required this.ad,
  });

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();

  VideoPlayerController? _videoController;

  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isSubmittingComment = false;
  bool _viewRegistered = false;

  String? _currentUserName;

  @override
  void initState() {
    super.initState();

    _loadCurrentUser();
    _registerView();
    _loadLikeStatus();
    _initializeVideo();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();

      if (!mounted) return;

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        setState(() {
          _currentUserName = (data['name'] ?? user.displayName ?? 'User').toString();
        });
      } else {
        setState(() {
          _currentUserName = user.displayName ?? 'User';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUserName = user.displayName ?? 'User';
        });
      }
    }
  }

  // ============================================================
  // VIEW TRACKING
  // ============================================================

  Future<void> _registerView() async {
    if (_viewRegistered) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final uid = user.uid;

    try {
      final viewRef = FirebaseDatabase.instance.ref('ads/${widget.adId}/views/$uid');

      final snapshot = await viewRef.get();

      // Already viewed by this user.
      if (snapshot.exists) {
        if (mounted) {
          setState(() {
            _viewRegistered = true;
          });
        }
        return;
      }

      // First view by this user.
      await viewRef.set({
        'userId': uid,
        'viewedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _viewRegistered = true;
        });
      }
    } catch (e) {
      debugPrint('View registration error: $e');
    }
  }

  // ============================================================
  // LIKE STATUS
  // ============================================================

  Future<void> _loadLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('ads/${widget.adId}/likes/${user.uid}')
          .get();

      if (!mounted) return;

      setState(() {
        _isLiked = snapshot.exists;
      });
    } catch (e) {
      debugPrint('Like status error: $e');
    }
  }

  // ============================================================
  // LIKE / UNLIKE
  // ============================================================

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar(
        'Please login to like this ad.',
        isError: true,
      );
      return;
    }

    final uid = user.uid;

    final likeRef = FirebaseDatabase.instance.ref('ads/${widget.adId}/likes/$uid');

    try {
      if (_isLiked) {
        await likeRef.remove();

        if (mounted) {
          setState(() {
            _isLiked = false;
          });
        }
      } else {
        await likeRef.set({
          'userId': uid,
          'userName': _currentUserName ?? 'User',
          'likedAt': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          setState(() {
            _isLiked = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Like error: $e');

      _showSnackBar(
        'Unable to update like.',
        isError: true,
      );
    }
  }

  // ============================================================
  // VIDEO
  // ============================================================

  Future<void> _initializeVideo() async {
    final videoUrl = _getVideoUrl();

    if (videoUrl == null || videoUrl.isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
      });
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  // ============================================================
  // DATA HELPERS
  // ============================================================

  List<String> _getImageUrls() {
    final rawImages = widget.ad['imageUrls'];

    if (rawImages == null) return [];

    if (rawImages is List) {
      return rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    if (rawImages is Map) {
      return rawImages.values.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return [];
  }

  String? _getVideoUrl() {
    final value = widget.ad['videoUrl'];

    if (value == null) return null;

    final url = value.toString().trim();

    if (url.isEmpty || url == 'null') return null;

    return url;
  }

  String _getTitle() {
    return (widget.ad['title'] ?? 'Untitled Ad').toString();
  }

  String _getDescription() {
    return (widget.ad['description'] ?? '').toString();
  }

  String _getOffer() {
    return (widget.ad['offer'] ?? '').toString();
  }

  // ============================================================
  // SHARE - FIXED
  // ============================================================

  Future<void> _shareAd() async {
    final title = _getTitle();
    final description = _getDescription();

    final text = '''
$title

$description

Check this ad on Digital Ads.
''';

    // FIXED: Correct share_plus syntax
    try {
      await Share.share(
        text,
        subject: title,  // Optional subject
      );

      _showSnackBar('Ad shared successfully!');
    } catch (e) {
      _showSnackBar('Error sharing: $e', isError: true);
    }
  }

  // ============================================================
  // COMMENT
  // ============================================================

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar(
        'Please login to comment.',
        isError: true,
      );
      return;
    }

    final text = _commentController.text.trim();

    if (text.isEmpty) {
      _showSnackBar(
        'Please enter a comment.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final commentRef = FirebaseDatabase.instance.ref('ads/${widget.adId}/comments').push();

      await commentRef.set({
        'userId': user.uid,
        'userName': _currentUserName ?? 'User',
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _commentController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();

        _showSnackBar(
          'Comment added.',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Comment error: $e');

      _showSnackBar(
        'Unable to add comment.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    // FIXED: Using Theme instead of undefined AppColors
    final theme = Theme.of(context);
    final color = isError
        ? Colors.red.shade700
        : const Color(0xFF1D9E75);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final images = _getImageUrls();
    final videoUrl = _getVideoUrl();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.blue.shade700, // FIXED: Used default color
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Ad Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareAd,
            icon: const Icon(
              Icons.share_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ======================================================
            // MEDIA
            // ======================================================

            _buildMediaSection(
              context,
              images,
              videoUrl,
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _getTitle(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Offer
                  if (_getOffer().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700.withOpacity(.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getOffer(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  if (_getOffer().isNotEmpty) const SizedBox(height: 14),

                  // Description
                  if (_getDescription().isNotEmpty) ...[
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withOpacity(.75),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ==================================================
                  // ACTIONS
                  // ==================================================

                  _buildActionRow(context),

                  const SizedBox(height: 16),

                  // ==================================================
                  // VIEW COUNT
                  // ==================================================

                  _buildViewCount(context),

                  const SizedBox(height: 22),

                  // ==================================================
                  // COMMENTS
                  // ==================================================

                  _buildCommentsSection(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEDIA SECTION
  // ============================================================

  Widget _buildMediaSection(
      BuildContext context,
      List<String> images,
      String? videoUrl,
      ) {
    final hasImages = images.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    if (!hasImages && !hasVideo) {
      return Container(
        height: 300,
        color: Colors.black12,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (hasImages)
          SizedBox(
            height: 360,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _openImageViewer(
                      context,
                      images,
                      index,
                    );
                  },
                  child: Hero(
                    tag: '${widget.adId}_image_$index',
                    child: Image.network(
                      images[index],
                      width: double.infinity,
                      height: 360,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

        if (hasImages && images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                    (index) {
                  final active = index == _currentImageIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? Colors.blue.shade700 : Colors.grey.withOpacity(.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ),

        // ========================================================
        // VIDEO
        // ========================================================

        if (hasVideo)
          Padding(
            padding: const EdgeInsets.only(
              top: 14,
              left: 16,
              right: 16,
            ),
            child: _buildVideoPlayer(context),
          ),
      ],
    );
  }

  // ============================================================
  // VIDEO PLAYER
  // ============================================================

  Widget _buildVideoPlayer(BuildContext context) {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),

              GestureDetector(
                onTap: () {
                  setState(() {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  });
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: controller.value.isPlaying ? 0 : 1,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTION ROW
  // ============================================================

  Widget _buildActionRow(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('ads/${widget.adId}/likes').onValue,
      builder: (context, snapshot) {
        int likeCount = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final value = snapshot.data!.snapshot.value;

          if (value is Map) {
            likeCount = value.length;
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withOpacity(.15),
            ),
          ),
          child: Row(
            children: [
              _actionButton(
                icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? const Color(0xFFE24B4A) : theme.colorScheme.onSurface.withOpacity(.55),
                label: '$likeCount',
                onTap: _toggleLike,
              ),

              const SizedBox(width: 8),

              StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('ads/${widget.adId}/comments').onValue,
                builder: (context, commentSnapshot) {
                  int commentCount = 0;

                  if (commentSnapshot.hasData && commentSnapshot.data!.snapshot.value != null) {
                    final value = commentSnapshot.data!.snapshot.value;

                    if (value is Map) {
                      commentCount = value.length;
                    }
                  }

                  return _actionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(.55),
                    label: '$commentCount',
                    onTap: () {
                      _focusCommentField();
                    },
                  );
                },
              ),

              const SizedBox(width: 8),

              _actionButton(
                icon: Icons.share_outlined,
                color: theme.colorScheme.onSurface.withOpacity(.55),
                label: 'Share',
                onTap: _shareAd,
              ),

              const Spacer(),

              // Views
              _buildSmallViewCount(context),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VIEW COUNT
  // ============================================================

  Widget _buildSmallViewCount(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('ads/${widget.adId}/views').onValue,
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final value = snapshot.data!.snapshot.value;

          if (value is Map) {
            count = value.length;
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewCount(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('ads/${widget.adId}/views').onValue,
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final value = snapshot.data!.snapshot.value;

          if (value is Map) {
            count = value.length;
          }
        }

        return Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 20,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 7),
            Text(
              '$count views',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.65),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // COMMENTS SECTION
  // ============================================================

  Widget _buildCommentsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        // Add comment
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(.45),
                  ),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? theme.colorScheme.surfaceContainerHighest.withOpacity(.35)
                      : const Color(0xFFF4F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              height: 48,
              width: 48,
              child: IconButton(
                onPressed: _isSubmittingComment ? null : _addComment,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmittingComment
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.send_rounded,
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Comments
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('ads/${widget.adId}/comments').onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No comments yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(.5),
                    ),
                  ),
                ),
              );
            }

            final raw = snapshot.data!.snapshot.value;

            if (raw is! Map) {
              return const SizedBox.shrink();
            }

            final comments = Map<dynamic, dynamic>.from(raw);

            final entries = comments.entries.toList();

            entries.sort((a, b) {
              final aTime = DateTime.tryParse((a.value['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);

              final bTime = DateTime.tryParse((b.value['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);

              return bTime.compareTo(aTime);
            });

            return Column(
              children: entries.map((entry) {
                final data = Map<dynamic, dynamic>.from(
                  entry.value as Map,
                );

                final name = (data['userName'] ?? 'User').toString();

                final text = (data['text'] ?? '').toString();

                final createdAt = (data['createdAt'] ?? '').toString();

                return _buildCommentItem(
                  context,
                  name,
                  text,
                  createdAt,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // COMMENT ITEM
  // ============================================================

  Widget _buildCommentItem(
      BuildContext context,
      String name,
      String text,
      String createdAt,
      ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(.30)
            : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade700.withOpacity(.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: theme.colorScheme.onSurface.withOpacity(.75),
                  ),
                ),

                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return '';

    final local = date.toLocal();

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  // ============================================================
  // IMAGE FULL VIEWER
  // ============================================================

  void _openImageViewer(
      BuildContext context,
      List<String> images,
      int initialIndex,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageViewer(
          images: images,
          initialIndex: initialIndex,
          adId: widget.adId,
        ),
      ),
    );
  }

  // ============================================================
  // FOCUS COMMENT
  // ============================================================

  void _focusCommentField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      FocusScope.of(context).requestFocus(
        FocusNode(),
      );
    });
  }
}

// ==================================================================
// FULL IMAGE VIEWER
// ==================================================================

class _FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String adId;

  const _FullImageViewer({
    required this.images,
    required this.initialIndex,
    required this.adId,
  });

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Hero(
                tag: '${widget.adId}_image_$index',
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 60,
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}