import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/theme/patient_tokens.dart';
import '../../../core/ui/section_header.dart';
import '../../../core/ui/shimmer_placeholder.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/providers/appointments_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../appointments/presentation/widgets/next_appointment_card.dart';
import '../../appointments/presentation/widgets/daily_tip_card.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab>
    with SingleTickerProviderStateMixin {
  static final _tips = [
    'Staying hydrated is key to focused energy. Aim for 8 glasses today!',
    'A 10-minute walk can boost your mood instantly.',
    'Prioritize 7–8 hours of sleep for better recovery.',
    'Include more fiber in your diet with fruits and whole grains.',
    'Take a moment for deep breathing to reduce stress.',
  ];

  late final AnimationController _stagger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _stagger.forward();
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _fadeSlide(int index, Widget child) {
    final start = index * 0.11;
    final anim = CurvedAnimation(
      parent: _stagger,
      curve: Interval(
        start.clamp(0.0, 0.82),
        (start + 0.58).clamp(0.2, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - anim.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final appointmentsAsync = ref.watch(appointmentsListProvider);
    final tip = _tips[DateTime.now().day % _tips.length];
    final theme = Theme.of(context);
    final tokens = context.patientTokens;
    final topPad = MediaQuery.paddingOf(context).top;
    final name = auth.user?['username'] ?? 'there';

    return Scaffold(
      backgroundColor: PatientTheme.scaffoldBackground,
      body: RefreshIndicator(
        color: PatientTheme.primary,
        onRefresh: () async {
          ref.invalidate(appointmentsListProvider);
          ref.invalidate(patientProfileProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: tokens.heroGradient),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(22, topPad + 8, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: PatientTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hello, $name',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Here is what matters for your care today.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!auth.isRegisteredAsPatient)
                    _fadeSlide(
                      0,
                      _OnboardingBanner(),
                    )
                  else
                    _fadeSlide(
                      0,
                      DailyTipCard(tip: tip),
                    ),
                  const SizedBox(height: 22),
                  _fadeSlide(
                    1,
                    PatientSectionHeader(
                      title: 'Next appointment',
                      subtitle: 'Your soonest scheduled visit',
                    ),
                  ),
                  _fadeSlide(
                    2,
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
                            (a, b) => a.requestedDatetime
                                .compareTo(b.requestedDatetime),
                          );
                        if (upcoming.isEmpty) {
                          return _EmptyNextAppointment();
                        }
                        final a = upcoming.first;
                        return NextAppointmentCard(
                          appointment: a,
                          onOpenBookings: () => context.go('/appointments'),
                        );
                      },
                      loading: () => const _AppointmentLoadingCard(),
                      error: (e, _) => _AppointmentError(message: '$e'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _fadeSlide(
                    3,
                    Semantics(
                      button: true,
                      label: 'Open bookings',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.go('/appointments'),
                          borderRadius:
                              BorderRadius.circular(tokens.cardRadius),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  'View all bookings',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: PatientTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: PatientTheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(
          context.patientTokens.cardRadius,
        ),
        border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your health profile',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Finish onboarding to book visits and upload records.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNextAppointment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.patientTokens.cardRadius;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.event_available_rounded,
            color: PatientTheme.primary.withValues(alpha: 0.7),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming visits',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Book a doctor from the Doctors tab when you are ready.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AppointmentLoadingCard extends StatelessWidget {
  const _AppointmentLoadingCard();

  @override
  Widget build(BuildContext context) {
    final r = context.patientTokens.cardRadius;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const AppointmentCardSkeleton(),
    );
  }
}

class _AppointmentError extends StatelessWidget {
  const _AppointmentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final r = context.patientTokens.cardRadius;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientTheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: PatientTheme.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Could not load appointments.\n$message',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PatientTheme.error,
            ),
      ),
    );
  }
}
