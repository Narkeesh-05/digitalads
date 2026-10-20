// abstract class AdminEvent {}
//
// class AdminLoginEvent extends AdminEvent {
//   final String email;
//   final String password;
//
//   AdminLoginEvent({
//     required this.email,
//     required this.password,
//   });
// }

import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class AdminLoginEvent extends AdminEvent {
  final String email;
  final String password;

  const AdminLoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AdminLogoutEvent extends AdminEvent {
  const AdminLogoutEvent();
}