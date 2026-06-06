import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = '';

  UserBloc() : super(UserInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
  }

  Future<void> _onSendOtp(
      SendOtpEvent event,
      Emitter<UserState> emit,
      ) async {
    emit(UserLoading());
    try {
      final completer = Completer<void>();

      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) completer.complete();
          emit(UserLoginSuccess());
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) completer.complete();
          emit(UserLoginError(message: 'Verification failed!'));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete();
          emit(OtpSentState());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future;
    } catch (e) {
      emit(UserLoginError(message: 'Something went wrong!'));
    }
  }

  Future<void> _onVerifyOtp(
      VerifyOtpEvent event,
      Emitter<UserState> emit,
      ) async {
    emit(UserLoading());
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: event.otp,
      );
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      String uid = userCredential.user!.uid;

      final snapshot = await FirebaseDatabase.instance
          .ref('users/$uid')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        emit(UserLoginSuccess());
      } else {
        emit(UserNewRegistration());
      }
    } on FirebaseAuthException catch (e) {
      emit(UserLoginError(message: 'Invalid OTP!'));
    } catch (e) {
      emit(UserLoginError(message: 'Something went wrong! ${e.toString()}'));
    }
  }
}