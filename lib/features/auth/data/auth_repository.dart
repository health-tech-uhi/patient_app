import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// `POST /api/auth/switch-context` returns a new access `token` but usually **no**
  /// `refresh_token` — keep the refresh token from the login response.
  Future<void> _saveTokensAfterContextSwitch(Response response) async {
    final data = response.data;
    if (data is! Map) {
      throw Exception('Invalid auth response');
    }
    final access = data['token'];
    if (access is! String) {
      throw Exception('Invalid access token received from server');
    }
    final refresh = data['refresh_token'] ?? data['refreshToken'];
    final String refreshToken;
    if (refresh is String) {
      refreshToken = refresh;
    } else {
      final existing = await _storage.getRefreshToken();
      if (existing == null) {
        throw Exception('No refresh token to pair with profile context');
      }
      refreshToken = existing;
    }
    await _storage.saveTokens(accessToken: access, refreshToken: refreshToken);
  }

  /// Binds the session to the **patient** access-control profile so the JWT includes
  /// `profile_id`. Required for clinical routes (`/api/records/...`); otherwise the API
  /// returns 401 *Missing profile context in token*. Not “multi-app switching” — this
  /// app only ever uses the patient profile when one exists.
  Future<void> switchToPatientProfileContext() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/api/patients/profile');
      final data = r.data;
      if (data == null) return;
      final id = data['profile_id'] ?? data['id'];
      if (id == null) return;
      final switchRes = await _dio.post<Map<String, dynamic>>(
        '/api/auth/switch-context',
        data: {'profile_id': id},
      );
      await _saveTokensAfterContextSwitch(switchRes);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return;
      rethrow;
    }
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
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
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
