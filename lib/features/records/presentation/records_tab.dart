import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/patient_theme.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/patient_elevated_card.dart';
import '../../../core/ui/patient_list_loading.dart';
import '../data/records_repository.dart';
import '../providers/records_providers.dart';

class RecordsTab extends ConsumerWidget {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicalRecordsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PatientTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Health records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Upload file',
            onPressed: () => _upload(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (files) {
          if (files.isEmpty) {
            return PatientEmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No files yet',
              subtitle: 'Upload lab reports, prescriptions, or imaging.',
              action: FilledButton.icon(
                onPressed: () => _upload(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Upload'),
              ),
            );
          }
          return RefreshIndicator(
            color: PatientTheme.primary,
            onRefresh: () async {
              ref.invalidate(medicalRecordsListProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: files.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final f = files[i];
                return PatientElevatedCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              PatientTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: PatientTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.fileName,
                              style: theme.textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${f.fileType} · ${DateFormat.yMMMd().format(f.createdAt.toLocal())}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: PatientTheme.textSecondary,
                        ),
                        onSelected: (v) async {
                          if (v == 'dl') {
                            final url = await ref
                                .read(recordsRepositoryProvider)
                                .getDownloadUrl(f.id);
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } else if (v == 'del' && context.mounted) {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Delete file?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              try {
                                await ref
                                    .read(recordsRepositoryProvider)
                                    .deleteFile(f.id);
                                ref.invalidate(medicalRecordsListProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'dl',
                            child: Text('Open / download'),
                          ),
                          PopupMenuItem(
                            value: 'del',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const PatientListLoading(),
        error: (e, _) => PatientEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load records',
          subtitle: '$e',
        ),
      ),
    );
  }

  static Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.single;
    final bytes = f.bytes;
    if (bytes == null) {
      if (f.path != null) {
        final file = File(f.path!);
        final raw = await file.readAsBytes();
        if (!context.mounted) return;
        await _doUpload(context, ref, raw, f.name);
      }
      return;
    }
    if (!context.mounted) return;
    await _doUpload(context, ref, bytes, f.name);
  }

  static Future<void> _doUpload(
    BuildContext context,
    WidgetRef ref,
    List<int> raw,
    String originalName,
  ) async {
    final logical = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final ext = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final typeCat = ext.replaceFirst('.', '').toLowerCase();
    final mime = lookupMimeType(originalName) ?? 'application/octet-stream';

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: PatientTheme.primary),
      ),
    );
    try {
      await ref.read(recordsRepositoryProvider).uploadFile(
            logicalFileName: logical,
            fileTypeCategory: typeCat.isEmpty ? 'file' : typeCat,
            rawBytes: raw,
            originalFileName: originalName,
            mimeType: mime,
          );
      ref.invalidate(medicalRecordsListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
