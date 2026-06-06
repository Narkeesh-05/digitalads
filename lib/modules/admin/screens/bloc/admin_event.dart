abstract class AdminEvent {}

class AdminLoginEvent extends AdminEvent {
  final String email;
  final String password;

  AdminLoginEvent({
    required this.email,
    required this.password,
  });
}