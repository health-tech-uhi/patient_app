/// Wired from [AuthNotifier] so [AuthInterceptor] can notify the app without importing Riverpod.
class AuthSessionBridge {
  static void Function()? onSessionExpired;
}
