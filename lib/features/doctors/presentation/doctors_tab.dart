import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/doctors_providers.dart';

class DoctorsTab extends ConsumerWidget {
  const DoctorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(doctorsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find doctors')),
      body: async.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return const Center(child: Text('No doctors available.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(doctorsListProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: doctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = doctors[i];
                return Card(
                  child: ListTile(
                    title: Text(d.fullName),
                    subtitle: Text(
                      '${d.specialization}${d.consultationFeeInr != null ? ' · ₹${d.consultationFeeInr!.toStringAsFixed(0)}' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/doctors/${d.id}/book'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
