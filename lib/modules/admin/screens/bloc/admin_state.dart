// abstract class AdminState {}
//
// class AdminInitial extends AdminState {}
//
// class AdminLoading extends AdminState {}
//
// class AdminLoginSuccess extends AdminState {}
//
// class AdminLoginError extends AdminState {
//   final String message;
//   AdminLoginError({required this.message});
// }

import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminLoginSuccess extends AdminState {
  const AdminLoginSuccess();
}

class AdminLoginError extends AdminState {
  final String message;

  const AdminLoginError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminLogoutSuccess extends AdminState {
  const AdminLogoutSuccess();
}