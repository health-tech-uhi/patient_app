import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../core/data/paginated_result.dart';
import '../../../core/network/dio_client.dart';
import '../../patient/data/patient_repository.dart';
import '../domain/medical_record_file.dart';

final recordsRepositoryProvider = Provider<RecordsRepository>((ref) {
  return RecordsRepository(
    ref.watch(dioClientProvider),
    ref.watch(patientRepositoryProvider),
  );
});

/// Upload pipeline matches patient-web-app [records/+page.server.ts]: gzip + PUT + metadata.
class RecordsRepository {
  RecordsRepository(this._dio, this._patientRepository);

  final Dio _dio;
  final PatientRepository _patientRepository;

  Future<List<MedicalRecordFile>> listFiles(String patientId) async {
    final r = await _dio.get<dynamic>(
      '/api/records/files/patient/$patientId',
    );
    final data = r.data;
    if (data is Map<String, dynamic> && data['items'] is List) {
      return PaginatedResult.fromJson(data, MedicalRecordFile.fromJson).items;
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MedicalRecordFile.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> deleteFile(String fileId) async {
    await _dio.delete('/api/records/files/$fileId');
  }

  /// Presigned URL upload with gzip body (same as web).
  Future<void> uploadFile({
    required String logicalFileName,
    required String fileTypeCategory,
    required List<int> rawBytes,
    required String originalFileName,
    String? description,
    String? mimeType,
  }) async {
    final profile = await _patientRepository.getProfile();
    final patientId = profile.id;

    var fileName = logicalFileName;
    final ext = originalFileName.contains('.')
        ? originalFileName.substring(originalFileName.lastIndexOf('.'))
        : '';
    if (ext.isNotEmpty && !fileName.toLowerCase().endsWith(ext.toLowerCase())) {
      fileName = fileName + ext;
    }

    final resolvedMime = mimeType ??
        lookupMimeType(originalFileName) ??
        'application/octet-stream';

    final uploadInfo = await _dio.post<Map<String, dynamic>>(
      '/api/records/files/upload-url',
      data: {
        'patient_id': patientId,
        'file_name': fileName,
        'content_type': resolvedMime,
      },
    );

    final url = uploadInfo.data?['url'] as String?;
    final key = uploadInfo.data?['key'] as String?;
    if (url == null || key == null) {
      throw Exception('Upload URL response missing url/key');
    }

    final compressed = gzip.encode(rawBytes);

    final putDio = Dio();
    await putDio.put<void>(
      url,
      data: compressed,
      options: Options(
        headers: {
          'Content-Type': resolvedMime,
          'Content-Encoding': 'gzip',
        },
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );

    final objectUuid = key.split('/').length > 1 ? key.split('/')[1] : key;

    await _dio.post('/api/records/files', data: {
      'patient_id': patientId,
      'file_name': fileName,
      'file_type': fileTypeCategory,
      'file_size_bytes': compressed.length,
      'mime_type': resolvedMime,
      'garage_object_uuid': objectUuid,
      if (description != null) 'description': description,
    });
  }

  Future<String> getDownloadUrl(String fileId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/api/records/files/$fileId/download-url',
    );
    return r.data?['url'] as String? ?? '';
  }
}
