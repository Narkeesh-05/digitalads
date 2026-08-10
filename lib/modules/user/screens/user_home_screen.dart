import 'dart:ui';
import 'package:digitalads/modules/user/screens/user_drawer.dart';
import 'package:digitalads/modules/user/screens/wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                decoration: InputDecoration(
                  labelText: 'Message',
                  prefixIcon: const Icon(
                    Icons.message_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
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

  void _showQuizDialog(BuildContext context, Map<String, dynamic> ad) {
    final quiz = Map<String, dynamic>.from(ad['quiz'] as Map);
    final List<dynamic> options = quiz['options'];
    int selectedIndex = -1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedIndex == index
                            ? AppColors.primary
                            : AppColors.border,
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
                              : AppColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(options[index].toString()),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: selectedIndex == -1
                  ? null
                  : () async {
                int correctIndex = quiz['correctIndex'] ?? 0;
                String userId = FirebaseAuth.instance.currentUser!.uid;

                if (selectedIndex == correctIndex) {
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
                        content: Text('❌ Wrong Answer! Try next time!'),
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
    return Scaffold(

      drawer:   UserDrawer( ),
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
                return const _AdListSkeleton();
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const _EmptyState(
                  icon: Icons.campaign_outlined,
                  message: 'No ads available right now',
                  subtitle: 'Check back later for local deals near you',
                );
              }

              Map<dynamic, dynamic> adsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<Map<String, dynamic>> adsList = adsMap.entries.map((e) {
                final ad = Map<String, dynamic>.from(e.value);

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
                return const _EmptyState(
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
// AD CARD — with carousel + dots indicator
// ════════════════════════════════════════════════════════════════════════
class _AdCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  final List<String> imageUrls;
  final String? videoUrl;
  final int totalSlides;
  final VoidCallback onEnquire;
  final VoidCallback onQuiz;

  const _AdCard({
    required this.ad,
    required this.imageUrls,
    required this.videoUrl,
    required this.totalSlides,
    required this.onEnquire,
    required this.onQuiz,
  });

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  int _currentSlide = 0;

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final double distance = ad['distance'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
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
                          (url) => _NetworkImageWithShimmer(url: url),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ad['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        ad['location'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onEnquire,
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('Enquire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 23),
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
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: OutlinedButton.icon(
                              onPressed: widget.onQuiz,
                              icon: const Icon(
                                Icons.quiz_outlined,
                                size: 15,
                              ),
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
}

// ════════════════════════════════════════════════════════════════════════
// NETWORK IMAGE — with blur/shimmer loading (YouTube style)
// ════════════════════════════════════════════════════════════════════════
class _NetworkImageWithShimmer extends StatelessWidget {
  final String url;

  const _NetworkImageWithShimmer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _ShimmerBox();
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

/// YouTube-style grey shimmer/blur placeholder shown while loading.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFE2E1F0)),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                colors: const [
                  Color(0xFFE2E1F0),
                  Color(0xFFF1F0FA),
                  Color(0xFFE2E1F0),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(-1.0 + _controller.value * 3, 0),
                end: Alignment(0.0 + _controller.value * 3, 0),
              ).createShader(rect);
            },
            child: Container(color: const Color(0xFFE2E1F0)),
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
  const _AdListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(height: 220, child: _ShimmerBox()),
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
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 220,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
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
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
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
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}