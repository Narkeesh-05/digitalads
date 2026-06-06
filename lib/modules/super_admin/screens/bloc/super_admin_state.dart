abstract class SuperAdminState {}

class SuperAdminInitial extends SuperAdminState {}

class SuperAdminLoading extends SuperAdminState {}

class SuperAdminLoginSuccess extends SuperAdminState {}

class SuperAdminLoginError extends SuperAdminState {
  final String message;
  SuperAdminLoginError({required this.message});
}