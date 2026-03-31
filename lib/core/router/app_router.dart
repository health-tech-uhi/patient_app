import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointments/presentation/appointments_tab.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/home_tab.dart';
import '../../features/doctors/presentation/doctor_book_screen.dart';
import '../../features/doctors/presentation/doctors_tab.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/records/presentation/records_tab.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.isRegisteredAsPatient != next.isRegisteredAsPatient) {
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.initial) return null;

      final publicAuth = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password';
      final authed = auth.status == AuthStatus.authenticated;

      if (!authed && !publicAuth) return '/login';

      if (authed && publicAuth) {
        if (!auth.isRegisteredAsPatient) return '/onboarding';
        return '/home';
      }

      if (authed &&
          !auth.isRegisteredAsPatient &&
          loc != '/onboarding' &&
          !loc.startsWith('/onboarding')) {
        return '/onboarding';
      }

      if (authed && auth.isRegisteredAsPatient && loc == '/onboarding') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctors',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const DoctorsTab(),
                ),
                routes: [
                  GoRoute(
                    path: ':id/book',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DoctorBookScreen(doctorId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/appointments',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AppointmentsTab(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/records',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const RecordsTab(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
