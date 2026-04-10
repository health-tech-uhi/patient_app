import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/patient_elevated_card.dart';
import '../../../core/ui/patient_list_loading.dart';
import '../domain/consultation_summary.dart';
import '../providers/records_providers.dart';

/// Read-only consultation summary with optional PDF download.
class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({super.key, required this.summaryId});

  final String summaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(consultationSummaryDetailProvider(summaryId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PatientTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Consultation summary'),
      ),
      body: async.when(
        data: (detail) => _DetailBody(detail: detail, theme: theme),
        loading: () => const PatientListLoading(),
        error: (e, _) => PatientEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load summary',
          subtitle: '$e',
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.theme,
  });

  final ConsultationSummaryDetail detail;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat.yMMMd().add_jm().format(detail.consultationDate.toLocal());
    final doctor = detail.doctorName ?? 'Your doctor';
    final pdfUrl = detail.pdfDownloadUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          doctor,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: PatientTheme.textSecondary,
          ),
        ),
        if (detail.approvedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Approved ${DateFormat.yMMMd().format(detail.approvedAt!.toLocal())}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: PatientTheme.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(pdfUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Download PDF'),
          ),
          const SizedBox(height: 20),
        ],
        _SectionCard(
          title: 'Chief complaint',
          body: detail.chiefComplaint,
          theme: theme,
        ),
        _SectionCard(
          title: 'Assessment',
          body: detail.assessment,
          theme: theme,
        ),
        _SectionCard(
          title: 'Plan',
          body: detail.plan,
          theme: theme,
        ),
        _JsonSectionCard(
          title: 'Diagnoses',
          value: detail.diagnoses,
          theme: theme,
        ),
        _JsonSectionCard(
          title: 'Medications',
          value: detail.medications,
          theme: theme,
        ),
        _JsonSectionCard(
          title: 'Vitals',
          value: detail.vitals,
          theme: theme,
        ),
        _JsonSectionCard(
          title: 'Follow-up',
          value: detail.followUp,
          theme: theme,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    required this.theme,
  });

  final String title;
  final String? body;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final text = body?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PatientElevatedCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonSectionCard extends StatelessWidget {
  const _JsonSectionCard({
    required this.title,
    required this.value,
    required this.theme,
  });

  final String title;
  final dynamic value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final lines = _stringifyClinicalJson(value);
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PatientElevatedCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SelectableText(
                  line,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flattens backend JSON arrays/objects into readable lines for patients.
List<String> _stringifyClinicalJson(dynamic value) {
  if (value == null) return [];
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? [] : [t];
  }
  if (value is List) {
    if (value.isEmpty) return [];
    final out = <String>[];
    for (final e in value) {
      if (e is Map) {
        out.add(_formatMapLine(Map<String, dynamic>.from(e)));
      } else {
        out.add(e.toString());
      }
    }
    return out;
  }
  if (value is Map) {
    final m = Map<String, dynamic>.from(value);
    if (m.isEmpty) return [];
    return [_formatMapLine(m)];
  }
  return [value.toString()];
}

String _formatMapLine(Map<String, dynamic> m) {
  const priority = ['name', 'code', 'dose', 'frequency', 'duration', 'substance', 'severity'];
  final parts = <String>[];
  for (final k in priority) {
    if (m[k] != null) {
      parts.add('$k: ${m[k]}');
    }
  }
  if (parts.isEmpty) {
    return m.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
  return parts.join(' · ');
}
