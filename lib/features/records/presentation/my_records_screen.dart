import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/patient_elevated_card.dart';
import '../../../core/ui/patient_list_loading.dart';
import '../providers/records_providers.dart';

/// List of consultation summaries: date, doctor, chief complaint — tap for detail.
class MyRecordsScreen extends ConsumerWidget {
  const MyRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(consultationSummariesListProvider);
    final theme = Theme.of(context);

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return PatientEmptyState(
            icon: Icons.medical_information_outlined,
            title: 'No consultation summaries yet',
            subtitle:
                'When your doctor approves a visit summary, it will appear here.',
          );
        }
        return RefreshIndicator(
          color: PatientTheme.primary,
          onRefresh: () async {
            ref.invalidate(consultationSummariesListProvider);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = items[i];
              final dateStr = DateFormat.yMMMd().format(s.consultationDate.toLocal());
              final doctor = s.doctorName ?? 'Your doctor';
              final complaint = s.chiefComplaint?.trim();
              final subtitle = complaint != null && complaint.isNotEmpty
                  ? complaint
                  : 'Consultation summary';

              return PatientElevatedCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: InkWell(
                  onTap: () => context.push('/records/summary/${s.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PatientTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: PatientTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor,
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: PatientTheme.textSecondary,
                              ),
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
                ),
              );
            },
          ),
        );
      },
      loading: () => const PatientListLoading(),
      error: (e, _) => PatientEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load summaries',
        subtitle: '$e',
      ),
    );
  }
}
