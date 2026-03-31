import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/feedback/app_snack_bar.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0;
  final _identifier = TextEditingController();
  final _otp = TextEditingController();
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _otp.dispose();
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordResetOtp(
            _identifier.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _step = 1;
        _loading = false;
      });
      AppSnackBar.show(context, 'OTP sent');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackBar.show(context, e.toString(), isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            identifier: _identifier.text.trim(),
            otp: _otp.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _step = 2;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackBar.show(context, e.toString(), isError: true);
    }
  }

  Future<void> _reset() async {
    if (_pass1.text.length < 8) {
      AppSnackBar.show(context, 'Password must be at least 8 characters',
          isError: true);
      return;
    }
    if (_pass1.text != _pass2.text) {
      AppSnackBar.show(context, 'Passwords do not match', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            identifier: _identifier.text.trim(),
            otp: _otp.text.trim(),
            newPassword: _pass1.text,
          );
      if (!mounted) return;
      AppSnackBar.show(context, 'Password updated. You can sign in.');
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackBar.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Step ${_step + 1} of 3',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_step == 0) ...[
                TextField(
                  controller: _identifier,
                  decoration: const InputDecoration(
                    labelText: 'Email or phone',
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Send OTP'),
                ),
              ],
              if (_step == 1) ...[
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '6-digit OTP'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Verify'),
                ),
              ],
              if (_step == 2) ...[
                TextField(
                  controller: _pass1,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass2,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _reset,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Update password'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
