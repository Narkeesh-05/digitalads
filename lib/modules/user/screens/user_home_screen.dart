import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shop/modules/user/screens/user_drawer.dart';
import 'package:shop/modules/user/screens/wallet_screen.dart';
import 'ad_search_delegate.dart';
import 'network_video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'network_video_player.dart';
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
        title: const Text(
          'Send Enquiry',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message',
                  prefixIcon: const Icon(Icons.message, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
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
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
          title: const Text(
            '📝 Quiz Time!',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedIndex == index
                            ? Colors.green
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedIndex == index
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: selectedIndex == index
                              ? Colors.green
                              : Colors.grey,
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedIndex == -1
                  ? null
                  : () async {
                      int correctIndex = quiz['correctIndex'] ?? 0;
                      String userId = FirebaseAuth.instance.currentUser!.uid;

                      if (selectedIndex == correctIndex) {
                        DatabaseReference pointsRef = FirebaseDatabase.instance
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
                              backgroundColor: Colors.green,
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
      backgroundColor: Colors.grey[100],
      drawer: const UserDrawer(),
      // drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Digital Ads', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(context: context, delegate: AdSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.wallet, color: Colors.white),
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
                return const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                );
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ad_units, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Ads Available!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              Map<dynamic, dynamic> adsMap =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              List<Map<String, dynamic>> adsList = adsMap.entries
                  .map(
                    (e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)},
                  )
                  .where((ad) {
                    // If user location not available show all ads
                    if (userLat == null || userLng == null) return true;

                    // If ad has no location show it
                    if (ad['latitude'] == null || ad['longitude'] == null) {
                      return true;
                    }

                    double adLat = (ad['latitude'] as num).toDouble();
                    double adLng = (ad['longitude'] as num).toDouble();

                    double distance = _calculateDistance(
                      userLat!,
                      userLng!,
                      adLat,
                      adLng,
                    );

                    // Show ads within 30km
                    return distance <= 30;
                  })
                  .toList();

              if (adsList.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Ads near your location!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
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
                      imageUrls = Map<dynamic, dynamic>.from(ad['imageUrls'])
                          .values
                          .map((e) => e.toString())
                          .toList();
                    }
                  }

                  String? videoUrl = ad['videoUrl'];
                  String imageUrl = '';

                  if (ad['imageUrls'] != null) {
                    if (ad['imageUrls'] is List) {
                      final images = List<dynamic>.from(ad['imageUrls']);
                      if (images.isNotEmpty) {
                        imageUrl = images.first.toString();
                      }
                    } else if (ad['imageUrls'] is Map) {
                      final images = Map<dynamic, dynamic>.from(ad['imageUrls']);
                      if (images.isNotEmpty) {
                        imageUrl = images.values.first.toString();
                      }
                    }
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ClipRRect(
                        //   borderRadius: const BorderRadius.vertical(
                        //     top: Radius.circular(12),
                        //   ),
                        //   child: Image.network(
                        //     // ad['imageUrl'] ?? '',
                        //     imageUrl,
                        //     width: double.infinity,
                        //     height: 200,
                        //     fit: BoxFit.cover,
                        //     errorBuilder: (_, __, ___) => Container(
                        //       height: 200,
                        //       color: Colors.grey[200],
                        //       child: const Icon(Icons.image, size: 60),
                        //     ),
                        //   ),
                        // ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 220,
                              viewportFraction: 1.0,
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
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      size: 60,
                                    ),
                                  ),
                                ),
                              ),

                              if (videoUrl != null && videoUrl.isNotEmpty)
                                NetworkVideoPlayer(
                                  videoUrl: videoUrl,
                                ),
                            ],
                          ),
                        ),
                        if (ad['videoUrl'] != null &&
                            ad['videoUrl'].toString().isNotEmpty)
                          // Padding(
                          //   padding: const EdgeInsets.all(12),
                          //   child: NetworkVideoPlayer(
                          //     videoUrl: ad['videoUrl'].toString(),
                          //   ),
                          // ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ad['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (ad['offer'] != null && ad['offer'] != '')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '🎯 ${ad['offer']}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    ad['location'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showEnquiryDialog(context, ad),
                                    icon: const Icon(Icons.send, size: 16),
                                    label: const Text('Enquire'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                        return ElevatedButton.icon(
                                          onPressed: () =>
                                              _showQuizDialog(context, ad),
                                          icon: const Icon(
                                            Icons.quiz,
                                            size: 16,
                                          ),
                                          label: const Text('Take Quiz'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                },
              );
            },
          );
        },
      ),
    );
  }
}
