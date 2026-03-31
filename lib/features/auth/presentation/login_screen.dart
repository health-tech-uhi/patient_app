import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/ui/feedback/app_snack_bar.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      AppSnackBar.show(context, 'Enter email or phone', isError: true);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).generateOtp(identifier: id);
      if (!mounted) return;
      AppSnackBar.show(context, 'OTP sent');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final loading = auth.status == AuthStatus.authenticating;

    ref.listen(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        AppSnackBar.show(context, next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('BlueSpan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: PatientTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to manage appointments and health records.',
                style: TextStyle(color: PatientTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                labelColor: PatientTheme.primary,
                tabs: const [
                  Tab(text: 'Password'),
                  Tab(text: 'OTP'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email or phone',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 0) {
                    return TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '6-digit OTP',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: loading ? null : _requestOtp,
                        child: const Text('Send OTP'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading
                    ? null
                    : () {
                        final id = _identifierController.text.trim();
                        if (_tabController.index == 0) {
                          ref.read(authNotifierProvider.notifier).loginWithPassword(
                                id,
                                _passwordController.text,
                              );
                        } else {
                          ref.read(authNotifierProvider.notifier).loginWithOtp(
                                id,
                                _otpController.text.trim(),
                              );
                        }
                      },
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
