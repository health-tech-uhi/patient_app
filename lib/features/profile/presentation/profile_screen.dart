import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../patient/data/patient_repository.dart';
import '../../patient/domain/patient_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _dob = TextEditingController();
  String _gender = 'Not Specified';
  String _blood = 'Unknown';
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _aadhaar = TextEditingController();
  final _abhaOtp = TextEditingController();
  String? _txnId;
  bool _loading = false;

  static const _genders = ['Not Specified', 'Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _dob.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _aadhaar.dispose();
    _abhaOtp.dispose();
    super.dispose();
  }

  void _fill(PatientProfile p) {
    _firstName.text = p.firstName ?? '';
    _lastName.text = p.lastName ?? '';
    _dob.text = p.dateOfBirth ?? '';
    _gender = p.gender ?? 'Not Specified';
    _blood = p.bloodGroup ?? 'Unknown';
    _address.text = p.address ?? '';
    _city.text = p.city ?? '';
    _state.text = p.state ?? '';
    _pincode.text = p.pincode ?? '';
    _emergencyName.text = p.emergencyContactName ?? '';
    _emergencyPhone.text = p.emergencyContactPhone ?? '';
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final existing = ref.read(patientProfileProvider).when(
            data: (p) => p,
            loading: () => null,
            error: (_, __) => null,
          );
      final allergies = existing?.allergies ?? [];
      final payload = PatientProfile(id: existing?.id ?? '-').toUpdatePayload(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        dateOfBirth: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
        gender: _gender,
        bloodGroup: _blood,
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        state: _state.text.trim().isEmpty ? null : _state.text.trim(),
        pincode: _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
        emergencyContactName: _emergencyName.text.trim().isEmpty
            ? null
            : _emergencyName.text.trim(),
        emergencyContactPhone: _emergencyPhone.text.trim().isEmpty
            ? null
            : _emergencyPhone.text.trim(),
        allergies: allergies,
      );
      await ref.read(patientRepositoryProvider).updateProfile(payload);
      ref.invalidate(patientProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initAbha() async {
    if (!RegExp(r'^\d{12}$').hasMatch(_aadhaar.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 12-digit Aadhaar')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await ref.read(patientRepositoryProvider).initAbhaEnrollment(
            _aadhaar.text.trim(),
          );
      setState(() => _txnId = r['txn_id']?.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent (if configured)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAbha() async {
    if (_txnId == null || _abhaOtp.text.length != 6) return;
    setState(() => _loading = true);
    try {
      final abhaProfile = await ref.read(patientRepositoryProvider).verifyAbhaOtp(
            otp: _abhaOtp.text.trim(),
            txnId: _txnId!,
          );
      await ref.read(patientRepositoryProvider).linkAbhaProfile({
        'abha_number': abhaProfile['abha_number'] ?? abhaProfile['abhaNumber'],
        'abha_address': abhaProfile['preferred_abha_address'] ??
            abhaProfile['preferredAbhaAddress'],
        'abha_status': 'ACTIVE',
        'abha_profile_json': abhaProfile,
      });
      ref.invalidate(patientProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ABHA linked')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Patient profile not available.'),
            );
          }
          if (_firstName.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fill(profile);
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dob,
                  decoration: const InputDecoration(
                    labelText: 'Date of birth (YYYY-MM-DD)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? 'Not Specified'),
                ),
                DropdownButtonFormField<String>(
                  value: _blood,
                  decoration: const InputDecoration(labelText: 'Blood group'),
                  items: _bloodGroups
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _blood = v ?? 'Unknown'),
                ),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextField(
                  controller: _state,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                TextField(
                  controller: _pincode,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                ),
                TextField(
                  controller: _emergencyName,
                  decoration: const InputDecoration(
                    labelText: 'Emergency contact name',
                  ),
                ),
                TextField(
                  controller: _emergencyPhone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency contact phone',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Save profile'),
                ),
                const Divider(height: 40),
                const Text(
                  'ABHA (optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _aadhaar,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Aadhaar (12 digits)'),
                ),
                FilledButton.tonal(
                  onPressed: _loading ? null : _initAbha,
                  child: const Text('Send ABHA OTP'),
                ),
                TextField(
                  controller: _abhaOtp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ABHA OTP'),
                ),
                FilledButton.tonal(
                  onPressed: _loading ? null : _verifyAbha,
                  child: const Text('Verify & link ABHA'),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
