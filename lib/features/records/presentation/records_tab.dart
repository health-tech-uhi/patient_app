import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/records_repository.dart';
import '../providers/records_providers.dart';

class RecordsTab extends ConsumerWidget {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicalRecordsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _upload(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No files yet.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _upload(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Upload'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(medicalRecordsListProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final f = files[i];
                return Card(
                  child: ListTile(
                    title: Text(f.fileName),
                    subtitle: Text(
                      '${f.fileType} · ${DateFormat.yMMMd().format(f.createdAt.toLocal())}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'dl') {
                          final url = await ref
                              .read(recordsRepositoryProvider)
                              .getDownloadUrl(f.id);
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                        PopupMenuItem(value: 'dl', child: Text('Open / download')),
                        PopupMenuItem(value: 'del', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
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
      builder: (c) => const Center(child: CircularProgressIndicator()),
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
