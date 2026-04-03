import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/paginated_result.dart';
import '../../../core/network/dio_client.dart';
import '../domain/appointment.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(dioClientProvider));
});

class AppointmentsRepository {
  AppointmentsRepository(this._dio);

  final Dio _dio;

  Future<List<Appointment>> listAppointments() async {
    final r = await _dio.get<dynamic>('/api/appointments');
    final data = r.data;
    if (data is Map<String, dynamic> && data['items'] is List) {
      return PaginatedResult.fromJson(data, Appointment.fromJson).items;
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Appointment.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> bookAppointment({
    required String doctorId,
    String? clinicId,
    required DateTime requestedDatetime,
    AppointmentMode mode = AppointmentMode.inPerson,
    required String chiefComplaint,
  }) async {
    await _dio.post('/api/appointments', data: {
      'doctor_id': doctorId,
      'clinic_id': ?clinicId,
      'requested_datetime': requestedDatetime.toUtc().toIso8601String(),
      'appointment_mode': mode == AppointmentMode.teleconsultation
          ? 'teleconsultation'
          : 'in_person',
      'chief_complaint': chiefComplaint,
    });
  }
}
