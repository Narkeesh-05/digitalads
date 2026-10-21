import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the selected bottom-nav tab index of the Admin home screen.
class AdminNavCubit extends Cubit<int> {
  AdminNavCubit() : super(0);

  void select(int index) {
    if (index != state) emit(index);
  }
}