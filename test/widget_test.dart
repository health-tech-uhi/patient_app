import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/core/theme/patient_theme.dart';
import 'package:patient_app/core/theme/patient_tokens.dart';

void main() {
  testWidgets('PatientTheme exposes PatientTokens extension', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PatientTheme.light(),
        home: Builder(
          builder: (context) {
            final ext = Theme.of(context).extension<PatientTokens>();
            expect(ext, isNotNull);
            expect(ext!.cardRadius, 20);
            expect(Theme.of(context).textTheme.headlineMedium, isNotNull);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
