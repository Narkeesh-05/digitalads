import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdShareRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  AdShareRepository({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Live count of users who shared this ad.
  Stream<int> watchShareCount(String adId) {
    return _db.ref('ads/$adId/shares').onValue.map((event) {
      final value = event.snapshot.value;
      return value is Map ? value.length : 0;
    });
  }

  /// One user is counted once per ad (same idea as views).
  Future<void> recordShare(String adId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _db.ref('ads/$adId/shares/$uid');
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set(DateTime.now().toIso8601String());
    }
  }
}