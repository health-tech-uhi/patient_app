import 'package:flutter/material.dart';

import 'shimmer_placeholder.dart';

class PatientListLoading extends StatelessWidget {
  const PatientListLoading({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ShimmerPlaceholder(
        width: double.infinity,
        height: 76,
        borderRadius: 20,
      ),
    );
  }
}
