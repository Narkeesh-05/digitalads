// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'admin_event.dart';
// import 'admin_state.dart';
//
// class AdminBloc extends Bloc<AdminEvent, AdminState> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   AdminBloc() : super(AdminInitial()) {
//     on<AdminLoginEvent>(_onLogin);
//   }
//
//   Future<void> _onLogin(
//       AdminLoginEvent event,
//       Emitter<AdminState> emit,
//       ) async {
//     emit(AdminLoading());
//     try {
//       UserCredential userCredential =
//       await _auth.signInWithEmailAndPassword(
//         email: event.email,
//         password: event.password,
//       );
//
//       // Check if this user is admin in database
//       final snapshot = await FirebaseDatabase.instance
//           .ref('admins/${userCredential.user!.uid}')
//           .get();
//
//       if (snapshot.exists) {
//         emit(AdminLoginSuccess());
//       } else {
//         await _auth.signOut();
//         emit(AdminLoginError(message: 'You are not an Admin!'));
//       }
//     } catch (e) {
//       emit(AdminLoginError(message: 'Invalid email or password!'));
//     }
//   }
// }


import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({AdminRepository? repository})
      : _repository = repository ?? AdminRepository(),
        super(const AdminInitial()) {
    on<AdminLoginEvent>(_onLogin);
    on<AdminLogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(
      AdminLoginEvent event,
      Emitter<AdminState> emit,
      ) async {
    emit(const AdminLoading());
    try {
      await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(const AdminLoginSuccess());
    } on AdminAuthException catch (e) {
      emit(AdminLoginError(message: e.message));
    }
  }

  Future<void> _onLogout(
      AdminLogoutEvent event,
      Emitter<AdminState> emit,
      ) async {
    await _repository.logout();
    emit(const AdminLogoutSuccess());
  }
} 