import 'dart:ui';
import 'package:digitalads/modules/user/screens/user_drawer.dart';
import 'package:digitalads/modules/user/screens/wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import 'ad_search_delegate.dart';
import 'network_video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../app/theme.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseDatabase.instance.ref('users/$uid').update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    }
  }

  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  void _showEnquiryDialog(BuildContext context, Map<String, dynamic> ad) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    final isDark = context.read<ThemeProvider>().isDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Send Enquiry',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Message',
                  prefixIcon: const Icon(
                    Icons.message_outlined,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill name and phone!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await FirebaseDatabase.instance.ref('enquiries').push().set({
                'adId': ad['id'],
                'adTitle': ad['title'],
                'adminId': ad['adminId'],
                'userName': nameController.text.trim(),
                'userPhone': phoneController.text.trim(),
                'message': messageController.text.trim(),
                'userId': FirebaseAuth.instance.currentUser!.uid,
                'createdAt': DateTime.now().toIso8601String(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enquiry Sent Successfully!'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuizDialog(BuildContext context, Map<String, dynamic> ad) async {
    final adId = ad['id'];
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (adId != null) {
      final attemptSnap = await FirebaseDatabase.instance
          .ref('ads/$adId/quizAttempts/$userId')
          .get();
      if (attemptSnap.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You've already attempted this quiz!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    final quiz = Map<String, dynamic>.from(ad['quiz'] as Map);
    final List<dynamic> options = quiz['options'];
    int selectedIndex = -1;
    final isDark = context.read<ThemeProvider>().isDark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '📝 Quiz Time!',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz['question'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                options.length,
                    (index) => GestureDetector(
                  onTap: () {
                    setDialogState(() => selectedIndex = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedIndex == index
                          ? AppColors.primarySurface
                          : (isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedIndex == index
                            ? AppColors.primary
                            : (isDark
                            ? AppColors.darkBorder
                            : AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedIndex == index
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: selectedIndex == index
                              ? AppColors.primary
                              : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textHint),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          options[index].toString(),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedIndex == -1
                  ? null
                  : () async {
                int correctIndex = quiz['correctIndex'] ?? 0;
                bool isCorrect = selectedIndex == correctIndex;

                // Record the attempt so this user can't retry.
                if (adId != null) {
                  await FirebaseDatabase.instance
                      .ref('ads/$adId/quizAttempts/$userId')
                      .set({
                    'selectedIndex': selectedIndex,
                    'correct': isCorrect,
                    'attemptedAt': DateTime.now().toIso8601String(),
                  });
                }

                if (isCorrect) {
                  DatabaseReference pointsRef = FirebaseDatabase
                      .instance
                      .ref('users/$userId/points');

                  final snapshot = await pointsRef.get();
                  int currentPoints = snapshot.exists
                      ? (snapshot.value as int)
                      : 0;

                  await pointsRef.set(currentPoints + 10);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🎉 Correct! You earned 10 points!',
                        ),
                        backgroundColor: Color(0xFF1D9E75),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Wrong Answer! Better luck next time!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      drawer: UserDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'DigitalAds',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: AdSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref('users/${FirebaseAuth.instance.currentUser!.uid}')
            .onValue,
        builder: (context, userSnapshot) {
          double? userLat;
          double? userLng;

          if (userSnapshot.hasData &&
              userSnapshot.data!.snapshot.value != null) {
            final userData = Map<String, dynamic>.from(
              userSnapshot.data!.snapshot.value as Map,
            );
            userLat = (userData['latitude'] as num?)?.toDouble();
            userLng = (userData['longitude'] as num?)?.toDouble();
          }

          return StreamBuilder(
            stream: FirebaseDatabase.instance.ref('ads').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _AdListSkeleton(isDark: isDark);
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return _EmptyState(
                  isDark: isDark,
                  icon: Icons.campaign_outlined,
                  message: 'No ads available right now',
                  subtitle: 'Check back later for local deals near you',
                );
              }

              Map<dynamic, dynamic> adsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<Map<String, dynamic>> adsList = adsMap.entries.map((e) {
                final ad = Map<String, dynamic>.from(e.value);
                ad['id'] = e.key;

                double distance = 999999;

                if (userLat != null &&
                    userLng != null &&
                    ad['latitude'] != null &&
                    ad['longitude'] != null) {
                  distance = _calculateDistance(
                    userLat,
                    userLng,
                    (ad['latitude'] as num).toDouble(),
                    (ad['longitude'] as num).toDouble(),
                  );
                }

                ad['distance'] = distance;

                return ad;
              }).toList();

              adsList.sort((a, b) {
                return (a['distance'] as double).compareTo(
                  b['distance'] as double,
                );
              });

              if (adsList.isEmpty) {
                return _EmptyState(
                  isDark: isDark,
                  icon: Icons.location_off_outlined,
                  message: 'No ads near your location',
                  subtitle: 'Try expanding your search area',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: adsList.length,
                itemBuilder: (context, index) {
                  final ad = adsList[index];

                  List<String> imageUrls = [];
                  if (ad['imageUrls'] != null) {
                    if (ad['imageUrls'] is List) {
                      imageUrls = List<String>.from(ad['imageUrls']);
                    } else if (ad['imageUrls'] is Map) {
                      imageUrls = Map<dynamic, dynamic>.from(
                        ad['imageUrls'],
                      ).values.map((e) => e.toString()).toList();
                    }
                  }
                  if (ad['imageUrl'] != null &&
                      ad['imageUrl'].toString().isNotEmpty) {
                    imageUrls.add(ad['imageUrl'].toString());
                  }

                  String? videoUrl = ad['videoUrl'];
                  bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;
                  int totalSlides = imageUrls.length + (hasVideo ? 1 : 0);

                  return _AdCard(
                    ad: ad,
                    imageUrls: imageUrls,
                    videoUrl: hasVideo ? videoUrl : null,
                    totalSlides: totalSlides,
                    isDark: isDark,
                    onEnquire: () => _showEnquiryDialog(context, ad),
                    onQuiz: () => _showQuizDialog(context, ad),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// AD CARD — with carousel + dots indicator + like/comment/share/whatsapp
// ════════════════════════════════════════════════════════════════════════
class _AdCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  final List<String> imageUrls;
  final String? videoUrl;
  final int totalSlides;
  final bool isDark;
  final VoidCallback onEnquire;
  final VoidCallback onQuiz;

  const _AdCard({
    required this.ad,
    required this.imageUrls,
    required this.videoUrl,
    required this.totalSlides,
    required this.isDark,
    required this.onEnquire,
    required this.onQuiz,
  });

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  int _currentSlide = 0;
  String? _adminPhone;

  @override
  void initState() {
    super.initState();
    _loadAdminPhone();
  }

  Future<void> _loadAdminPhone() async {
    final adminId = widget.ad['adminId'];
    if (adminId == null) return;

    try {
      final snapshot =
      await FirebaseDatabase.instance.ref('admins/$adminId/phone').get();
      if (snapshot.exists && mounted) {
        setState(() => _adminPhone = snapshot.value.toString());
      }
    } catch (_) {
      // Silently ignore — WhatsApp button just won't show.
    }
  }

  Future<void> _openWhatsApp() async {
    if (_adminPhone == null || _adminPhone!.isEmpty) return;

    final digits = _adminPhone!.replaceAll(RegExp(r'[^0-9]'), '');
    final title = widget.ad['title'] ?? 'your ad';
    final message = Uri.encodeComponent(
      "Hi, I'm interested in \"$title\" that I saw on DigitalAds.",
    );
    final url = Uri.parse('https://wa.me/$digits?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _shareAd() {
    final title = widget.ad['title'] ?? 'Check this out';
    final description = widget.ad['description'] ?? '';
    final offer = widget.ad['offer'];

    final text = StringBuffer()
      ..writeln(title)
      ..writeln()
      ..writeln(description);

    if (offer != null && offer.toString().isNotEmpty) {
      text.writeln();
      text.writeln('🎯 Offer: $offer');
    }

    text.writeln();
    text.writeln('Seen on DigitalAds');

    Share.share(text.toString());
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(adId: widget.ad['id'], isDark: widget.isDark),
    );
  }

  Future<void> _toggleLike() async {
    final adId = widget.ad['id'];
    if (adId == null) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final likeRef = FirebaseDatabase.instance.ref('ads/$adId/likes/$userId');
    final snapshot = await likeRef.get();

    if (snapshot.exists) {
      await likeRef.remove();
    } else {
      await likeRef.set(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final isDark = widget.isDark;
    final double distance = ad['distance'] as double;
    final adId = ad['id'];
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: AppColors.primaryDeep.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carousel with dots ──────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 220,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: false,
                    onPageChanged: (index, reason) {
                      setState(() => _currentSlide = index);
                    },
                  ),
                  items: [
                    ...widget.imageUrls.map(
                          (url) => _NetworkImageWithShimmer(url: url, isDark: isDark),
                    ),
                    if (widget.videoUrl != null)
                      NetworkVideoPlayer(videoUrl: widget.videoUrl!),
                  ],
                ),
              ),

              // Distance badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        distance < 1
                            ? "${(distance * 1000).toStringAsFixed(0)} m"
                            : "${distance.toStringAsFixed(1)} km",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Dots indicator (Amazon style) ──────────────
              if (widget.totalSlides > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.totalSlides, (index) {
                      final isActive = index == _currentSlide;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),

              // Slide count badge (1/4 style) — top right
              if (widget.totalSlides > 1)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentSlide + 1}/${widget.totalSlides}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Content ──────────────────────────────────────────
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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ad['description'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ad['offer'] != null && ad['offer'] != '') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🎯 ${ad['offer']}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        ad['location'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Like / Comment / Share / WhatsApp row ──────
                if (adId != null)
                  StreamBuilder<DatabaseEvent>(
                    stream:
                    FirebaseDatabase.instance.ref('ads/$adId/likes').onValue,
                    builder: (context, likeSnap) {
                      int likeCount = 0;
                      bool isLiked = false;

                      if (likeSnap.hasData &&
                          likeSnap.data!.snapshot.value != null) {
                        final likesMap = Map<dynamic, dynamic>.from(
                          likeSnap.data!.snapshot.value as Map,
                        );
                        likeCount = likesMap.length;
                        isLiked = likesMap.containsKey(userId);
                      }

                      final hintColor = isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textHint;
                      final labelColor = isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary;

                      return Row(
                        children: [
                          _actionIcon(
                            icon: isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked ? const Color(0xFFE24B4A) : hintColor,
                            labelColor: labelColor,
                            label: likeCount > 0 ? '$likeCount' : 'Like',
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 6),
                          StreamBuilder<DatabaseEvent>(
                            stream: FirebaseDatabase.instance
                                .ref('ads/$adId/comments')
                                .onValue,
                            builder: (context, commentSnap) {
                              int commentCount = 0;
                              if (commentSnap.hasData &&
                                  commentSnap.data!.snapshot.value != null) {
                                commentCount = Map<dynamic, dynamic>.from(
                                  commentSnap.data!.snapshot.value as Map,
                                ).length;
                              }
                              return _actionIcon(
                                icon: Icons.chat_bubble_outline_rounded,
                                color: hintColor,
                                labelColor: labelColor,
                                label: commentCount > 0
                                    ? '$commentCount'
                                    : 'Comment',
                                onTap: _openComments,
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          _actionIcon(
                            icon: Icons.share_outlined,
                            color: hintColor,
                            labelColor: labelColor,
                            label: 'Share',
                            onTap: _shareAd,
                          ),
                          const Spacer(),
                          if (_adminPhone != null && _adminPhone!.isNotEmpty)
                            GestureDetector(
                              onTap: _openWhatsApp,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366)
                                      .withOpacity(.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat,
                                  size: 18,
                                  color: Color(0xFF25D366),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onEnquire,
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('Enquire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 23),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (ad['quiz'] != null)
                      Builder(
                        builder: (context) {
                          final quiz = Map<String, dynamic>.from(
                            ad['quiz'] as Map,
                          );
                          if (quiz['question'] == null ||
                              quiz['question'] == '') {
                            return const SizedBox();
                          }

                          if (adId == null) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: OutlinedButton.icon(
                                onPressed: widget.onQuiz,
                                icon: const Icon(Icons.quiz_outlined, size: 15),
                                label: const Text('Quiz'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          return StreamBuilder<DatabaseEvent>(
                            stream: FirebaseDatabase.instance
                                .ref('ads/$adId/quizAttempts/$userId')
                                .onValue,
                            builder: (context, attemptSnap) {
                              final attempted = attemptSnap.hasData &&
                                  attemptSnap.data!.snapshot.value != null;

                              bool? wasCorrect;
                              if (attempted) {
                                final data = Map<String, dynamic>.from(
                                  attemptSnap.data!.snapshot.value as Map,
                                );
                                wasCorrect = data['correct'] == true;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: OutlinedButton.icon(
                                  onPressed: attempted ? null : widget.onQuiz,
                                  icon: Icon(
                                    attempted
                                        ? (wasCorrect == true
                                        ? Icons.check_circle_rounded
                                        : Icons.quiz_outlined)
                                        : Icons.quiz_outlined,
                                    size: 15,
                                  ),
                                  label: Text(
                                    attempted ? 'Attempted' : 'Quiz',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: attempted
                                        ? (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textHint)
                                        : AppColors.primary,
                                    disabledForegroundColor: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textHint,
                                    side: BorderSide(
                                      color: attempted
                                          ? (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border)
                                          : AppColors.primary,
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
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

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required Color labelColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMMENTS BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════
class _CommentsSheet extends StatefulWidget {
  final String adId;
  final bool isDark;

  const _CommentsSheet({required this.adId, required this.isDark});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String userName = 'User';

      final userSnap =
      await FirebaseDatabase.instance.ref('users/$uid/name').get();
      if (userSnap.exists) {
        userName = userSnap.value.toString();
      }

      await FirebaseDatabase.instance
          .ref('ads/${widget.adId}/comments')
          .push()
          .set({
        'userId': uid,
        'userName': userName,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      });

      _commentController.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _timeAgo(String raw) {
    try {
      final date = DateTime.parse(raw);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Comments',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Divider(
                height: 20,
                color: isDark ? AppColors.darkBorder : AppColors.divider,
              ),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('ads/${widget.adId}/comments')
                      .onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return Center(
                        child: Text(
                          'No comments yet — be the first!',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey.shade500,
                          ),
                        ),
                      );
                    }

                    final map = Map<dynamic, dynamic>.from(
                      snapshot.data!.snapshot.value as Map,
                    );
                    final comments = map.entries.map((e) {
                      return Map<String, dynamic>.from(e.value);
                    }).toList();

                    comments.sort((a, b) => (b['createdAt'] ?? '')
                        .toString()
                        .compareTo((a['createdAt'] ?? '').toString()));

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primarySurface,
                                child: Text(
                                  (c['userName'] ?? 'U')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c['userName'] ?? 'User',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _timeAgo(
                                              (c['createdAt'] ?? '')
                                                  .toString()),
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
                                      c['text'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary,
                                        height: 1.3,
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
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textHint,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                          : IconButton(
                        onPressed: _postComment,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// NETWORK IMAGE — with blur/shimmer loading (YouTube style)
// ════════════════════════════════════════════════════════════════════════
class _NetworkImageWithShimmer extends StatelessWidget {
  final String url;
  final bool isDark;

  const _NetworkImageWithShimmer({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _ShimmerBox(isDark: isDark);
      },
      errorBuilder: (_, __, ___) => Container(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
        ),
      ),
    );
  }
}

/// Grey shimmer/blur placeholder shown while loading.
class _ShimmerBox extends StatefulWidget {
  final bool isDark;

  const _ShimmerBox({this.isDark = false});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
    widget.isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE2E1F0);
    final highlightColor =
    widget.isDark ? AppColors.darkBorder : const Color(0xFFF1F0FA);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: baseColor),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(-1.0 + _controller.value * 3, 0),
                end: Alignment(0.0 + _controller.value * 3, 0),
              ).createShader(rect);
            },
            child: Container(color: baseColor),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// SKELETON LOADER — full list shimmer while ads are first loading
// ════════════════════════════════════════════════════════════════════════
class _AdListSkeleton extends StatelessWidget {
  final bool isDark;

  const _AdListSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(height: 220, child: _ShimmerBox(isDark: isDark)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 220,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
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
  }
}

// ════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Icon(icon, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
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
}