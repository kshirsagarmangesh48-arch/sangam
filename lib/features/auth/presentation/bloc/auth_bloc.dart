import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sangam_expense/features/auth/data/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  ChangePasswordRequested(this.oldPassword, this.newPassword);
  @override
  List<Object> get props => [oldPassword, newPassword];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  AuthAuthenticated(this.user);
  @override
  List<Object> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
  @override
  List<Object> get props => [error];
}

class AuthPasswordSuccess extends AuthState {
  final String message;
  AuthPasswordSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await authRepository.getStoredUser();
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await authRepository.login(event.email, event.password);
        emit(AuthAuthenticated(result['data']['user']));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    });

    on<ChangePasswordRequested>((event, emit) async {
      final currentState = state;
      emit(AuthLoading());
      try {
        final result = await authRepository.changePassword(event.oldPassword, event.newPassword);
        emit(AuthPasswordSuccess(result['message'] ?? 'Password changed successfully'));
        // Restore previous state (Authenticated) after success
        if (currentState is AuthAuthenticated) {
          emit(currentState);
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
        if (currentState is AuthAuthenticated) {
          emit(currentState);
        }
      }
    });
  }
}
