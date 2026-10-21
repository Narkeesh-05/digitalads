import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminAuthException implements Exception {
  final String message;
  AdminAuthException(this.message);

  @override
  String toString() => message;
}

class AdminRepository {
  AdminRepository({FirebaseAuth? auth, FirebaseDatabase? database})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = database ?? FirebaseDatabase.instance;

  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  /// Signs in and verifies the user exists under `admins/{uid}`.
  /// Throws [AdminAuthException] with a user-friendly message on failure.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AdminAuthException('Login failed. Try again!');
      }

      final snapshot = await _db.ref('admins/$uid').get();
      if (!snapshot.exists) {
        await _auth.signOut();
        throw AdminAuthException('You are not an Admin!');
      }
    } on AdminAuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AdminAuthException(_mapAuthError(e.code));
    } catch (_) {
      // e.g. network / database permission error after sign-in
      await _auth.signOut();
      throw AdminAuthException(
        'Something went wrong. Check your internet and try again!',
      );
    }
  }

  Future<void> logout() => _auth.signOut();

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Invalid email or password!';
      case 'user-disabled':
        return 'This account is disabled!';
      case 'too-many-requests':
        return 'Too many attempts. Try again later!';
      case 'network-request-failed':
        return 'No internet connection!';
      default:
        return 'Login failed. Try again!';
    }
  }
}