import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/patient_profile.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(dioClientProvider));
});

class PatientProfileNotFoundException implements Exception {
  @override
  String toString() => 'Patient profile not found';
}

class PatientRepository {
  PatientRepository(this._dio);

  final Dio _dio;

  Future<PatientProfile> getProfile() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/api/patients/profile');
      final data = r.data;
      if (data == null) throw PatientProfileNotFoundException();
      return PatientProfile.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw PatientProfileNotFoundException();
      }
      rethrow;
    }
  }

  /// POST /api/patients/register — onboarding form payload (snake_case).
  ///
  /// Rust expects `date_of_birth` as `YYYY-MM-DD` or omitted; invalid strings
  /// or `""` cause JSON deserialization to fail with **422**.
  Future<void> registerPatient(Map<String, dynamic> payload) async {
    await _dio.post(
      '/api/patients/register',
      data: _sanitizeRegisterPayload(payload),
    );
  }

  /// Matches backend [RegisterPatientRequest]: optional fields must not send
  /// empty strings for [date_of_birth] (serde `NaiveDate` rejects them).
  Map<String, dynamic> _sanitizeRegisterPayload(Map<String, dynamic> raw) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    void putStr(Map<String, dynamic> out, String key, dynamic v) {
      final s = str(v);
      if (s != null) out[key] = s;
    }

    final out = <String, dynamic>{};

    putStr(out, 'first_name', raw['first_name']);
    putStr(out, 'last_name', raw['last_name']);

    final dob = str(raw['date_of_birth']);
    if (dob != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
      out['date_of_birth'] = dob;
    }

    final g = str(raw['gender']);
    if (g != null && g != 'Not Specified') out['gender'] = g;

    final bg = str(raw['blood_group']);
    if (bg != null && bg != 'Unknown') out['blood_group'] = bg;

    putStr(out, 'emergency_contact_name', raw['emergency_contact_name']);
    putStr(out, 'emergency_contact_phone', raw['emergency_contact_phone']);
    putStr(out, 'address', raw['address']);
    putStr(out, 'city', raw['city']);
    putStr(out, 'state', raw['state']);
    putStr(out, 'pincode', raw['pincode']);

    final rawAllergies = raw['allergies'];
    if (rawAllergies is List) {
      final list = <Map<String, dynamic>>[];
      for (final e in rawAllergies) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final name = str(m['allergen_name']);
        if (name == null) continue;
        final row = <String, dynamic>{
          'allergen_name': name,
        };
        final sid = m['substance_id'];
        if (sid != null) row['substance_id'] = sid;
        final sev = str(m['severity']);
        if (sev != null) row['severity'] = sev;
        final react = str(m['reaction']);
        if (react != null) row['reaction'] = react;
        list.add(row);
      }
      if (list.isNotEmpty) out['allergies'] = list;
    }

    return out;
  }

  Future<PatientProfile> updateProfile(Map<String, dynamic> payload) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/api/patients/profile',
      data: _sanitizeUpdatePayload(payload),
    );
    final data = r.data;
    if (data == null) {
      return getProfile();
    }
    return PatientProfile.fromJson(data);
  }

  Map<String, dynamic> _sanitizeUpdatePayload(Map<String, dynamic> raw) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    void putStr(Map<String, dynamic> out, String key, dynamic v) {
      final s = str(v);
      if (s != null) out[key] = s;
    }

    final out = <String, dynamic>{};

    putStr(out, 'first_name', raw['first_name']);
    putStr(out, 'last_name', raw['last_name']);

    final dob = str(raw['date_of_birth']);
    if (dob != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
      out['date_of_birth'] = dob;
    }

    final g = str(raw['gender']);
    if (g != null && g != 'Not Specified') out['gender'] = g;

    final bg = str(raw['blood_group']);
    if (bg != null && bg != 'Unknown') out['blood_group'] = bg;

    putStr(out, 'emergency_contact_name', raw['emergency_contact_name']);
    putStr(out, 'emergency_contact_phone', raw['emergency_contact_phone']);
    putStr(out, 'address', raw['address']);
    putStr(out, 'city', raw['city']);
    putStr(out, 'state', raw['state']);
    putStr(out, 'pincode', raw['pincode']);

    final rawAllergies = raw['allergies'];
    if (rawAllergies is List) {
      final list = <Map<String, dynamic>>[];
      for (final e in rawAllergies) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final name = str(m['allergen_name']);
        if (name == null) continue;
        final row = <String, dynamic>{'allergen_name': name};
        final sid = m['substance_id'];
        if (sid != null) row['substance_id'] = sid;
        final sev = str(m['severity']);
        if (sev != null) row['severity'] = sev;
        final react = str(m['reaction']);
        if (react != null) row['reaction'] = react;
        list.add(row);
      }
      out['allergies'] = list;
    }

    return out;
  }

  Future<Map<String, dynamic>> initAbhaEnrollment(String aadhaar) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/abdm/v3/enrol/init',
      data: {'aadhaar': aadhaar},
    );
    return r.data ?? {};
  }

  Future<Map<String, dynamic>> verifyAbhaOtp({
    required String otp,
    required String txnId,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/abdm/v3/enrol/verify',
      data: {'otp': otp, 'txn_id': txnId},
    );
    return r.data ?? {};
  }

  Future<void> linkAbhaProfile(Map<String, dynamic> linkRequest) async {
    await _dio.put('/api/patients/profile/abha', data: linkRequest);
  }
}
