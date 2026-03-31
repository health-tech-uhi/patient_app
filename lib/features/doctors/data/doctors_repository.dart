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

  Future<List<Doctor>> listDoctors() async {
    final r = await _dio.get<dynamic>('/api/doctors');
    final data = r.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Doctor.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic> && data['items'] is List) {
      return PaginatedResult.fromJson(data, Doctor.fromJson).items;
    }
    return [];
  }

  Future<Doctor?> getDoctorById(String id) async {
    final list = await listDoctors();
    try {
      return list.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
