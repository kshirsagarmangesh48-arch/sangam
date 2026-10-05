import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSessionExpired>(_onAuthSessionExpired);
    on<AuthChangePasswordRequested>(_onAuthChangePasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Restoring session...'));
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (!isAuth) {
        emit(const AuthUnauthenticated());
        return;
      }

      final cachedUser = await authRepository.getCachedUser();
      if (cachedUser != null) {
        emit(AuthAuthenticated(cachedUser));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));
    try {
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
        rememberEmail: event.rememberEmail,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));
    try {
      await authRepository.logout();
    } catch (_) {}
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated(
      message: 'Your session has expired. Please log in again.',
    ));
  }

  Future<void> _onAuthChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    final currentUser = currentState.user;

    emit(const AuthLoading(message: 'Updating password...'));
    try {
      await authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(AuthPasswordChangeSuccess(
        user: currentUser,
        message: 'Password updated successfully',
      ));
      emit(AuthAuthenticated(currentUser));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthAuthenticated(currentUser));
    }
  }
}
