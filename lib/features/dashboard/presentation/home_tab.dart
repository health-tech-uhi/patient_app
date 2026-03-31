import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../appointments/domain/appointment.dart';
import '../../appointments/providers/appointments_providers.dart';
import '../../auth/providers/auth_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  static final _tips = [
    'Staying hydrated is key to focused energy. Aim for 8 glasses today!',
    'A 10-minute walk can boost your mood instantly.',
    'Prioritize 7–8 hours of sleep for better recovery.',
    'Include more fiber in your diet with fruits and whole grains.',
    'Take a moment for deep breathing to reduce stress.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final tip = _tips[DateTime.now().day % _tips.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(appointmentsListProvider);
          ref.invalidate(patientProfileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hello, ${auth.user?['username'] ?? 'there'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (!auth.isRegisteredAsPatient)
              Card(
                color: Colors.orange.shade50,
                child: const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Complete your health profile'),
                  subtitle: Text(
                    'Finish onboarding to book visits and upload records.',
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: const Text('Daily tip'),
                  subtitle: Text(tip),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Next appointment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            appointmentsAsync.when(
              data: (list) {
                final now = DateTime.now();
                final upcoming = list
                    .where(
                      (a) =>
                          a.requestedDatetime.isAfter(now) &&
                          (a.status == AppointmentStatus.requested ||
                              a.status == AppointmentStatus.accepted),
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        a.requestedDatetime.compareTo(b.requestedDatetime),
                  );
                if (upcoming.isEmpty) {
                  return const Text('No upcoming appointments.');
                }
                final a = upcoming.first;
                return Card(
                  child: ListTile(
                    title: Text(
                      DateFormat.yMMMd()
                          .add_jm()
                          .format(a.requestedDatetime.toLocal()),
                    ),
                    subtitle: Text(a.statusLabel),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load appointments: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
