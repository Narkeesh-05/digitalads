abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoginSuccess extends AdminState {}

class AdminLoginError extends AdminState {
  final String message;
  AdminLoginError({required this.message});
}