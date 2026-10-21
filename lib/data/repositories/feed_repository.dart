import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class FeedRepository {
  /// null  = ella ads-um kaattum (ippo irukkura madhiri, distance padi sort mattum).
  /// 30    = 30 km kulla ulla ads mattum kaattum.
  static const double? radiusKm = null;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  FeedRepository({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Saves the user's latest position (the feed uses it for distance).
  Future<void> saveMyLocation(double lat, double lng) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.ref('users/$uid').update({'latitude': lat, 'longitude': lng});
  }

  /// Live feed: ads + the user's location combined, sorted nearest first.
  /// Re-emits when either the ads or the user's location change.
  Stream<List<Map<String, dynamic>>> watchFeed() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    StreamSubscription<DatabaseEvent>? userSub;
    StreamSubscription<DatabaseEvent>? adsSub;

    double? userLat;
    double? userLng;
    Object? adsValue;
    var adsReady = false;

    void push() {
      if (!adsReady || controller.isClosed) return;
      controller.add(_buildFeed(adsValue, userLat, userLng));
    }

    controller.onListen = () {
      final uid = _uid;
      if (uid != null) {
        userSub = _db.ref('users/$uid').onValue.listen((event) {
          final v = event.snapshot.value;
          if (v is Map) {
            userLat = (v['latitude'] as num?)?.toDouble();
            userLng = (v['longitude'] as num?)?.toDouble();
          }
          push();
        }, onError: controller.addError);
      }

      adsSub = _db.ref('ads').onValue.listen((event) {
        adsValue = event.snapshot.value;
        adsReady = true;
        push();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await userSub?.cancel();
      await adsSub?.cancel();
    };

    return controller.stream;
  }

  List<Map<String, dynamic>> _buildFeed(
      Object? adsValue,
      double? userLat,
      double? userLng,
      ) {
    if (adsValue is! Map) return [];

    final ads = <Map<String, dynamic>>[];

    for (final entry in adsValue.entries) {
      final value = entry.value;
      if (value is! Map) continue;

      final ad = Map<String, dynamic>.from(value);
      ad['id'] = entry.key.toString();
      ad['imageUrls'] = _parseImageUrls(ad);

      var distance = 999999.0;
      final adLat = (ad['latitude'] as num?)?.toDouble();
      final adLng = (ad['longitude'] as num?)?.toDouble();
      if (userLat != null && userLng != null && adLat != null && adLng != null) {
        distance =
            Geolocator.distanceBetween(userLat, userLng, adLat, adLng) / 1000;
      }
      ad['distance'] = distance;

      final limit = radiusKm;
      if (limit != null && distance > limit) continue;

      ads.add(ad);
    }

    ads.sort(
          (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );
    return ads;
  }

  /// imageUrls can be a List or a Map; old ads also have a single imageUrl.
  List<String> _parseImageUrls(Map<String, dynamic> ad) {
    final urls = <String>[];
    final raw = ad['imageUrls'];
    if (raw is List) {
      urls.addAll(raw.where((e) => e != null).map((e) => e.toString()));
    } else if (raw is Map) {
      urls.addAll(raw.values.map((e) => e.toString()));
    }
    final legacy = (ad['imageUrl'] ?? '').toString();
    if (legacy.isNotEmpty && !urls.contains(legacy)) urls.add(legacy);
    return urls;
  }
}