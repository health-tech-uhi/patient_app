import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/patient_theme.dart';
import '../../../../core/theme/patient_tokens.dart';
import '../../../../core/ui/status_chip.dart';
import '../../domain/appointment.dart';

class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard({
    super.key,
    required this.appointment,
    required this.onOpenBookings,
  });

  final Appointment appointment;
  final VoidCallback onOpenBookings;

  @override
  Widget build(BuildContext context) {
    final tokens = context.patientTokens;
    final theme = Theme.of(context);
    final formatted = DateFormat.yMMMd()
        .add_jm()
        .format(appointment.requestedDatetime.toLocal());

    return Semantics(
      button: true,
      label: 'Next appointment $formatted, ${appointment.statusLabel}. Open bookings.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenBookings,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: PatientTheme.primary.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appointment.displayDoctorName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          AppointmentStatusChip(
                            status: appointment.status,
                            label: appointment.statusLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            size: 16,
                            color: PatientTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatted,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: PatientTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: PatientTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to view all bookings',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: PatientTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
