import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Builds and shares a message with a clickable link that opens the
/// product — via a Firebase Hosting landing page, since Firebase Dynamic
/// Links was shut down by Google on 25 Aug 2025 and no longer works.
///
/// Setup required (see ad_landing_page.html):
///  1. Deploy ad_landing_page.html to Firebase Hosting as `/ad.html`.
///  2. Enable Anonymous Authentication in the Firebase console (Authentication
///     > Sign-in method) — the landing page uses it to read the ad despite
///     your `auth != null` database rules, without weakening them.
///  3. Replace hostingDomain below with your actual Hosting URL
///     (e.g. https://digitalads-84cb8.web.app).
Future<void> shareAd({
  required String adId,
  required Map<String, dynamic> ad,
}) async {
  const hostingDomain = 'https://YOUR-PROJECT.web.app'; // TODO: replace
  final link = '$hostingDomain/ad.html?id=$adId';

  final title = (ad['title'] ?? 'Check out this ad on DigitalAds').toString();
  final priceValue = ad['price'];
  final priceLine = (priceValue != null && priceValue.toString().isNotEmpty) ? '₹$priceValue' : null;

  final message = [
    title,
    if (priceLine != null) priceLine,
    '',
    'View it here: $link',
  ].join('\n');

  await Share.share(message, subject: title);
}

/// Drop-in share button for the ad detail screen's action row.
class ShareAdButton extends StatelessWidget {
  final String adId;
  final Map<String, dynamic> ad;

  const ShareAdButton({super.key, required this.adId, required this.ad});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => shareAd(adId: adId, ad: ad),
      icon: const Icon(Icons.share_rounded),
      tooltip: 'Share',
    );
  }
} 