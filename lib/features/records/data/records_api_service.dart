import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paginated_result.dart';
import '../../../core/network/dio_client.dart';
import '../domain/consultation_summary.dart';

final recordsApiServiceProvider = Provider<RecordsApiService>((ref) {
  return RecordsApiService(ref.watch(dioClientProvider));
});

/// Patient self-access endpoints under `/api/records/me`.
class RecordsApiService {
  RecordsApiService(this._dio);

  final Dio _dio;

  /// Paginated consultation summaries (date, doctor, chief complaint).
  Future<PaginatedResult<ConsultationSummaryListItem>> getMySummaries({
    int page = 1,
    int perPage = 20,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/api/records/me/summaries',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = r.data;
    if (data == null) {
      return const PaginatedResult(items: []);
    }
    return PaginatedResult.fromJson(
      data,
      ConsultationSummaryListItem.fromJson,
    );
  }

  /// Full SOAP-style consultation summary for read-only detail + PDF link.
  Future<ConsultationSummaryDetail> getSummaryDetail(String summaryId) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/api/records/me/summary/$summaryId',
    );
    final data = r.data;
    if (data == null) {
      throw StateError('Empty response for consultation summary');
    }
    return ConsultationSummaryDetail.fromJson(data);
  }
}
