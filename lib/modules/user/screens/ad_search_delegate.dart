import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search ads by location or title...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  String _getFirstImage(Map<String, dynamic> ad) {
    try {
      if (ad['imageUrls'] != null) {
        if (ad['imageUrls'] is List) {
          final list = List<dynamic>.from(ad['imageUrls'] as List);
          if (list.isNotEmpty) return list.first.toString();
        } else if (ad['imageUrls'] is Map) {
          final map =
          Map<dynamic, dynamic>.from(ad['imageUrls'] as Map);
          if (map.isNotEmpty) return map.values.first.toString();
        }
      }
      if (ad['imageUrl'] != null) return ad['imageUrl'].toString();
    } catch (e) {
      return '';
    }
    return '';
  }

  Widget _buildSearchResults() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('ads').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.snapshot.value == null) {
          return const Center(
            child: Text('No Ads Found!'),
          );
        }

        Map<dynamic, dynamic> adsMap =
        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        List<Map<String, dynamic>> adsList = adsMap.entries
            .map((e) => {
          'id': e.key,
          ...Map<String, dynamic>.from(e.value),
        })
            .where((ad) =>
        ad['title']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()) ||
            ad['location']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();

        if (adsList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Ads Found!',
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
            String firstImage = _getFirstImage(ad);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: firstImage.isNotEmpty
                      ? Image.network(
                    firstImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
                title: Text(
                  ad['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.grey),
                    Text(
                      ad['location'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}