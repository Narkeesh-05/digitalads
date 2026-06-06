abstract class UserEvent {}

class SendOtpEvent extends UserEvent {
  final String phoneNumber;
  SendOtpEvent({required this.phoneNumber});
}

class VerifyOtpEvent extends UserEvent {
  final String otp;
  VerifyOtpEvent({required this.otp});
}