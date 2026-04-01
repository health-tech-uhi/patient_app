import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/patient_elevated_card.dart';
import '../../../core/ui/patient_list_loading.dart';
import '../providers/doctors_providers.dart';

class DoctorsTab extends ConsumerWidget {
  const DoctorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(doctorsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PatientTheme.scaffoldBackground,
      appBar: AppBar(title: const Text('Find doctors')),
      body: async.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return PatientEmptyState(
              icon: Icons.medical_services_rounded,
              title: 'No doctors available',
              subtitle: 'Check back later — care providers will appear here.',
            );
          }
          return RefreshIndicator(
            color: PatientTheme.primary,
            onRefresh: () async {
              ref.invalidate(doctorsListProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: doctors.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = doctors[i];
                final fee = d.consultationFeeInr != null
                    ? ' · ₹${d.consultationFeeInr!.toStringAsFixed(0)}'
                    : '';
                return PatientElevatedCard(
                  onTap: () => context.push('/doctors/${d.id}/book'),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            PatientTheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person_rounded,
                          color: PatientTheme.primaryDark,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.fullName,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${d.specialization}$fee',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: PatientTheme.textSecondary,
                      ),
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
          title: 'Something went wrong',
          subtitle: '$e',
        ),
      ),
    );
  }
}
