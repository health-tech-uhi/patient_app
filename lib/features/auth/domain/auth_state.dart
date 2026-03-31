enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  /// Populated from login response when available.
  final Map<String, dynamic>? user;
  /// True when `GET /patients/profile` succeeds.
  final bool isRegisteredAsPatient;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
    this.isRegisteredAsPatient = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    Map<String, dynamic>? user,
    bool clearUser = false,
    bool? isRegisteredAsPatient,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
      isRegisteredAsPatient:
          isRegisteredAsPatient ?? this.isRegisteredAsPatient,
    );
  }
}
