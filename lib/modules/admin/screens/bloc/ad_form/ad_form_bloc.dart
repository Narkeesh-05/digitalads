import 'package:digitalads/data/models/ad_form_data.dart';
import 'package:digitalads/data/repositories/ad_draft_repository.dart';
import 'package:digitalads/data/repositories/ad_repository.dart';
import 'package:digitalads/data/repositories/media_upload_repository.dart';
import 'package:digitalads/data/services/location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import 'ad_form_event.dart';
import 'ad_form_state.dart';

EventTransformer<E> _debounce<E>(Duration duration) =>
        (events, mapper) => events.debounce(duration).switchMap(mapper);

class AdFormBloc extends Bloc<AdFormEvent, AdFormState> {
  final String? adId;
  final AdRepository _ads;
  final MediaUploadRepository _media;
  final AdDraftRepository _drafts;
  final LocationService _location;

  bool _posted = false;

  bool get isEdit => adId != null;

  AdFormBloc({
    this.adId,
    required AdRepository ads,
    required MediaUploadRepository media,
    required AdDraftRepository drafts,
    required LocationService location,
  })  : _ads = ads,
        _media = media,
        _drafts = drafts,
        _location = location,
        super(adId != null ? AdFormLoading() : AdFormInitial()) {
    on<AdFormStarted>(_onStarted);
    on<DraftChanged>(
      _onDraftChanged,
      transformer: _debounce(const Duration(milliseconds: 500)),
    );
    on<SubmitAd>(_onSubmit);
  }

  Future<void> _onStarted(
      AdFormStarted event,
      Emitter<AdFormState> emit,
      ) async {
    if (isEdit) {
      emit(AdFormLoading());
      try {
        emit(AdFormLoaded(await _ads.fetchAdForEdit(adId!)));
      } on AdException catch (e) {
        emit(AdFormLoadFailed(e.message));
      } catch (_) {
        emit(AdFormLoadFailed('Unable to load ad. Please try again.'));
      }
    } else {
      final draft = await _drafts.restore();
      if (draft != null) emit(AdFormLoaded(draft, fromDraft: true));
    }
  }

  Future<void> _onDraftChanged(
      DraftChanged event,
      Emitter<AdFormState> emit,
      ) async {
    if (isEdit || _posted) return;
    await _drafts.save(event.data);
  }

  Future<void> _onSubmit(SubmitAd event, Emitter<AdFormState> emit) async {
    final error = AdFormValidator.validate(event.data);
    if (error != null) {
      emit(AdFormFailure(error));
      return;
    }

    emit(AdFormSubmitting());

    try {
      final imageUrls = await _media.resolveImages(event.data.images);
      final videoUrl = await _media.resolveVideo(
        newVideo: event.data.video,
        existingUrl: event.data.existingVideoUrl,
      );

      if (isEdit) {
        await _ads.updateAd(
          adId: adId!,
          data: event.data,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
        );
      } else {
        final pos = await _location.current();
        await _ads.createAd(
          data: event.data,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          latitude: pos?.latitude,
          longitude: pos?.longitude,
        );
        _posted = true;
        await _drafts.clear();
      }

      emit(AdFormSuccess(isEdit: isEdit));
    } on AdException catch (e) {
      emit(AdFormFailure(e.message));
    } catch (e) {
      emit(AdFormFailure('Error: $e'));
    }
  }
}