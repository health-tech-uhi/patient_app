import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session_bridge.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

final baseUrlProvider = Provider<String>((ref) {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) return envUrl;
  return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3111';
});

/// Provides [Dio] with auth + refresh. Session expiry is handled via [AuthSessionBridge].
final dioClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      secureStorage,
      refreshDio,
      dio,
      onUnauthorized: () => AuthSessionBridge.onSessionExpired?.call(),
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ),
  );

  return dio;
});
