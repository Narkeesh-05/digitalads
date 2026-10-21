/// Builds and parses the shareable link for an ad.
///
/// Shared link format:  https://<host>/ad/<adId>
///
/// Put this file at lib/core/ad_links.dart
class AdLinks {
  AdLinks._();

  /// Your Firebase Hosting domain, e.g. `digitalads-12345.web.app`
  /// (Firebase Console -> Hosting shows it). Must match the host in
  /// AndroidManifest.xml.
  // static const String host = 'YOUR-PROJECT-ID.web.app';
  static const String host = 'digitalads-84cb8.web.app';

  /// The link that goes into the shared message.
  static String adUrl(String adId) => 'https://$host/ad/$adId';

  /// Returns the ad id if [uri] is an ad link, otherwise null.
  static String? adIdFromUri(Uri uri) {
    if (uri.scheme == 'https' && uri.host != host) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'ad') {
      return segments[1];
    }
    return null;
  }
}
