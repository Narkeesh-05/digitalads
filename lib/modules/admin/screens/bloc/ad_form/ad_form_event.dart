import 'package:digitalads/data/models/ad_form_data.dart';

abstract class AdFormEvent {}

class AdFormStarted extends AdFormEvent {}

class DraftChanged extends AdFormEvent {
  final AdFormData data;
  DraftChanged(this.data);
}

class SubmitAd extends AdFormEvent {
  final AdFormData data;
  SubmitAd(this.data);
}