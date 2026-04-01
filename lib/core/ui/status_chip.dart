import 'package:flutter/material.dart';

import '../../features/appointments/domain/appointment.dart';

/// Maps appointment status to a compact, accessible chip.
class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({super.key, required this.status, this.label});

  final AppointmentStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = _colors(theme);
    return Semantics(
      label: label ?? status.name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label ?? _defaultLabel(status),
          style: theme.textTheme.labelLarge?.copyWith(
            color: fg,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  static String _defaultLabel(AppointmentStatus s) {
    return switch (s) {
      AppointmentStatus.requested => 'Requested',
      AppointmentStatus.accepted => 'Accepted',
      AppointmentStatus.rejected => 'Declined',
      AppointmentStatus.completed => 'Completed',
      AppointmentStatus.cancelled => 'Cancelled',
    };
  }

  (Color bg, Color fg) _colors(ThemeData theme) {
    final success = const Color(0xFF16A34A);
    final error = theme.colorScheme.error;
    final warn = const Color(0xFFD97706);
    return switch (status) {
      AppointmentStatus.accepted => (success.withValues(alpha: 0.15), success),
      AppointmentStatus.requested => (warn.withValues(alpha: 0.18), warn),
      AppointmentStatus.rejected => (error.withValues(alpha: 0.12), error),
      AppointmentStatus.completed =>
        (theme.colorScheme.primary.withValues(alpha: 0.12), theme.colorScheme.primary),
      AppointmentStatus.cancelled =>
        (theme.colorScheme.outline.withValues(alpha: 0.2), theme.colorScheme.onSurfaceVariant),
    };
  }
}
