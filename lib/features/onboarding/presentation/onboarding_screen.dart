import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/feedback/app_snack_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../patient/data/patient_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  /// Stored date; API requires `YYYY-MM-DD` for [date_of_birth] (Rust `NaiveDate`).
  DateTime? _dateOfBirth;
  String _gender = 'Not Specified';
  String _blood = 'Unknown';
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final List<_AllergyRow> _allergies = [];
  bool _loading = false;

  static const _genders = [
    'Not Specified',
    'Male',
    'Female',
    'Other',
  ];
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
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      AppSnackBar.show(context, 'First and last name are required',
          isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final allergies = _allergies
          .where((a) => a.name.text.trim().isNotEmpty)
          .map(
            (a) => {
              'allergen_name': a.name.text.trim(),
              'severity': a.severity,
              'reaction': a.reaction.text.trim().isEmpty
                  ? null
                  : a.reaction.text.trim(),
              'substance_id': null,
            },
          )
          .toList();

      final payload = {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'date_of_birth': _dateOfBirth == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'gender': _gender == 'Not Specified' ? null : _gender,
        'blood_group': _blood == 'Unknown' ? null : _blood,
        'emergency_contact_name': _emergencyName.text.trim().isEmpty
            ? null
            : _emergencyName.text.trim(),
        'emergency_contact_phone': _emergencyPhone.text.trim().isEmpty
            ? null
            : _emergencyPhone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'state': _state.text.trim().isEmpty ? null : _state.text.trim(),
        'pincode': _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
        'allergies': allergies.isEmpty ? null : allergies,
      };

      await ref.read(patientRepositoryProvider).registerPatient(payload);
      await ref.read(authNotifierProvider.notifier).refreshPatientRegistration();
      if (!mounted) return;
      AppSnackBar.show(context, 'Profile saved');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us about yourself',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'First name *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Last name *'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date of birth'),
                subtitle: Text(
                  _dateOfBirth == null
                      ? 'Tap to choose (optional)'
                      : DateFormat.yMMMd().format(_dateOfBirth!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v ?? 'Not Specified'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _blood,
                decoration: const InputDecoration(labelText: 'Blood group'),
                items: _bloodGroups
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _blood = v ?? 'Unknown'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _state,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pincode,
                decoration: const InputDecoration(labelText: 'Pincode'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emergencyName,
                decoration: const InputDecoration(
                  labelText: 'Emergency contact name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emergencyPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency contact phone',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Allergies',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: () => setState(() => _allergies.add(_AllergyRow())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              ..._allergies.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextField(
                          controller: row.name,
                          decoration: const InputDecoration(
                            labelText: 'Allergen',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: row.severity,
                          items: const [
                            DropdownMenuItem(
                                value: 'mild', child: Text('mild')),
                            DropdownMenuItem(
                                value: 'moderate', child: Text('moderate')),
                            DropdownMenuItem(
                                value: 'severe', child: Text('severe')),
                            DropdownMenuItem(
                                value: 'unknown', child: Text('unknown')),
                          ],
                          onChanged: (v) =>
                              setState(() => row.severity = v ?? 'unknown'),
                        ),
                        TextField(
                          controller: row.reaction,
                          decoration: const InputDecoration(
                            labelText: 'Reaction (optional)',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _allergies.removeAt(i)),
                            child: const Text('Remove'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Save and continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllergyRow {
  _AllergyRow()
      : name = TextEditingController(),
        reaction = TextEditingController(),
        severity = 'unknown';

  final TextEditingController name;
  final TextEditingController reaction;
  String severity;
}
