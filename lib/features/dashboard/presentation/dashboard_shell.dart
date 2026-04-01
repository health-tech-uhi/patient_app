import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/theme/patient_theme.dart';
import '../../../core/theme/patient_tokens.dart';

/// Bottom tabs: index 0 Home, 1 Doctors, 2 Bookings, 3 Records, 4 Profile.
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _accent = PatientTheme.primary;
  static const _muted = Color(0xFF8E8E93);

  static const _iconsOutlined = [
    Icons.home_rounded,
    Icons.medical_services_rounded,
    Icons.calendar_month_rounded,
    Icons.folder_rounded,
    Icons.person_outline_rounded,
  ];

  static const _iconsFilled = [
    Icons.home_rounded,
    Icons.medical_services_rounded,
    Icons.calendar_month_rounded,
    Icons.folder_rounded,
    Icons.person_rounded,
  ];

  static const _labels = [
    'Home',
    'Doctors',
    'Bookings',
    'Records',
    'Profile',
  ];

  void _goBranch(int index) {
    hapticSelectionOnApple();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.patientTokens;
    return Scaffold(
      backgroundColor: PatientTheme.scaffoldBackground,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: tokens.navBarShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: List.generate(5, (i) {
                return Expanded(
                  child: _NavItem(
                    selected: navigationShell.currentIndex == i,
                    label: _labels[i],
                    icon: navigationShell.currentIndex == i
                        ? _iconsFilled[i]
                        : _iconsOutlined[i],
                    accent: _accent,
                    muted: _muted,
                    pillRadius: tokens.navPillRadius,
                    onTap: () => _goBranch(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.accent,
    required this.muted,
    required this.pillRadius,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color accent;
  final Color muted;
  final double pillRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(pillRadius + 4),
          splashColor: accent.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(pillRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    color: selected ? accent : muted,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? accent : muted,
                        letterSpacing: -0.2,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
