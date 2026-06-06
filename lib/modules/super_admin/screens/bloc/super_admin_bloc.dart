import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'super_admin_event.dart';
import 'super_admin_state.dart';

class SuperAdminBloc extends Bloc<SuperAdminEvent, SuperAdminState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SuperAdminBloc() : super(SuperAdminInitial()) {
    on<SuperAdminLoginEvent>(_onLogin);
  }

  Future<void> _onLogin(
      SuperAdminLoginEvent event,
      Emitter<SuperAdminState> emit,
      ) async {
    emit(SuperAdminLoading());
    try {
      await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(SuperAdminLoginSuccess());
    } catch (e) {
      emit(SuperAdminLoginError(message: 'Invalid email or password!'));
    }
  }
}