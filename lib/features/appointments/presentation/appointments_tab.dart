import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/patient_elevated_card.dart';
import '../../../core/ui/patient_list_loading.dart';
import '../../../core/ui/status_chip.dart';
import '../domain/appointment.dart';
import '../providers/appointments_providers.dart';

class AppointmentsTab extends ConsumerWidget {
  const AppointmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptsAsync = ref.watch(appointmentsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PatientTheme.scaffoldBackground,
      appBar: AppBar(title: const Text('Appointments')),
      body: apptsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return PatientEmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No appointments yet',
              subtitle: 'Book a visit from the Doctors tab.',
            );
          }

          final sorted = [...appointments]..sort(
              (a, b) =>
                  b.requestedDatetime.compareTo(a.requestedDatetime),
            );

          return RefreshIndicator(
            color: PatientTheme.primary,
            onRefresh: () async {
              ref.invalidate(appointmentsListProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = sorted[i];
                final rejection = a.status == AppointmentStatus.rejected &&
                        a.rejectionReason != null &&
                        a.rejectionReason!.trim().isNotEmpty
                    ? a.rejectionReason!.trim()
                    : null;
                return PatientElevatedCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.displayDoctorName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (a.clinicName != null &&
                                    a.clinicName!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'at ${a.clinicName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: PatientTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          AppointmentStatusChip(
                            status: a.status,
                            label: a.statusLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat.yMMMd()
                            .add_jm()
                            .format(a.requestedDatetime.toLocal()),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: PatientTheme.textPrimary,
                        ),
                      ),
                      if (a.chiefComplaint != null &&
                          a.chiefComplaint!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          a.chiefComplaint!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (rejection != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          rejection,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: PatientTheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const PatientListLoading(),
        error: (e, _) => PatientEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load appointments',
          subtitle: '$e',
        ),
      ),
    );
  }
}
