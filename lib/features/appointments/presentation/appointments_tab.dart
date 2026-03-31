import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../doctors/providers/doctors_providers.dart';
import '../providers/appointments_providers.dart';

class AppointmentsTab extends ConsumerWidget {
  const AppointmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptsAsync = ref.watch(appointmentsListProvider);
    final doctorsAsync = ref.watch(doctorsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: apptsAsync.when(
        data: (appointments) {
          return doctorsAsync.when(
            data: (doctors) {
              if (appointments.isEmpty) {
                return const Center(child: Text('No appointments yet.'));
              }
              String nameFor(String doctorId) {
                try {
                  return doctors.firstWhere((d) => d.id == doctorId).fullName;
                } catch (_) {
                  return doctorId;
                }
              }

              final sorted = [...appointments]..sort(
                  (a, b) =>
                      b.requestedDatetime.compareTo(a.requestedDatetime),
                );

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(appointmentsListProvider);
                  ref.invalidate(doctorsListProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = sorted[i];
                    return Card(
                      child: ListTile(
                        title: Text(nameFor(a.doctorId)),
                        subtitle: Text(
                          '${DateFormat.yMMMd().add_jm().format(a.requestedDatetime.toLocal())}\n'
                          '${a.statusLabel}${a.chiefComplaint != null ? ' · ${a.chiefComplaint}' : ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
