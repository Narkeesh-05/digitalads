abstract class SuperAdminEvent {}

class SuperAdminLoginEvent extends SuperAdminEvent {
  final String email;
  final String password;

  SuperAdminLoginEvent({
    required this.email,
    required this.password,
  });
}