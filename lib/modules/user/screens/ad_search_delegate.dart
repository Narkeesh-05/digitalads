import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// Result of parsing a raw search query.
///
/// Two shapes:
///  - Combined ("pants in Trichy") — [productTerm] and [locationTerm] must
///    BOTH match (AND), same as Amazon narrowing a product search by city.
///  - Free text ("saree") — a single term that can match EITHER the
///    product fields OR the location (OR), for broad recall when the user
///    hasn't specified a location.
class ParsedSearchQuery {
  final String? productTerm;
  final String? locationTerm;
  final bool isCombinedQuery;

  const ParsedSearchQuery({
    this.productTerm,
    this.locationTerm,
    this.isCombinedQuery = false,
  });

  bool get isEmpty => productTerm == null && locationTerm == null;
}

/// Splits on the first standalone " in " (case-insensitive), Amazon-style:
/// "pants in trichy" -> product="pants", location="trichy".
/// Plain "saree" (no " in ") stays a single broad term.
ParsedSearchQuery parseAdSearchQuery(String rawQuery) {
  final trimmed = rawQuery.trim();
  if (trimmed.isEmpty) return const ParsedSearchQuery();

  final match = RegExp(r'^(.*?)\s+in\s+(.+)$', caseSensitive: false).firstMatch(trimmed);

  if (match != null) {
    final product = match.group(1)?.trim();
    final location = match.group(2)?.trim();
    return ParsedSearchQuery(
      productTerm: (product != null && product.isNotEmpty) ? product : null,
      locationTerm: (location != null && location.isNotEmpty) ? location : null,
      isCombinedQuery: true,
    );
  }

  return ParsedSearchQuery(productTerm: trimmed, locationTerm: trimmed);
}

/// Whether a single ad map satisfies the parsed query. Pure function, no
/// Firebase/Flutter dependency — easy to unit test on its own.
bool adMatchesSearch(Map<String, dynamic> ad, ParsedSearchQuery parsed) {
  if (parsed.isEmpty) return false;

  final title = (ad['title'] ?? '').toString().toLowerCase();
  final category = (ad['category'] ?? '').toString().toLowerCase();
  final description = (ad['description'] ?? '').toString().toLowerCase();
  final location = (ad['location'] ?? '').toString().toLowerCase();

  bool matchesProduct(String term) =>
      title.contains(term) || category.contains(term) || description.contains(term);
  bool matchesLocation(String term) => location.contains(term);

  if (parsed.isCombinedQuery) {
    // "pants in Trichy" — both sides must match (AND), narrowing the search.
    final productOk = parsed.productTerm == null || matchesProduct(parsed.productTerm!.toLowerCase());
    final locationOk = parsed.locationTerm == null || matchesLocation(parsed.locationTerm!.toLowerCase());
    return productOk && locationOk;
  }

  // Plain free text — broad OR match so "saree" surfaces every saree ad
  // regardless of which city it's in.
  final term = parsed.productTerm!.toLowerCase();
  return matchesProduct(term) || matchesLocation(term);
}

class AdSearchDelegate extends SearchDelegate {
  AdSearchDelegate() : _adsFuture = FirebaseDatabase.instance.ref('ads').onValue.first;

  // Fetched exactly ONCE per search session and cached as a Future.
  //
  // Why .onValue.first instead of .get()? .get() has known reliability
  // issues in some firebase_database plugin versions — it can throw an
  // internal type-cast error ("Null is not a subtype of type Future...")
  // instead of resolving. .onValue.first is the older, more battle-tested
  // one-time-read pattern: it subscribes to the live stream, takes just
  // the first event, then cancels — same net effect as .get(), without
  // that bug.
  //
  // Why not a Stream directly (even a broadcast one)? buildSuggestions()
  // and buildResults() each mount their OWN builder widget, at different
  // times, and both need to read the same data:
  //  - A plain Stream can only be listened to once — the second builder's
  //    subscribe attempt throws "Stream has already been listened to".
  //  - A broadcast Stream fixes that crash, but introduces a worse, silent
  //    bug: if the one-and-only "initial value" event fires before anyone
  //    is listening (e.g. because the query started empty, so no builder
  //    subscribed yet), that event is dropped forever — broadcast streams
  //    do NOT buffer or replay past events to late listeners.
  //
  // A Future has neither problem: it always remembers its one resolved
  // value, and any number of FutureBuilders — no matter when they start
  // listening — get that same value immediately.
  //
  // Trade-off: results are a snapshot at search-open time, not live. Fine
  // for a search session, which is short-lived by nature.
  final Future<DatabaseEvent> _adsFuture;

  @override
  String get searchFieldLabel => 'Search "pants in Trichy" or just "saree"...';

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
  Widget buildResults(BuildContext context) => _buildSearchBody();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchBody();

  Widget _buildSearchBody() {
    final parsed = parseAdSearchQuery(query);

    // Don't show anything (let alone the full ad list) until the user has
    // actually typed something.
    if (parsed.isEmpty) {
      return const _SearchHint();
    }

    return FutureBuilder<DatabaseEvent>(
      future: _adsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _NoResults();
        }

        final value = snapshot.data?.snapshot.value;
        if (value == null) {
          return const _NoResults();
        }

        final adsMap = Map<dynamic, dynamic>.from(value as Map);

        final results = adsMap.entries
            .map((e) => <String, dynamic>{
          'id': e.key,
          ...Map<String, dynamic>.from(e.value as Map),
        })
            .where((ad) => adMatchesSearch(ad, parsed))
            .toList();

        if (results.isEmpty) return const _NoResults();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) => _AdResultTile(ad: results[index]),
        );
      },
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search by product or location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            SizedBox(height: 6),
            Text(
              'Try "saree" or "pants in Trichy"',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No Ads Found!', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _AdResultTile extends StatelessWidget {
  final Map<String, dynamic> ad;
  const _AdResultTile({required this.ad});

  String get _firstImage {
    try {
      final imageUrls = ad['imageUrls'];
      if (imageUrls is List && imageUrls.isNotEmpty) {
        return imageUrls.first.toString();
      }
      if (imageUrls is Map && imageUrls.isNotEmpty) {
        return imageUrls.values.first.toString();
      }
      if (ad['imageUrl'] != null) return ad['imageUrl'].toString();
    } catch (_) {
      // Fall through to empty — the placeholder icon below covers this.
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final image = _firstImage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image.isNotEmpty
              ? Image.network(
            image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(),
          )
              : _imagePlaceholder(),
        ),
        title: Text(
          (ad['title'] ?? '').toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 2),
            Text(
              (ad['location'] ?? '').toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.image),
    );
  }
}