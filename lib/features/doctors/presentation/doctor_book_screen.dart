import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../appointments/data/appointments_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../data/doctors_repository.dart';

class DoctorBookScreen extends ConsumerStatefulWidget {
  const DoctorBookScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<DoctorBookScreen> createState() => _DoctorBookScreenState();
}

class _DoctorBookScreenState extends ConsumerState<DoctorBookScreen> {
  DateTime? _date;
  TimeOfDay? _time;
  AppointmentMode _mode = AppointmentMode.inPerson;
  final _complaint = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _complaint.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    if (_date == null || _time == null || _complaint.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill date, time, and complaint')),
      );
      return;
    }
    final dt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    setState(() => _loading = true);
    try {
      await ref.read(appointmentsRepositoryProvider).bookAppointment(
            doctorId: widget.doctorId,
            requestedDatetime: dt,
            mode: _mode,
            chiefComplaint: _complaint.text.trim(),
          );
      if (!mounted) return;
      context.go('/appointments');
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
    return FutureBuilder(
      future: ref.read(doctorsRepositoryProvider).getDoctorById(widget.doctorId),
      builder: (context, snap) {
        final doctor = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(doctor?.fullName ?? 'Book visit')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (doctor != null)
                  Text(
                    doctor.specialization,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _date == null
                        ? 'Pick date'
                        : DateFormat.yMMMd().format(_date!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                ListTile(
                  title: Text(
                    _time == null ? 'Pick time' : _time!.format(context),
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickTime,
                ),
                DropdownButtonFormField<AppointmentMode>(
                  initialValue: _mode,
                  decoration: const InputDecoration(labelText: 'Mode'),
                  items: const [
                    DropdownMenuItem(
                      value: AppointmentMode.inPerson,
                      child: Text('In person'),
                    ),
                    DropdownMenuItem(
                      value: AppointmentMode.teleconsultation,
                      child: Text('Teleconsultation'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _mode = v ?? AppointmentMode.inPerson),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _complaint,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Chief complaint *',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Request appointment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
