import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/patient_theme.dart';
import '../../../../core/theme/patient_tokens.dart';

/// Featured daily tip with a light frosted surface.
class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key, required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.patientTokens;
    final r = tokens.cardRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PatientTheme.primary.withValues(alpha: 0.12),
                    const Color(0xFFE0F2FE).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                color: Colors.white.withValues(alpha: 0.35),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PatientTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: PatientTheme.primaryDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily tip',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tip,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
