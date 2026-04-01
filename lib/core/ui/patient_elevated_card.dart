import 'package:flutter/material.dart';

import '../theme/patient_theme.dart';
import '../theme/patient_tokens.dart';

/// Tonal card with soft shadow — optional tap ripple.
class PatientElevatedCard extends StatelessWidget {
  const PatientElevatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final r = context.patientTokens.cardRadius;
    final decoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: PatientTheme.primary.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
    final inner = Padding(padding: padding, child: child);
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: Ink(decoration: decoration, child: inner),
        ),
      );
    }
    return DecoratedBox(decoration: decoration, child: inner);
  }
}
