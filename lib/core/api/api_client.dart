import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  // Base URL for public storage files — single source of truth: AppConfig.
  final String storageBaseUrl;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Accept': 'application/json',
            },
          ),
        ),
        storageBaseUrl = AppConfig.storageBaseUrl
  {
    dio.interceptors.add(AuthInterceptor());
  }
}