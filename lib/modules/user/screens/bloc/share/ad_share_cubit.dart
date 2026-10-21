import 'dart:async';

import 'package:digitalads/data/repositories/ad_share_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State = share count (int).
class AdShareCubit extends Cubit<int> {
  final String adId;
  final AdShareRepository _repo;
  StreamSubscription<int>? _sub;

  AdShareCubit({required this.adId, required AdShareRepository repo})
      : _repo = repo,
        super(0) {
    _sub = _repo.watchShareCount(adId).listen(
      emit,
      onError: (e) => debugPrint('Share count error: $e'),
    );
  }

  Future<void> recordShare() async {
    try {
      await _repo.recordShare(adId);
    } catch (e) {
      debugPrint('Record share failed: $e');
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}