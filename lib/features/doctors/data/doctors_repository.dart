import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paginated_result.dart';
import '../../../core/network/dio_client.dart';
import '../domain/doctor.dart';

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  return DoctorsRepository(ref.watch(dioClientProvider));
});

class DoctorsRepository {
  DoctorsRepository(this._dio);

  final Dio _dio;

  /// Loads every verified doctor. The API paginates (default 10/page, max 100/page);
  /// without paging, older doctors never appear on the first page.
  Future<List<Doctor>> listDoctors() async {
    const perPage = 100;
    final all = <Doctor>[];
    var page = 1;

    while (true) {
      final r = await _dio.get<dynamic>(
        '/api/doctors',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = r.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Doctor.fromJson)
            .toList();
      }
      if (data is! Map<String, dynamic>) {
        return all;
      }
      if (data['items'] is! List) {
        return all;
      }
      final batch = PaginatedResult.fromJson(data, Doctor.fromJson);
      all.addAll(batch.items);
      final meta = batch.metadata;
      final totalPages = meta?.totalPages ?? 1;
      if (page >= totalPages || batch.items.isEmpty) {
        break;
      }
      page++;
    }
    return all;
  }

  Future<Doctor?> getDoctorById(String id) async {
    final list = await listDoctors();
    try {
      return list.firstWhere(
        (d) => d.id == id || d.profileId == id || d.userId == id,
      );
    } catch (_) {
      return null;
    }
  }
}
