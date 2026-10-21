import 'dart:async';

import 'package:digitalads/data/repositories/feed_repository.dart';
import 'package:digitalads/data/services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _repo;
  final LocationService _location;

  FeedBloc({
    required FeedRepository repo,
    required LocationService location,
  })  : _repo = repo,
        _location = location,
        super(FeedLoading()) {
    on<FeedStarted>(_onStarted);
  }

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    emit(FeedLoading());

    // Location update parallel ah poganum; feed stream user location
    // maarumbodhu thaane refresh aagum.
    unawaited(_refreshLocation());

    await emit.forEach<List<Map<String, dynamic>>>(
      _repo.watchFeed(),
      onData: (ads) => ads.isEmpty ? FeedEmpty() : FeedLoaded(ads),
      onError: (error, _) {
        debugPrint('Feed error: $error');
        return FeedError('Unable to load ads');
      },
    );
  }

  Future<void> _refreshLocation() async {
    try {
      final pos = await _location.current();
      if (pos != null) {
        await _repo.saveMyLocation(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('Location refresh failed: $e');
    }
  }
}