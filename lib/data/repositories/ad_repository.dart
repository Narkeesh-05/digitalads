import 'package:digitalads/data/models/ad_form_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdException implements Exception {
  final String message;
  AdException(this.message);
  @override
  String toString() => message;
}

class AdRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  AdRepository({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get currentUid {
    final user = _auth.currentUser;
    if (user == null) throw AdException('User is not logged in.');
    return user.uid;
  }

  /// Loads an ad for editing. Only the owner may edit it.
  Future<AdFormData> fetchAdForEdit(String adId) async {
    final snap = await _db.ref('ads/$adId').get();

    if (!snap.exists || snap.value is! Map) {
      throw AdException('This ad no longer exists.');
    }

    final data = Map<String, dynamic>.from(snap.value as Map);

    if (data['adminId'] != currentUid) {
      throw AdException('You can only edit your own ads.');
    }

    return AdFormData.fromMap(data);
  }

  Future<void> createAd({
    required AdFormData data,
    required List<String> imageUrls,
    String? videoUrl,
    double? latitude,
    double? longitude,
  }) {
    return _db.ref('ads').push().set({
      ..._adMap(data, imageUrls, videoUrl),
      'adminId': currentUid,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// update() only touches these fields, so likes, comments, views and
  /// quiz attempts stay as they are.
  Future<void> updateAd({
    required String adId,
    required AdFormData data,
    required List<String> imageUrls,
    String? videoUrl,
  }) {
    return _db.ref('ads/$adId').update({
      ..._adMap(data, imageUrls, videoUrl),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, Object?> _adMap(
      AdFormData d,
      List<String> imageUrls,
      String? videoUrl,
      ) {
    final whatsapp = d.whatsapp.trim();
    return {
      'title': d.title.trim(),
      'description': d.description.trim(),
      'offer': d.offer.trim(),
      'phone': '+91${d.phone.trim()}',
      'whatsapp': whatsapp.isEmpty ? null : '+91$whatsapp',
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'status': d.status,
      'quiz': {
        'question': d.quizQuestion.trim(),
        'options': d.options.map((o) => o.trim()).toList(),
        'correctIndex': d.correctIndex,
      },
    };
  }
}