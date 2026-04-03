import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/access_context_restore.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  /// Full login response: always includes `token` + `refresh_token`.
  Future<void> _saveTokensFromResponse(Response response) async {
    final data = response.data;
    if (data is! Map) {
      throw Exception('Invalid auth response');
    }
    final access = data['token'];
    final refresh = data['refresh_token'] ?? data['refreshToken'];
    if (access is! String || refresh is! String) {
      throw Exception('Invalid tokens received from server');
    }
    await _storage.saveTokens(accessToken: access, refreshToken: refresh);
  }

  /// Binds the session to the **patient** access-control profile so the JWT includes
  /// `profile_id` and `role: PATIENT`. Required for appointments, clinical routes, etc.
  Future<void> switchToPatientProfileContext() async {
    await restorePatientJwtProfile(plainDio: _dio, storage: _storage);
  }

  /// Password or OTP login, then attach patient profile to the JWT when a profile exists.
  Future<Map<String, dynamic>?> login({
    required String identifier,
    required String credential,
    required String loginType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {
        'identifier': identifier,
        'credential': credential,
        'login_type': loginType,
      },
    );
    await _saveTokensFromResponse(response);
    await switchToPatientProfileContext();
    final data = response.data;
    final user = data?['user'];
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }
    return null;
  }

  Future<void> generateOtp({required String identifier}) async {
    final channel = identifier.contains('@') ? 'Email' : 'Sms';
    await _dio.post('/api/auth/otp/generate', data: {
      'identifier': identifier,
      'channel': channel,
    });
  }

  Future<void> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await _dio.post('/api/auth/register', data: {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'first_name': ?firstName,
      'last_name': ?lastName,
    });
  }

  /// Register then login (same as patient-web-app register action).
  Future<Map<String, dynamic>?> registerAndLogin({
    required String username,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await register(
      username: username,
      email: email,
      phone: phone,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    return login(
      identifier: username,
      credential: password,
      loginType: 'Password',
    );
  }

  Future<void> requestPasswordResetOtp(String identifier) async {
    final channel = identifier.contains('@') ? 'Email' : 'Sms';
    await _dio.post('/api/auth/otp/generate', data: {
      'identifier': identifier,
      'channel': channel,
    });
  }

  Future<void> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    await _dio.post('/api/auth/verify-otp', data: {
      'identifier': identifier,
      'otp': otp,
    });
  }

  Future<void> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post('/api/auth/reset-password', data: {
      'identifier': identifier,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {
      // ignore
    } finally {
      await _storage.clearTokens();
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
