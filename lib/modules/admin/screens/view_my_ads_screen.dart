import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ViewMyAdsScreen extends StatefulWidget {
  const ViewMyAdsScreen({super.key});

  @override
  State<ViewMyAdsScreen> createState() => _ViewMyAdsScreenState();
}

class _ViewMyAdsScreenState extends State<ViewMyAdsScreen> {
  final String _adminId = FirebaseAuth.instance.currentUser!.uid;
  List<String> imageUrls = [];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'My Ads',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('ads').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
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
                    'No Ads Posted Yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> adsMap =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          List<Map<String, dynamic>> adsList = adsMap.entries
              .where((e) =>
          Map<String, dynamic>.from(e.value)['adminId'] == _adminId)
              .map((e) => {
            'id': e.key,
            ...Map<String, dynamic>.from(e.value),
          })
              .toList();

          if (adsList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ad_units, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Ads Posted Yet!',
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

// Multiple images
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

// Single image
              if (imageUrls.isEmpty &&
                  ad['imageUrl'] != null &&
                  ad['imageUrl'].toString().isNotEmpty) {
                imageUrls.add(ad['imageUrl'].toString());
              }

//
// // Single image
//               if (imageUrls.isEmpty &&
//                   ad['imageUrl'] != null &&
//                   ad['imageUrl'].toString().isNotEmpty) {
//                 imageUrls.add(ad['imageUrl'].toString());
//               }
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
                    //
                    //   child: Image.network(
                    //     ad['imageUrl'] ?? '',
                    //     width: double.infinity,
                    //     height: 180,
                    //     fit: BoxFit.cover,
                    //     errorBuilder: (_, __, ___) => Container(
                    //       height: 180,
                    //       width: double.infinity,
                    //       color: Colors.grey[200],
                    //       child: const Icon(Icons.image, size: 60),
                    //     ),
                    //   ),
                    // ),

                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: imageUrls.isNotEmpty
                          ? Image.network(
                        imageUrls.first,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 60),
                      ),
                    ),
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
                          const SizedBox(height: 4),
                          if (ad['offer'] != null && ad['offer'] != '')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🎯 ${ad['offer']}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              Text(
                                ad['location'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () async {
                                  await FirebaseDatabase.instance
                                      .ref('ads/${ad['id']}')
                                      .remove();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ad Deleted!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
      ),
    );
  }
}