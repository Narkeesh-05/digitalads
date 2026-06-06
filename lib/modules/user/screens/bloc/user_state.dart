abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class OtpSentState extends UserState {}

class UserLoginSuccess extends UserState {}

class UserNewRegistration extends UserState {}

class UserLoginError extends UserState {
  final String message;
  UserLoginError({required this.message});
}