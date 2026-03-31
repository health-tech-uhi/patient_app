import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session_bridge.dart';
import '../../../core/errors/user_facing_error.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../patient/data/patient_repository.dart';
import '../../patient/domain/patient_profile.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Patient demographics when registered; null if not a patient yet or logged out.
final patientProfileProvider =
    FutureProvider.autoDispose<PatientProfile?>((ref) async {
  final auth = ref.watch(authNotifierProvider);
  if (auth.status != AuthStatus.authenticated ||
      !auth.isRegisteredAsPatient) {
    return null;
  }
  final repo = ref.watch(patientRepositoryProvider);
  try {
    return await repo.getProfile();
  } on PatientProfileNotFoundException {
    return null;
  }
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  late final PatientRepository _patientRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _patientRepository = ref.watch(patientRepositoryProvider);
    AuthSessionBridge.onSessionExpired = onSessionExpired;

    Future.microtask(checkInitialStatus);

    return const AuthState();
  }

  /// Called from [AuthInterceptor] when refresh fails or there is no refresh token.
  /// Do **not** call [ref.invalidate] on [patientProfileProvider] here: that runs
  /// synchronously inside Dio’s error path while providers that depend on Dio may
  /// still be resolving, which triggers Riverpod’s `CircularDependencyError`.
  /// [patientProfileProvider] already [watch]es this notifier; clearing auth state
  /// is enough for it to rebuild and return `null`.
  void onSessionExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkInitialStatus() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (!isAuth) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    await _hydrateFromToken();
  }

  Future<void> loginWithPassword(String identifier, String password) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearErrorMessage: true,
    );
    try {
      final user = await _authRepository.login(
        identifier: identifier,
        credential: password,
        loginType: 'Password',
      );
      await _hydrateAfterLogin(user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFacingErrorMessage(
          e,
          context: ErrorUxContext.login,
        ),
      );
    }
  }

  Future<void> loginWithOtp(String identifier, String otp) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearErrorMessage: true,
    );
    try {
      final user = await _authRepository.login(
        identifier: identifier,
        credential: otp,
        loginType: 'Otp',
      );
      await _hydrateAfterLogin(user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFacingErrorMessage(
          e,
          context: ErrorUxContext.login,
        ),
      );
    }
  }

  Future<void> registerAndLogin({
    required String username,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearErrorMessage: true,
    );
    try {
      final user = await _authRepository.registerAndLogin(
        username: username,
        email: email,
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      await _hydrateAfterLogin(user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFacingErrorMessage(
          e,
          context: ErrorUxContext.signup,
        ),
      );
    }
  }

  Future<void> _hydrateAfterLogin(Map<String, dynamic>? user) async {
    try {
      await _patientRepository.getProfile();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isRegisteredAsPatient: true,
      );
      ref.invalidate(patientProfileProvider);
    } on PatientProfileNotFoundException {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isRegisteredAsPatient: false,
      );
      ref.invalidate(patientProfileProvider);
    }
  }

  Future<void> _hydrateFromToken() async {
    try {
      await _authRepository.switchToPatientProfileContext();
      await _patientRepository.getProfile();
      state = const AuthState(
        status: AuthStatus.authenticated,
        isRegisteredAsPatient: true,
      );
      ref.invalidate(patientProfileProvider);
    } on PatientProfileNotFoundException {
      state = const AuthState(
        status: AuthStatus.authenticated,
        isRegisteredAsPatient: false,
      );
      ref.invalidate(patientProfileProvider);
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.authenticated,
        isRegisteredAsPatient: false,
      );
    }
  }

  Future<void> refreshPatientRegistration() async {
    await _hydrateFromToken();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    AuthSessionBridge.onSessionExpired = onSessionExpired;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
