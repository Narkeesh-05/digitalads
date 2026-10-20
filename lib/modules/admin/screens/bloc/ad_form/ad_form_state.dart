import 'package:digitalads/data/models/ad_form_data.dart';

abstract class AdFormState {}

class AdFormInitial extends AdFormState {}

class AdFormLoading extends AdFormState {}

class AdFormLoaded extends AdFormState {
  final AdFormData data;
  final bool fromDraft;
  AdFormLoaded(this.data, {this.fromDraft = false});
}

class AdFormLoadFailed extends AdFormState {
  final String message;
  AdFormLoadFailed(this.message);
}

class AdFormSubmitting extends AdFormState {}

class AdFormSuccess extends AdFormState {
  final bool isEdit;
  AdFormSuccess({required this.isEdit});
}

class AdFormFailure extends AdFormState {
  final String message;
  AdFormFailure(this.message);
}