import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Shared radii and hero gradients for the patient app — use via [ThemeExtension].
@immutable
class PatientTokens extends ThemeExtension<PatientTokens> {
  const PatientTokens({
    required this.cardRadius,
    required this.panelRadius,
    required this.chipRadius,
    required this.navPillRadius,
    required this.heroGradient,
    required this.heroGradientSoft,
    required this.surfaceElevated,
    required this.navBarShadow,
  });

  final double cardRadius;
  final double panelRadius;
  final double chipRadius;
  final double navPillRadius;
  final LinearGradient heroGradient;
  final LinearGradient heroGradientSoft;
  final Color surfaceElevated;
  final List<BoxShadow> navBarShadow;

  static const PatientTokens light = PatientTokens(
    cardRadius: 20,
    panelRadius: 24,
    chipRadius: 10,
    navPillRadius: 14,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEFF6FF),
        Color(0xFFF0FDF4),
        Color(0xFFF8FAFC),
      ],
      stops: [0.0, 0.45, 1.0],
    ),
    heroGradientSoft: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x14FFFFFF),
        Color(0xFFF8FAFC),
      ],
    ),
    surfaceElevated: Color(0xFFFFFFFF),
    navBarShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 24,
        offset: Offset(0, -4),
      ),
    ],
  );

  @override
  PatientTokens copyWith({
    double? cardRadius,
    double? panelRadius,
    double? chipRadius,
    double? navPillRadius,
    LinearGradient? heroGradient,
    LinearGradient? heroGradientSoft,
    Color? surfaceElevated,
    List<BoxShadow>? navBarShadow,
  }) {
    return PatientTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      panelRadius: panelRadius ?? this.panelRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      navPillRadius: navPillRadius ?? this.navPillRadius,
      heroGradient: heroGradient ?? this.heroGradient,
      heroGradientSoft: heroGradientSoft ?? this.heroGradientSoft,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      navBarShadow: navBarShadow ?? this.navBarShadow,
    );
  }

  @override
  PatientTokens lerp(ThemeExtension<PatientTokens>? other, double t) {
    if (other is! PatientTokens) return this;
    return PatientTokens(
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      chipRadius: lerpDouble(chipRadius, other.chipRadius, t)!,
      navPillRadius: lerpDouble(navPillRadius, other.navPillRadius, t)!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      heroGradientSoft:
          LinearGradient.lerp(heroGradientSoft, other.heroGradientSoft, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      navBarShadow: t < 0.5 ? navBarShadow : other.navBarShadow,
    );
  }
}

extension PatientTokensContext on BuildContext {
  PatientTokens get patientTokens =>
      Theme.of(this).extension<PatientTokens>() ?? PatientTokens.light;
}
