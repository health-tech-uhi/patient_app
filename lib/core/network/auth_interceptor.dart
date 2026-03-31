import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._secureStorage,
    this._refreshDio,
    this._mainDio, {
    this.onUnauthorized,
  });

  final SecureStorage _secureStorage;
  final Dio _refreshDio;
  final Dio _mainDio;
  final void Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.uri.path;
    if (path.endsWith('/api/auth/refresh')) {
      await _handleLogout();
      return handler.next(err);
    }

    if (err.requestOptions.extra['_auth_retry'] == true) {
      await _handleLogout();
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken != null) {
        try {
          final response = await _refreshDio.post(
            '/api/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data as Map<String, dynamic>;
            final newAccessToken = data['token'] ?? data['accessToken'];
            final newRefreshToken =
                data['refresh_token'] ?? data['refreshToken'];

            if (newAccessToken != null && newRefreshToken != null) {
              await _secureStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              final retryOptions = err.requestOptions.copyWith(
                extra: {
                  ...err.requestOptions.extra,
                  '_auth_retry': true,
                },
              );
              retryOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';

              final retryResponse = await _mainDio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          await _handleLogout();
        }
      } else {
        await _handleLogout();
      }
    }

    handler.next(err);
  }

  Future<void> _handleLogout() async {
    await _secureStorage.clearTokens();
    onUnauthorized?.call();
  }
}
